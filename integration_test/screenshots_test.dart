/// App Store screenshots, one test per frame. Not part of `flutter test`
/// (integration tests need a device); run on the 6.9" simulator via the
/// driver in `test_driver/integration_test.dart`, which writes each frame to
/// `store/screenshots/<name>.png`.
///
/// Each test seeds an in-memory LocalStore (the same trick the widget suite
/// uses) so the frames show a lived-in game — player ليلى, answer وردة, the
/// canvas's sample stats — with the app otherwise unconfigured (no Supabase
/// defines), exactly like a fresh offline install.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kalimat/app.dart';
import 'package:kalimat/backend/backend_providers.dart';
import 'package:kalimat/backend/challenge_repository.dart';
import 'package:kalimat/challenge/challenge_screen.dart';
import 'package:kalimat/challenge/models.dart';
import 'package:kalimat/core/theme/kalimat_theme.dart';
import 'package:kalimat/game/data/dictionary.dart';
import 'package:kalimat/game/data/local_store.dart';
import 'package:kalimat/game/engine/models.dart';
import 'package:kalimat/game/engine/puzzle_calendar.dart';
import 'package:kalimat/game/state/game_controller.dart';
import 'package:kalimat/game/state/settings_controller.dart';
import 'package:kalimat/game/widgets/kalimat_avatar.dart';
import 'package:kalimat/game/widgets/kalimat_button.dart';
import 'package:kalimat/onboarding/sign_in_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _answer = 'وردة';
// Absent-only → mixed → nearly there: the board reads as a story.
const _midPlay = ['جميل', 'بحار', 'ورقة'];
const _won = ['بحار', 'ورقة', 'وردة'];
// ٤٥ played · ٨٩٪ · streak ٧ · best ١٢ — the canvas's sample player.
const _stats = GameStats(
  played: 45,
  wins: 40,
  streak: 7,
  best: 12,
  dist: [2, 6, 12, 11, 6, 3],
);

late GuessDictionary _dictionary;

Future<LocalStore> _store({
  required bool helpSeen,
  bool dark = false,
  List<String>? board,
}) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final store = await LocalStore.create();
  await store.setSettings(GameSettings(dark: dark));
  await store.setDisplayName('ليلى');
  await store.setOnboarded();
  if (helpSeen) await store.setHelpSeen();
  await store.setStats(_stats);
  if (board != null) {
    await store.setBoard(
      BoardSave(date: dateOnly(DateTime.now()), guesses: board),
    );
  }
  return store;
}

Widget _app(LocalStore store) => ProviderScope(
  overrides: [
    localStoreProvider.overrideWithValue(store),
    dictionaryProvider.overrideWithValue(_dictionary),
    initialWordProvider.overrideWithValue(
      DailyWord(
        date: dateOnly(DateTime.now()),
        puzzleNo: puzzleNumberFor(DateTime.now()),
        word: _answer,
        fromServer: false,
      ),
    ),
  ],
  child: const KalimatApp(),
);

/// pumpAndSettle can't see the tiles' Future.delayed reveal timers, so give
/// the choreography real time to finish before shooting.
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 2500));
  await tester.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    _dictionary = GuessDictionary();
    await _dictionary.ensureLoaded();
  });

  testWidgets('01-board — mid-game with hints', (tester) async {
    await tester.pumpWidget(
      _app(await _store(helpSeen: true, board: _midPlay)),
    );
    await _settle(tester);
    await binding.takeScreenshot('01-board');
  });

  testWidgets('02-won — solved board with the stats card', (tester) async {
    await tester.pumpWidget(_app(await _store(helpSeen: true, board: _won)));
    await _settle(tester);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is KalimatIconButton && w.icon == LucideIcons.chartColumn,
      ),
    );
    await _settle(tester);
    await binding.takeScreenshot('02-won');
  });

  testWidgets('03-help — first-run how-to-play', (tester) async {
    await tester.pumpWidget(_app(await _store(helpSeen: false)));
    await _settle(tester);
    await binding.takeScreenshot('03-help');
  });

  testWidgets('04-profile — «حسابي» with stats and streak', (tester) async {
    await tester.pumpWidget(_app(await _store(helpSeen: true, board: _won)));
    await _settle(tester);
    await tester.tap(find.byType(KalimatAvatar).first);
    await _settle(tester);
    await binding.takeScreenshot('04-profile');
  });

  testWidgets('05-signin — first screen', (tester) async {
    final store = await _store(helpSeen: false);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStoreProvider.overrideWithValue(store)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: kalimatTheme(Brightness.light),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: SignInScreen(),
          ),
        ),
      ),
    );
    await _settle(tester);
    await binding.takeScreenshot('05-signin');
  });

  testWidgets('06-dark — the board in «الوضع الليلي»', (tester) async {
    await tester.pumpWidget(
      _app(await _store(helpSeen: true, dark: true, board: _midPlay)),
    );
    await _settle(tester);
    await binding.takeScreenshot('06-dark');
  });
  for (final dark in [false, true]) {
    testWidgets('duel board dark=$dark, motion disabled', (tester) async {
      final store = await _store(helpSeen: true, dark: dark);
      await store.setSettings(GameSettings(dark: dark, motion: false));
      await store.setChallengeBoard(
        'screenshot',
        const ChallengeBoardSave(guesses: ['جميل', 'صباح', 'ساعة']),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStoreProvider.overrideWithValue(store),
            dictionaryProvider.overrideWithValue(_dictionary),
            challengeRepositoryProvider.overrideWithValue(_ScreenshotDuels()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: kalimatTheme(dark ? Brightness.dark : Brightness.light),
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: ChallengeScreen(challengeId: 'screenshot'),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot(dark ? '08-duel-dark' : '07-duel');
    });
  }
}

class _ScreenshotDuels extends ChallengeRepository {
  @override
  Future<ChallengeDetail?> open(String id) async => ChallengeDetail(
    id: id,
    word: 'ساحة',
    opponentId: 'opponent',
    opponentName: 'تركي',
    status: ChallengeStatus.active,
    mine: const ChallengeSide(),
    theirs: const ChallengeSide(guesses: 4),
  );
  @override
  Stream<ChallengeSide> watchOpponent(String challengeId, String opponentId) =>
      const Stream.empty();
}
