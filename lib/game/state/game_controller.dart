/// The game loop: typing, validation, reveal/toast/dialog sequencing,
/// persistence, and stats recording.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../data/dictionary.dart';
import '../data/local_store.dart';
import '../engine/evaluate.dart';
import '../engine/keyboard_state.dart';
import '../engine/letters.dart';
import '../engine/models.dart';
import 'settings_controller.dart';
import 'stats_controller.dart';

const int kWordLength = 5;
const int kMaxGuesses = 6;

/// Reveal choreography (must match the tile flip animation timings).
const Duration kRevealTotal = Duration(milliseconds: 900); // 420 + 4*120
const Duration kWinToastToStats = Duration(milliseconds: 1400);
const Duration kLossToStats = Duration(milliseconds: 1000);

/// Overridden in main() with the word resolved at startup.
final initialWordProvider = Provider<DailyWord>(
  (ref) => throw UnimplementedError('initialWordProvider must be overridden'),
);

/// Overridden in main() with the loaded dictionary.
final dictionaryProvider = Provider<GuessDictionary>(
  (ref) => throw UnimplementedError('dictionaryProvider must be overridden'),
);

final gameProvider =
    NotifierProvider<GameController, GameState>(GameController.new);

class GameState {
  const GameState({
    required this.word,
    this.guesses = const [],
    this.rowStates = const [],
    this.current = const [],
    this.keyStates = const {},
    this.status = GameStatus.playing,
    this.toast,
    this.toastIsWin = false,
    this.shakeRow = -1,
    this.revealRow = -1,
    this.revealAnswer = false,
    this.statsDialogTick = 0,
  });

  final DailyWord word;

  /// Submitted guesses as typed spellings.
  final List<String> guesses;

  /// Evaluated states per submitted row.
  final List<List<TileState>> rowStates;

  /// Letters of the in-progress row.
  final List<String> current;

  /// Best-known state per canonical letter class (keyboard hints).
  final Map<String, TileState> keyStates;

  final GameStatus status;

  /// Non-null while a toast is showing (replaces the day badge).
  final String? toast;
  final bool toastIsWin;

  /// Row index currently shaking / flip-revealing, -1 when none.
  final int shakeRow;
  final int revealRow;

  /// Loss: the badge slot shows «الكلمة: …».
  final bool revealAnswer;

  /// Increments when the controller asks the UI to open the stats dialog.
  final int statsDialogTick;

  bool get finished => status != GameStatus.playing;

  GameState copyWith({
    List<String>? guesses,
    List<List<TileState>>? rowStates,
    List<String>? current,
    Map<String, TileState>? keyStates,
    GameStatus? status,
    String? toast,
    bool clearToast = false,
    bool? toastIsWin,
    int? shakeRow,
    int? revealRow,
    bool? revealAnswer,
    int? statsDialogTick,
  }) =>
      GameState(
        word: word,
        guesses: guesses ?? this.guesses,
        rowStates: rowStates ?? this.rowStates,
        current: current ?? this.current,
        keyStates: keyStates ?? this.keyStates,
        status: status ?? this.status,
        toast: clearToast ? null : (toast ?? this.toast),
        toastIsWin: toastIsWin ?? this.toastIsWin,
        shakeRow: shakeRow ?? this.shakeRow,
        revealRow: revealRow ?? this.revealRow,
        revealAnswer: revealAnswer ?? this.revealAnswer,
        statsDialogTick: statsDialogTick ?? this.statsDialogTick,
      );

  /// Server-side grid encoding: 0=absent, 1=present, 2=correct, rows
  /// separated by '|'.
  String get gridString => rowStates
      .map((row) => row
          .map((s) => switch (s) {
                TileState.correct => '2',
                TileState.present => '1',
                _ => '0',
              })
          .join())
      .join('|');
}

class GameController extends Notifier<GameState> {
  final List<Timer> _timers = [];

