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
import 'package:kalimat/game/state/settings_controller.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

// The dictionary asset is real file I/O — it must load OUTSIDE testWidgets'
// fake-async zone (in setUpAll) or the test deadlocks.
late GuessDictionary _dictionary;

Future<Widget> _app(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData(prefs);
  final store = (await tester.runAsync(LocalStore.create))!;
  return ProviderScope(
    overrides: [
      localStoreProvider.overrideWithValue(store),
      dictionaryProvider.overrideWithValue(_dictionary),
      // Dated *today* so SyncService's offline day-rollover check
      // (sync_service.dart) never swaps the word mid-test — a fixed date
      // broke here the day the calendar epoch passed.
      initialWordProvider.overrideWithValue(
        DailyWord(
          date: dateOnly(DateTime.now()),
          puzzleNo: puzzleNumberFor(DateTime.now()),
          word: 'وردة',
          fromServer: false,
        ),
      ),
    ],
    child: const KalimatApp(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    _dictionary = GuessDictionary();
    await _dictionary.ensureLoaded();
  });

  testWidgets('app boots RTL with header, badge, board, keyboard', (
    tester,
  ) async {
    await tester.pumpWidget(await _app(tester, prefs: {'help_seen': true}));
    await tester.pump();

    // RTL comes from the ar locale.
    final context = tester.element(find.text(S.appTitle));
    expect(Directionality.of(context), TextDirection.rtl);

    expect(find.text(S.appTitle), findsOneWidget);
    expect(find.textContaining(S.dayBadgePrefix), findsOneWidget);
    expect(find.text(S.enterKey), findsOneWidget);
  });

  testWidgets('help dialog shows on first launch only', (tester) async {
    await tester.pumpWidget(await _app(tester));
    await tester.pumpAndSettle();
    expect(find.text(S.helpBody), findsOneWidget);
    await tester.tap(find.text(S.helpStart));
    await tester.pumpAndSettle();
    expect(find.text(S.helpBody), findsNothing);
  });

  testWidgets('typing fills tiles; too-short enter shakes with toast', (
    tester,
  ) async {
    await tester.pumpWidget(await _app(tester, prefs: {'help_seen': true}));
    await tester.pump();

    await tester.tap(
      find.descendant(of: find.byType(Scaffold), matching: find.text('م')),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(S.enterKey));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(S.tooShort), findsOneWidget);
    // Toast auto-dismisses.
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(S.tooShort), findsNothing);
  });

  testWidgets('full winning game: reveal, toast, stats dialog', (tester) async {
    await tester.pumpWidget(
      await _app(
        tester,
        prefs: {
          'help_seen': true,
          'settings': '{"dark":false,"hints":true,"motion":false}',
        },
      ),
    );
    await tester.pump();

    for (final letter in ['و', 'ر', 'د', 'ة']) {
      await tester.tap(
        find.descendant(of: find.byType(Scaffold), matching: find.text(letter)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.text(S.enterKey));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(S.win), findsOneWidget); // toast

    // Stats dialog opens after the win delay.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text(S.statPlayed), findsOneWidget);
    expect(find.text(S.shareResult), findsOneWidget);
  });
}
