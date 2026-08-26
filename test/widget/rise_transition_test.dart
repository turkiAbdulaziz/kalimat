/// The kalimat-rise screen transitions: riseRoute push/pop, the motion
/// setting gate, and RootFlow's animated step switch (sign-out → sign-in
/// rising over the fading game, profile round trip via the header avatar).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/app.dart';
import 'package:kalimat/core/rise_route.dart';
import 'package:kalimat/flow/flow_controller.dart';
import 'package:kalimat/game/data/dictionary.dart';
import 'package:kalimat/game/data/local_store.dart';
import 'package:kalimat/game/engine/models.dart';
import 'package:kalimat/game/game_screen.dart';
import 'package:kalimat/game/state/game_controller.dart';
import 'package:kalimat/game/state/settings_controller.dart';
import 'package:kalimat/game/widgets/kalimat_avatar.dart';
import 'package:kalimat/onboarding/sign_in_screen.dart';
import 'package:kalimat/profile/profile_screen.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

// Real asset I/O — must load outside testWidgets (see rtl_smoke_test).
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
      initialWordProvider.overrideWithValue(
        DailyWord(
          date: DateTime(2026, 9, 1),
          puzzleNo: 1,
          word: 'مدرسة',
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

  group('riseRoute', () {
    testWidgets('push rises in over the old screen, pop sinks out', (
      tester,
    ) async {
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          home: const Scaffold(body: Text('home')),
        ),
      );

      nav.currentState!.push(
        riseRoute(
          motion: true,
          builder: (_) => const Scaffold(body: Text('pushed')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 110)); // mid-flight
      expect(find.text('home'), findsOneWidget); // still painted beneath
      expect(find.text('pushed'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('pushed'), findsOneWidget);
      expect(find.text('home'), findsNothing); // offstage under opaque route

      nav.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 110)); // sinking out
      expect(find.text('home'), findsOneWidget);
      expect(find.text('pushed'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('pushed'), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('motion off swaps in a single frame', (tester) async {
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          home: const Scaffold(body: Text('home')),
        ),
      );

      nav.currentState!.push(
        riseRoute(
          motion: false,
          builder: (_) => const Scaffold(body: Text('pushed')),
        ),
      );
      await tester.pump();
      // Instant: the old screen is already offstage on the first frame.
      expect(find.text('pushed'), findsOneWidget);
      expect(find.text('home'), findsNothing);
    });
  });

  group('RootFlow step switch', () {
    testWidgets('sign-out: sign-in rises in while the game fades out', (
      tester,
    ) async {
      await tester.pumpWidget(await _app(tester, prefs: {'help_seen': true}));
      await tester.pump();
      expect(find.byType(GameScreen), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameScreen)),
      );
      await container.read(flowProvider.notifier).signOut();
      await tester.pump(); // switcher gets the new entry
      await tester.pump(const Duration(milliseconds: 110)); // mid-transition
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(GameScreen), findsOneWidget); // still fading

      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(GameScreen), findsNothing);
    });

    testWidgets('sign-out with motion off is an instant swap', (tester) async {
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

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameScreen)),
      );
      await container.read(flowProvider.notifier).signOut();
      await tester.pump();
      await tester.pump();
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(GameScreen), findsNothing);
    });
  });

  testWidgets('profile round trip through the header avatar', (tester) async {
    await tester.pumpWidget(await _app(tester, prefs: {'help_seen': true}));
    await tester.pump();

    await tester.tap(find.byType(KalimatAvatar));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110)); // rising in
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(GameScreen), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing); // offstage beneath

    Navigator.of(tester.element(find.byType(ProfileScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsNothing);
    expect(find.byType(GameScreen), findsOneWidget); // board surface is back
  });
}
