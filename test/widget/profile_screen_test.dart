import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/core/strings.dart';
import 'package:kalimat/core/theme/kalimat_theme.dart';
import 'package:kalimat/game/data/local_store.dart';
import 'package:kalimat/game/engine/models.dart';
import 'package:kalimat/game/state/game_controller.dart';
import 'package:kalimat/game/state/settings_controller.dart';
import 'package:kalimat/game/widgets/distribution_bar.dart';
import 'package:kalimat/game/widgets/kalimat_switch.dart';
import 'package:kalimat/profile/profile_screen.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Future<Widget> _screen(WidgetTester tester) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final store = (await tester.runAsync(LocalStore.create))!;
  return ProviderScope(
    overrides: [
      localStoreProvider.overrideWithValue(store),
      initialWordProvider.overrideWithValue(
        DailyWord(
          date: DateTime(2026, 9, 1),
          puzzleNo: 1,
          word: 'مدرسة',
          fromServer: false,
        ),
      ),
    ],
    child: MaterialApp(
      theme: kalimatTheme(Brightness.light),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: ProfileScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('renders identity, stats, distribution, and preferences', (
    tester,
  ) async {
    await tester.pumpWidget(await _screen(tester));
    await tester.pump();

    expect(find.text(S.profileTitle), findsOneWidget);
    // Guest identity: default name, no email, no sign-out.
    expect(find.text(S.guestName), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
    expect(find.text(S.signOut), findsNothing);
    expect(find.text(S.deleteAccount), findsNothing);

    for (final label in [
      S.statPlayed,
      S.statWinRate,
      S.statStreak,
      S.statBest,
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byType(DistributionBar), findsNWidgets(6));
    for (final label in [S.settingDark, S.settingHints, S.settingMotion]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text(S.shareLastResult), findsOneWidget);
    expect(find.textContaining(S.versionPrefix), findsOneWidget);
    expect(find.text(S.backToGame), findsOneWidget);
  });

  testWidgets('dark switch writes through to the settings controller', (
    tester,
  ) async {
    await tester.pumpWidget(await _screen(tester));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ProfileScreen)),
    );
    expect(container.read(settingsProvider).dark, isFalse);

    final darkRow = find.ancestor(
      of: find.text(S.settingDark),
      matching: find.byType(KalimatSwitch),
    );
    await tester.ensureVisible(darkRow);
    await tester.pump();
    await tester.tap(
      find.descendant(of: darkRow, matching: find.byType(GestureDetector)),
    );
    await tester.pump();

    expect(container.read(settingsProvider).dark, isTrue);
    expect(container.read(localStoreProvider).settings.dark, isTrue);
  });
}
