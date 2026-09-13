import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/core/strings.dart';
import 'package:kalimat/core/theme/kalimat_theme.dart';
import 'package:kalimat/flow/flow_controller.dart';
import 'package:kalimat/game/data/local_store.dart';
import 'package:kalimat/game/state/settings_controller.dart';
import 'package:kalimat/game/widgets/tile.dart';
import 'package:kalimat/onboarding/sign_in_screen.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

Future<Widget> _screen(
  WidgetTester tester, {
  Map<String, Object> prefs = const {
    // Motion off keeps the sample-row flip out of the pump timeline.
    'settings': '{"dark":false,"hints":true,"motion":false}',
  },
}) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData(prefs);
  final store = (await tester.runAsync(LocalStore.create))!;
  return ProviderScope(
    overrides: [localStoreProvider.overrideWithValue(store)],
    child: MaterialApp(
      theme: kalimatTheme(Brightness.light),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: SignInScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('renders hero, sample row, auth buttons, and legal line', (
    tester,
  ) async {
    await tester.pumpWidget(await _screen(tester));
    await tester.pump();

    expect(find.text(S.appTitle), findsOneWidget);
    expect(find.text(S.signInPitch), findsOneWidget);
    expect(find.byType(Tile), findsNWidgets(4));
    // No GOOGLE_WEB_CLIENT_ID under `flutter test` ⇒ Google is hidden and
    // Apple takes the primary slot; a dead Google button would be an App
    // Review rejection.
    expect(find.text(S.continueWithGoogle), findsNothing);
    expect(find.byType(SignInWithAppleButton), findsOneWidget);
    expect(find.text(S.continueWithAppleOfficial), findsOneWidget);
    expect(find.text(S.continueAsGuest), findsOneWidget);
    expect(find.text(S.continueAsGuestEnglish), findsOneWidget);
    expect(find.text(S.legalLine), findsOneWidget);
  });

  testWidgets('guest tap marks onboarding done and moves the flow to game', (
    tester,
  ) async {
    await tester.pumpWidget(await _screen(tester));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SignInScreen)),
    );
    final store = container.read(localStoreProvider);

    await tester.tap(find.text(S.continueAsGuest));
    await tester.pump();

    expect(container.read(flowProvider), FlowStep.game);
    expect(store.onboarded, isTrue);
  });

  testWidgets('sign-in without a backend shows the connection error line', (
    tester,
  ) async {
    await tester.pumpWidget(await _screen(tester));
    await tester.pump();

    // Supabase is unconfigured in tests, so ensureSession() fails fast.
    await tester.tap(find.byType(SignInWithAppleButton));
    await tester.pump();
    await tester.pump();

    expect(find.text(S.connectionFailed), findsOneWidget);
  });
}
