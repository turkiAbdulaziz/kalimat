/// The shared word-game loop: typing, validation, reveal choreography,
/// win/loss sequencing, and the solve clock.
///
/// Two sessions extend it — the daily puzzle ([GameController]) and a friend
/// duel (`ChallengeGameController`). Everything session-specific (which word,
/// where the board is persisted, what happens when the game ends) is a hook,
/// so the loop itself exists exactly once.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../core/theme/motion.dart';
import '../data/dictionary.dart';
import '../engine/evaluate.dart';
import '../engine/keyboard_state.dart';
import '../engine/letters.dart';
import '../engine/models.dart';
import 'settings_controller.dart';

const int kWordLength = 5;
const int kMaxGuesses = 6;

/// Reveal choreography (must match the tile flip animation timings).
const Duration kRevealTotal = Duration(milliseconds: 900); // 420 + 4*120
const Duration kWinToastToStats = Duration(milliseconds: 1400);
const Duration kLossToStats = Duration(milliseconds: 1000);

/// Overridden in main() with the loaded dictionary.
final dictionaryProvider = Provider<GuessDictionary>(
  (ref) => throw UnimplementedError('dictionaryProvider must be overridden'),
);

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

  /// Increments when the controller asks the UI to open the end-of-game
  /// dialog (stats for the daily puzzle, the result card for a duel).
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
  }) => GameState(
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
      .map(
        (row) => row
            .map(
              (s) => switch (s) {
                TileState.correct => '2',
                TileState.present => '1',
                _ => '0',
              },
            )
            .join(),
      )
      .join('|');
}

abstract class WordGameNotifier extends Notifier<GameState> {
  final List<Timer> _timers = [];

  /// Epoch ms of the first letter typed in this game — the solve clock.
  /// Restored with the board so a kill/relaunch doesn't reset it.
  int? _startedAtMs;

  int? get startedAtMs => _startedAtMs;

  // ---- session hooks -------------------------------------------------

  /// The word this session is playing.
  DailyWord get sessionWord;

  /// Typed spellings restored from storage (empty = fresh board).
  List<String> get restoredGuesses => const [];

  /// Epoch ms the restored board's clock started at, null when unknown.
  int? get restoredStartedAtMs => null;

  /// Persist after every submitted guess and when the clock starts.
  void persistBoard(List<String> guesses, int? startedAtMs);

  /// A valid guess was accepted; [guessCount] guesses have now been made.
  /// Fires before the reveal animation, so a duel opponent sees progress live.
  void onGuessSubmitted(int guessCount) {}

  /// The game ended (after the reveal). [durationMs] is null when the clock
  /// is unknown — an old board save with no recorded start.
  void onFinished({
    required bool won,
    required int guesses,
    required int? durationMs,
  });

  // ---- loop ----------------------------------------------------------

  @override
  GameState build() {
    ref.onDispose(cancelTimers);
    _startedAtMs = restoredStartedAtMs;
    return restoreBoard(GameState(word: sessionWord), restoredGuesses);
  }

  /// Replays [guesses] onto [initial], recomputing row/key states and the
  /// finished status. Row states are never stored — only typed spellings.
  static GameState restoreBoard(GameState initial, List<String> guesses) {
    var s = initial;
    final target = stripMarks(s.word.word).split('');
    for (final guess in guesses.take(kMaxGuesses)) {
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
      return s.copyWith(status: GameStatus.won);
    }
    if (s.guesses.length >= kMaxGuesses) {
      return s.copyWith(status: GameStatus.lost, revealAnswer: true);
    }
    return s;
  }

  bool get motion => ref.read(settingsProvider).motion;

  void onKey(String letter) {
    if (state.finished || state.current.length >= kWordLength) return;
    _startClock();
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
      revealRow: motion ? rowIndex : -1,
    );

    persistBoard(state.guesses, _startedAtMs);
    onGuessSubmitted(state.guesses.length);

    after(motion ? kRevealTotal : Duration.zero, () {
      state = state.copyWith(revealRow: -1);
      if (solved) {
        _finish(won: true);
      } else if (isLastRow) {
        _finish(won: false);
      }
    });
  }

  /// The clock starts on the first letter of the game, not when the screen
  /// opens — reading the board costs no time. It is only written to storage
  /// with the first submitted guess: nothing is persisted while a row is
  /// still being typed (or rejected).
  void _startClock() {
    if (_startedAtMs != null || state.guesses.isNotEmpty) return;
    _startedAtMs = DateTime.now().millisecondsSinceEpoch;
  }

  int? _elapsedMs() {
    final start = _startedAtMs;
    if (start == null) return null;
    final ms = DateTime.now().millisecondsSinceEpoch - start;
    return ms < 0 ? null : ms;
  }

  void _rejectRow(String message) {
    final row = state.guesses.length;
    state = state.copyWith(shakeRow: motion ? row : -1);
    flash(message);
    if (motion) {
      after(const Duration(milliseconds: 450), () {
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
    if (won) flash(S.win, isWin: true);

    onFinished(won: won, guesses: guesses, durationMs: _elapsedMs());

    after(won ? kWinToastToStats : kLossToStats, () {
      state = state.copyWith(statsDialogTick: state.statsDialogTick + 1);
    });
  }

  void flash(String message, {bool isWin = false}) {
    state = state.copyWith(toast: message, toastIsWin: isWin);
    after(Motion.toastVisible, () {
      state = state.copyWith(clearToast: true);
    });
  }

  void after(Duration d, void Function() fn) {
    if (d == Duration.zero) {
      fn();
      return;
    }
    _timers.add(Timer(d, fn));
  }

  void cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  /// Restarts the loop on a brand-new word (day rollover / rematch).
  void resetTo(DailyWord word) {
    cancelTimers();
    _startedAtMs = null;
    state = GameState(word: word);
  }
}
