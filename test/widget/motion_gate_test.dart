/// M7a: MotionScope gate + the shared motion primitives.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/core/motion/celebration_pop.dart';
import 'package:kalimat/core/motion/count_up_text.dart';
import 'package:kalimat/core/motion/staggered_rise.dart';
import 'package:kalimat/core/theme/kalimat_theme.dart';
import 'package:kalimat/core/theme/motion.dart';
import 'package:kalimat/core/theme/motion_scope.dart';
import 'package:kalimat/game/widgets/distribution_bar.dart';
import 'package:kalimat/game/widgets/toast_slot.dart';

Widget _wrap(Widget child, {bool? motion}) => MaterialApp(
  theme: kalimatTheme(Brightness.light),
  home: Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: Center(
        child: motion == null
            ? child
            : MotionScope(enabled: motion, child: child),
      ),
    ),
  ),
);

void main() {
  group('MotionScope', () {
    testWidgets('defaults to enabled with no ancestor', (tester) async {
      late bool enabled;
      late Duration duration;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              enabled = context.motionEnabled;
              duration = context.motionDuration(Motion.base);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(enabled, isTrue);
      expect(duration, Motion.base);
    });

    testWidgets('disabled scope zeroes token durations', (tester) async {
      late Duration duration;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              duration = context.motionDuration(Motion.slow);
              return const SizedBox();
            },
          ),
          motion: false,
        ),
      );
      expect(duration, Duration.zero);
    });
  });

  group('DistributionBar', () {
    testWidgets('width grows over 420ms with motion on', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 300,
            child: DistributionBar(guess: 3, count: 4, max: 4),
          ),
          motion: true,
        ),
      );
      // Mid-flight: partially grown.
      await tester.pump(const Duration(milliseconds: 210));
      final mid = tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor!;
      expect(mid, greaterThan(.06));
      expect(mid, lessThan(1));
      await tester.pumpAndSettle();
      final done = tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor!;
      expect(done, 1);
    });

    testWidgets('motion off renders full width in a single frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 300,
            child: DistributionBar(guess: 3, count: 4, max: 4),
          ),
          motion: false,
        ),
      );
      final factor = tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor!;
      expect(factor, 1);
    });

    testWidgets('delay holds the fill until it elapses', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 300,
            child: DistributionBar(
              guess: 1,
              count: 2,
              max: 2,
              delay: Duration(milliseconds: 200),
            ),
          ),
          motion: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final held = tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor!;
      expect(held, .06); // clamped stub, not yet growing
      await tester.pumpAndSettle();
      final done = tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor!;
      expect(done, 1);
    });
  });

  group('CountUpText', () {
    testWidgets('disabled renders the final Arabic-Indic value at once', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const CountUpText(value: 42, enabled: false, suffix: '٪')),
      );
      expect(find.text('٤٢٪'), findsOneWidget);
    });

    testWidgets('enabled ticks up from zero to the value', (tester) async {
      await tester.pumpWidget(
        _wrap(const CountUpText(value: 42, enabled: true)),
      );
      expect(find.text('٠'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('٤٢'), findsOneWidget);
    });
  });

  group('CelebrationPop', () {
    double scaleOf(WidgetTester tester) => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(CelebrationPop),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .storage[0];

    testWidgets('pops when popKey changes, not on mount', (tester) async {
      await tester.pumpWidget(
        _wrap(const CelebrationPop(popKey: 3, child: Text('س'))),
      );
      await tester.pump(const Duration(milliseconds: 60));
      expect(scaleOf(tester), 1.0); // mount alone never pops

      await tester.pumpWidget(
        _wrap(const CelebrationPop(popKey: 4, child: Text('س'))),
      );
      await tester.pump(const Duration(milliseconds: 60));
      expect(scaleOf(tester), greaterThan(1.01));
      await tester.pumpAndSettle();
      expect(scaleOf(tester), 1.0);
    });

    testWidgets('celebrateOnMount pops after its delay', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CelebrationPop(
            celebrateOnMount: true,
            delay: Duration(milliseconds: 200),
            child: Text('س'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(scaleOf(tester), 1.0); // still holding
      await tester.pump(const Duration(milliseconds: 110)); // timer fires
      await tester.pump(const Duration(milliseconds: 60)); // pop mid-flight
      expect(scaleOf(tester), greaterThan(1.01));
      await tester.pumpAndSettle();
    });

    testWidgets('motion off: never pops', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CelebrationPop(celebrateOnMount: true, child: Text('س')),
          motion: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));
      expect(scaleOf(tester), 1.0);
    });
  });

  group('ToastSlot opponent pill', () {
    testWidgets('pops once when the badge value changes', (tester) async {
      double scaleOf() => tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(CelebrationPop),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .storage[0];

      await tester.pumpWidget(
        _wrap(const ToastSlot(puzzleNo: 1, badge: 'ليلى في المحاولة ٢')),
      );
      await tester.pump(const Duration(milliseconds: 60));
      expect(scaleOf(), 1.0); // mount alone never pops

      await tester.pumpWidget(
        _wrap(const ToastSlot(puzzleNo: 1, badge: 'ليلى في المحاولة ٣')),
      );
      await tester.pump(const Duration(milliseconds: 60));
      expect(scaleOf(), greaterThan(1.01));
      await tester.pumpAndSettle();
      expect(scaleOf(), 1.0);
      expect(find.text('ليلى في المحاولة ٣'), findsOneWidget);
    });
  });

  group('StaggeredRise', () {
    testWidgets('disabled shows all children settled in one frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const StaggeredRise(
            enabled: false,
            children: [Text('أ'), Text('ب'), Text('ج')],
          ),
        ),
      );
      for (final t in ['أ', 'ب', 'ج']) {
        final fade = tester.widget<FadeTransition>(
          find.ancestor(of: find.text(t), matching: find.byType(FadeTransition))
              .first,
        );
        expect(fade.opacity.value, 1);
      }
    });

    testWidgets('enabled staggers: later children lag earlier ones', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const StaggeredRise(
            enabled: true,
            interval: Duration(milliseconds: 60),
            children: [Text('أ'), Text('ب'), Text('ج')],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 80));
      double opacityOf(String t) => tester
          .widget<FadeTransition>(
            find
                .ancestor(of: find.text(t), matching: find.byType(FadeTransition))
                .first,
          )
          .opacity
          .value;
      expect(opacityOf('أ'), greaterThan(opacityOf('ج')));
      await tester.pumpAndSettle();
      expect(opacityOf('أ'), 1);
      expect(opacityOf('ج'), 1);
    });
  });
}
