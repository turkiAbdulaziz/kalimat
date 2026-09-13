import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/backend/backend_providers.dart';
import 'package:kalimat/backend/challenge_repository.dart';
import 'package:kalimat/challenge/challenge_controller.dart';
import 'package:kalimat/challenge/challenge_screen.dart';
import 'package:kalimat/challenge/models.dart';
import 'package:kalimat/core/strings.dart';
import 'package:kalimat/core/theme/kalimat_theme.dart';
import 'package:kalimat/core/theme/metrics.dart';
import 'package:kalimat/game/data/dictionary.dart';
import 'package:kalimat/game/data/local_store.dart';
import 'package:kalimat/game/engine/models.dart';
import 'package:kalimat/game/state/game_controller.dart';
import 'package:kalimat/game/state/settings_controller.dart';
import 'package:kalimat/game/widgets/game_surface.dart';
import 'package:kalimat/game/widgets/guess_grid.dart';
import 'package:kalimat/game/widgets/key_cap.dart';
import 'package:kalimat/game/widgets/tile.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakeDuels extends ChallengeRepository {
  String word = 'وردة';
  String? grid;
  @override
  Future<ChallengeDetail?> open(String id) async => ChallengeDetail(
    id: id,
    word: word,
    opponentId: 'them',
    opponentName: 'ليلى',
    status: ChallengeStatus.active,
    mine: const ChallengeSide(),
    theirs: ChallengeSide(grid: grid),
  );
  @override
  Stream<ChallengeSide> watchOpponent(String challengeId, String opponentId) =>
      const Stream.empty();
}

late GuessDictionary dictionary;

Future<Widget> app(
  WidgetTester tester, {
  required bool duel,
  required bool dark,
  required bool motion,
  required FakeDuels repo,
}) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final store = (await tester.runAsync(LocalStore.create))!;
  await store.setSettings(GameSettings(dark: dark, motion: motion));
  final game = GameState(
    word: DailyWord(
      date: DateTime(2026, 9, 1),
      puzzleNo: 1,
      word: 'وردة',
      fromServer: false,
    ),
  );
  return ProviderScope(
    overrides: [
      localStoreProvider.overrideWithValue(store),
      dictionaryProvider.overrideWithValue(dictionary),
      challengeRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      theme: kalimatTheme(dark ? Brightness.dark : Brightness.light),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: duel
            ? const ChallengeScreen(challengeId: 'duel')
            : Scaffold(
                body: SafeArea(
                  child: GameSurface(
                    game: game,
                    motion: motion,
                    hints: true,
                    onKey: (_) {},
                    onEnter: () {},
                    onDelete: () {},
                  ),
                ),
              ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    dictionary = GuessDictionary();
    await dictionary.ensureLoaded();
  });
  for (final duel in [false, true]) {
    for (final dark in [false, true]) {
      for (final motion in [false, true]) {
        for (final size in [const Size(320, 568), const Size(430, 932)]) {
          testWidgets(
            '${duel ? 'duel' : 'daily'} dark=$dark motion=$motion $size',
            (tester) async {
              tester.view.physicalSize = size;
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              await tester.pumpWidget(
                await app(
                  tester,
                  duel: duel,
                  dark: dark,
                  motion: motion,
                  repo: FakeDuels(),
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(find.byType(Tile), findsNWidgets(24));
              expect(find.byType(KeyCap), findsNWidgets(35));
              final tiles = tester.widgetList<Tile>(find.byType(Tile)).toList();
              expect(tiles.first.size, lessThanOrEqualTo(Metrics.tileSize));
              if (size.height > 900) expect(tiles.first.size, Metrics.tileSize);
              final right = tester.getRect(find.byType(Tile).at(0));
              final left = tester.getRect(find.byType(Tile).at(3));
              expect(right.left, greaterThan(left.left));
              expect(
                (right.right + left.left) / 2,
                closeTo(size.width / 2, .01),
              );
              expect(
                tester.getRect(find.byType(GuessGrid)).bottom,
                lessThan(tester.getRect(find.byType(KeyCap).first).top),
              );
            },
          );
        }
      }
    }
  }
  testWidgets(
    'stale duel never builds an engine; retry opens an updated duel',
    (tester) async {
      final repo = FakeDuels()..word = 'مدرسة';
      await tester.pumpWidget(
        await app(tester, duel: true, dark: false, motion: false, repo: repo),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(S.openChallengeFailed), findsOneWidget);
      expect(find.byType(GuessGrid), findsNothing);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ChallengeScreen)),
      );
      expect(container.read(activeChallengeProvider), isNull);
      repo.word = 'وردة';
      await tester.tap(find.text(S.retry));
      await tester.pumpAndSettle();
      expect(find.byType(Tile), findsNWidgets(24));
      expect(container.read(challengeGameProvider).word.word, 'وردة');
    },
  );
  testWidgets('incompatible remote result grid shows recoverable error', (
    tester,
  ) async {
    final repo = FakeDuels()..grid = '22222';
    await tester.pumpWidget(
      await app(tester, duel: true, dark: true, motion: false, repo: repo),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(S.retry), findsOneWidget);
    expect(find.byType(GuessGrid), findsNothing);
  });
}