  @override
  GameState build() {
    ref.onDispose(_cancelTimers);
    final word = ref.read(initialWordProvider);
    final store = ref.read(localStoreProvider);

    var s = GameState(word: word);

    // Restore today's board (typed spellings; states recomputed).
    final saved = store.board;
    if (saved != null && _sameDate(saved.date, word.date)) {
      final target = stripMarks(word.word).split('');
      for (final guess in saved.guesses.take(kMaxGuesses)) {
        final letters = guess.split('');
        if (letters.length != kWordLength) continue;
        final states = evaluateGuess(letters, target);
        s = s.copyWith(
          guesses: [...s.guesses, guess],
          rowStates: [...s.rowStates, states],
          keyStates: updateKeyStates(s.keyStates, letters, states),
        );
      }
      if (s.rowStates.any((r) => r.every((t) => t == TileState.correct))) {
        s = s.copyWith(status: GameStatus.won);
      } else if (s.guesses.length >= kMaxGuesses) {
        s = s.copyWith(status: GameStatus.lost, revealAnswer: true);
      }
    }
    return s;
  }

  static bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _motion => ref.read(settingsProvider).motion;

  void onKey(String letter) {
    if (state.finished || state.current.length >= kWordLength) return;
    state = state.copyWith(current: [...state.current, letter]);
  }

  void onDelete() {
    if (state.finished || state.current.isEmpty) return;
    state = state.copyWith(
      current: state.current.sublist(0, state.current.length - 1),
    );
  }

  void onEnter() {
    if (state.finished || state.revealRow != -1) return;

    if (state.current.length < kWordLength) {
      _rejectRow(S.tooShort);
      return;
    }
    final typed = state.current.join();
    final dict = ref.read(dictionaryProvider);
    if (!dict.contains(typed, answer: state.word.word)) {
      _rejectRow(S.notInDictionary);
      return;
    }

    final letters = state.current;
    final target = stripMarks(state.word.word).split('');
    final states = evaluateGuess(letters, target);
    final rowIndex = state.guesses.length;
    final solved = states.every((t) => t == TileState.correct);
    final isLastRow = rowIndex + 1 >= kMaxGuesses;

    state = state.copyWith(
      guesses: [...state.guesses, typed],
      rowStates: [...state.rowStates, states],
      keyStates: updateKeyStates(state.keyStates, letters, states),
      current: const [],
      revealRow: _motion ? rowIndex : -1,
    );

    final store = ref.read(localStoreProvider);
    store.setBoard(BoardSave(date: state.word.date, guesses: state.guesses));

    _after(_motion ? kRevealTotal : Duration.zero, () {
      state = state.copyWith(revealRow: -1);
      if (solved) {
        _finish(won: true);
      } else if (isLastRow) {
        _finish(won: false);
      }
    });
  }

  void _rejectRow(String message) {
    final row = state.guesses.length;
    state = state.copyWith(shakeRow: _motion ? row : -1);
    _flash(message);
    if (_motion) {
      _after(const Duration(milliseconds: 450), () {
        state = state.copyWith(shakeRow: -1);
      });
    }
  }

  void _finish({required bool won}) {
    final guesses = state.guesses.length;
    state = state.copyWith(
      status: won ? GameStatus.won : GameStatus.lost,
      revealAnswer: !won,
    );
    if (won) _flash(S.win, isWin: true);

    ref.read(statsProvider.notifier).recordGame(won: won, guesses: guesses);
    _enqueueResult(won: won, guesses: guesses);

    _after(won ? kWinToastToStats : kLossToStats, () {
      state = state.copyWith(statsDialogTick: state.statsDialogTick + 1);
    });
  }

  void _enqueueResult({required bool won, required int guesses}) {
    final store = ref.read(localStoreProvider);
    final queue = [
      ...store.pendingResults,
      PendingResult(
        date: state.word.date,
        won: won,
        guesses: won ? guesses : null,
        grid: state.gridString,
      ),
    ];
    store.setPendingResults(queue);
    // M3: results_repository flushes this queue to Supabase.
  }

  void _flash(String message, {bool isWin = false}) {
    state = state.copyWith(toast: message, toastIsWin: isWin);
    _after(const Duration(milliseconds: 1300), () {
      state = state.copyWith(clearToast: true);
    });
  }

  void _after(Duration d, void Function() fn) {
    if (d == Duration.zero) {
      fn();
      return;
    }
    _timers.add(Timer(d, fn));
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }
}
