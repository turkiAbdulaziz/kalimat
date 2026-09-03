/// M7b: the win-wave choreography — stagger, haptic, timing — and the
/// loss-path answer tiles. Typing is driven through the notifier so board
/// letters never make keyboard taps ambiguous.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/app.dart';
import 'package:kalimat/core/strings.dart';
import 'package:kalimat/game/data/dictionary.dart';
import 'package:kalimat/game/data/local_store.dart';
import 'package:kalimat/game/engine/models.dart';
import 'package:kalimat/game/engine/puzzle_calendar.dart';
import 'package:kalimat/game/state/game_controller.dart';
import 'package:kalimat/game/state/haptics.dart';
import 'package:kalimat/game/state/settings_controller.dart';
import 'package:kalimat/game/widgets/answer_tiles.dart';
import 'package:kalimat/game/widgets/tile.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

late GuessDictionary _dictionary;

class RecordingHaptics implements HapticsService {
  int taps = 0;
  int successes = 0;
  int errors = 0;

  @override
  void tap() => taps++;

  @override
  void success() => successes++;

  @override
  void error() => errors++;
}

Future<(Widget, RecordingHaptics)> _app(
  WidgetTester tester, {
  required bool motion,
}) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData({
        'help_seen': true,
        'settings': '{"dark":false,"hints":true,"motion":$motion}',
      });
  final store = (await tester.runAsync(LocalStore.create))!;
  final haptics = RecordingHaptics();
  final app = ProviderScope(
    overrides: [
      localStoreProvider.overrideWithValue(store),
      dictionaryProvider.overrideWithValue(_dictionary),
      hapticsProvider.overrideWithValue(haptics),
      initialWordProvider.overrideWithValue(
        DailyWord(
          date: dateOnly(DateTime.now()),
          puzzleNo: puzzleNumberFor(DateTime.now()),
          word: 'مدرسة',
          fromServer: false,
        ),
      ),
    ],
    child: const KalimatApp(),
  );
  return (app, haptics);
}

GameController _notifier(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(KalimatApp)),
).read(gameProvider.notifier);

GameState _game(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(KalimatApp)),
).read(gameProvider);

double _tileScale(WidgetTester tester, int index) {
  final tile = find.byType(Tile).at(index);
  final transform = tester.widget<Transform>(
    find.descendant(of: tile, matching: find.byType(Transform)).first,
  );
  return transform.transform.storage[0]; // x-scale entry
}

void _type(WidgetTester tester, String word) {
  final n = _notifier(tester);
  for (final letter in word.split('')) {
    n.onKey(letter);
  }
  n.onEnter();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    _dictionary = GuessDictionary();
    await _dictionary.ensureLoaded();
  });

  testWidgets('win wave: staggered pop after the reveal, one haptic', (
    tester,
  ) async {
    final (app, haptics) = await _app(tester, motion: true);
    await tester.pumpWidget(app);
    await tester.pump();

    _type(tester, 'مدرسة');
    await tester.pump();

    // Reveal runs 900ms; the wave holds 250ms more.
    await tester.pump(const Duration(milliseconds: 900));
    expect(_game(tester).waveRow, -1);
    expect(haptics.successes, 0);
    await tester.pump(const Duration(milliseconds: 250));
    expect(_game(tester).waveRow, 0);
    expect(haptics.successes, 1);

    // Near the first pop's peak (~60ms in): the rightmost tile (index 0)
    // is scaling, the leftmost (index 4, wave delay 280ms) has not started.
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump(const Duration(milliseconds: 30));
    expect(_tileScale(tester, 0), greaterThan(1.01));
    expect(_tileScale(tester, 4), 1.0);

    // Wave clears, stats dialog rises at 1600ms after the toast.
    await tester.pump(const Duration(milliseconds: 1300));
    expect(_game(tester).waveRow, -1);
    await tester.pumpAndSettle();
    expect(find.text(S.statPlayed), findsOneWidget);
  });

  testWidgets('motion off: no wave, haptic still fires, old 1400ms delay', (
    tester,
  ) async {
    final (app, haptics) = await _app(tester, motion: false);
    await tester.pumpWidget(app);
    await tester.pump();

    _type(tester, 'مدرسة');
    await tester.pump();

    // Reveal is synchronous with motion off; the finish already ran.
    expect(_game(tester).status, GameStatus.won);
    expect(_game(tester).waveRow, -1);
    expect(haptics.successes, 1);

    await tester.pump(const Duration(milliseconds: 1400));
    expect(_game(tester).waveRow, -1);
    await tester.pumpAndSettle();
    expect(find.text(S.statPlayed), findsOneWidget);
  });

  testWidgets('loss: stats dialog shows the answer as filled tiles', (
    tester,
  ) async {
    final (app, haptics) = await _app(tester, motion: false);
    await tester.pumpWidget(app);
    await tester.pump();

    for (var i = 0; i < 6; i++) {
      _type(tester, 'عندما');
      await tester.pump();
    }
    expect(_game(tester).status, GameStatus.lost);
    expect(haptics.successes, 0); // no celebration on loss

    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    expect(find.byType(AnswerTiles), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AnswerTiles), matching: find.byType(Tile)),
      findsNWidgets(5),
    );
    // Typing haptics fired throughout play.
    expect(haptics.taps, 30);
  });
}
