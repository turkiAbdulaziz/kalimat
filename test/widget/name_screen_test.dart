import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/core/strings.dart';
import 'package:kalimat/core/theme/kalimat_theme.dart';
import 'package:kalimat/flow/flow_controller.dart';
import 'package:kalimat/game/data/local_store.dart';
import 'package:kalimat/game/state/settings_controller.dart';
import 'package:kalimat/game/widgets/kalimat_button.dart';
import 'package:kalimat/onboarding/name_screen.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Future<Widget> _screen(WidgetTester tester) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final store = (await tester.runAsync(LocalStore.create))!;
  return ProviderScope(
    overrides: [localStoreProvider.overrideWithValue(store)],
    child: MaterialApp(
      theme: kalimatTheme(Brightness.light),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: NameScreen(),
      ),
    ),
  );
}

bool _startDisabled(WidgetTester tester) => tester
    .widget<KalimatButton>(find.widgetWithText(KalimatButton, S.startPlaying))
    .disabled;

void main() {
  testWidgets('start button needs at least 2 trimmed characters', (
    tester,
  ) async {
    await tester.pumpWidget(await _screen(tester));
    await tester.pump();

    expect(_startDisabled(tester), isTrue);

    await tester.enterText(find.byType(TextField), 'ل');
    await tester.pump();
    expect(_startDisabled(tester), isTrue);

    await tester.enterText(find.byType(TextField), 'ليلى');
    await tester.pump();
    expect(_startDisabled(tester), isFalse);
  });

  testWidgets('input is capped at 20 characters', (tester) async {
    await tester.pumpWidget(await _screen(tester));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'ا' * 25);
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, 20);
  });

  testWidgets('completing the name caches it and moves the flow to game', (
    tester,
  ) async {
    await tester.pumpWidget(await _screen(tester));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(NameScreen)),
    );

    await tester.enterText(find.byType(TextField), 'ليلى');
    await tester.pump();
    await tester.tap(find.text(S.startPlaying));
    await tester.pump();

    expect(container.read(flowProvider), FlowStep.game);
    expect(container.read(displayNameProvider), 'ليلى');
    expect(container.read(localStoreProvider).displayName, 'ليلى');
    expect(container.read(localStoreProvider).onboarded, isTrue);
  });

  testWidgets('skip falls back to the guest name', (tester) async {
    await tester.pumpWidget(await _screen(tester));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(NameScreen)),
    );

    await tester.tap(find.text(S.skip));
    await tester.pump();

    expect(container.read(flowProvider), FlowStep.game);
    expect(container.read(displayNameProvider), S.guestName);
    expect(container.read(localStoreProvider).onboarded, isTrue);
  });
}
