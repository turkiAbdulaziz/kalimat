import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/core/theme/kalimat_colors.dart';
import 'package:kalimat/core/theme/kalimat_theme.dart';
import 'package:kalimat/game/engine/models.dart';
import 'package:kalimat/game/widgets/tile.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: kalimatTheme(brightness),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: Center(child: child)),
      ),
    );

BoxDecoration _decorationOf(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(of: find.byType(Tile), matching: find.byType(Container)),
  );
  return container.decoration! as BoxDecoration;
}

BoxDecoration _decorationForLetter(WidgetTester tester, String letter) {
  final tile = find.ancestor(
    of: find.text(letter),
    matching: find.byType(Tile),
  );
  final container = tester.widget<Container>(
    find.descendant(of: tile, matching: find.byType(Container)),
  );
  return container.decoration! as BoxDecoration;
}

double _contrast(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() + 0.05;
  final darker = background.computeLuminance() + 0.05;
  return lighter > darker ? lighter / darker : darker / lighter;
}

void main() {
  final colors = KalimatColors.light();

  test('result palette keeps one identity across themes', () {
    final dark = KalimatColors.dark();
    expect(dark.tileCorrect, colors.tileCorrect);
    expect(dark.tilePresent, colors.tilePresent);
    expect(dark.tileAbsent, colors.tileAbsent);
    expect(dark.tileTextCorrect, colors.tileTextCorrect);
    expect(dark.tileTextPresent, colors.tileTextPresent);
    expect(dark.tileTextAbsent, colors.tileTextAbsent);
    expect(
      colors.tileCorrect.computeLuminance(),
      lessThan(colors.tilePresent.computeLuminance()),
    );
  });

  test('all evaluated letter foregrounds have large-text contrast', () {
    expect(
      _contrast(colors.tileTextCorrect, colors.tileCorrect),
      greaterThan(3),
    );
    expect(
      _contrast(colors.tileTextPresent, colors.tilePresent),
      greaterThan(3),
    );
    expect(_contrast(colors.tileTextAbsent, colors.tileAbsent), greaterThan(3));
  });

  for (final brightness in Brightness.values) {
    testWidgets('${brightness.name} evaluated tiles use semantic colors', (
      tester,
    ) async {
      final themeColors = brightness == Brightness.dark
          ? KalimatColors.dark()
          : KalimatColors.light();
      await tester.pumpWidget(
        _wrap(
          const Row(
            children: [
              Tile(letter: 'م', state: TileState.correct),
              Tile(letter: 'ك', state: TileState.present),
              Tile(letter: 'ت', state: TileState.absent),
            ],
          ),
          brightness: brightness,
        ),
      );

      expect(_decorationForLetter(tester, 'م').color, themeColors.tileCorrect);
      expect(_decorationForLetter(tester, 'ك').color, themeColors.tilePresent);
      expect(_decorationForLetter(tester, 'ت').color, themeColors.tileAbsent);
      expect(
        tester.widget<Text>(find.text('م')).style!.color,
        themeColors.tileTextCorrect,
      );
      expect(
        tester.widget<Text>(find.text('ك')).style!.color,
        themeColors.tileTextPresent,
      );
      expect(
        tester.widget<Text>(find.text('ت')).style!.color,
        themeColors.tileTextAbsent,
      );
    });
  }

  testWidgets('empty tile: transparent with brown-300 border', (tester) async {
    await tester.pumpWidget(_wrap(const Tile()));
    final deco = _decorationOf(tester);
    expect(deco.color, Colors.transparent);
    expect((deco.border! as Border).top.color, colors.tileEmptyBorder);
    expect((deco.border! as Border).top.width, 2);
  });

  testWidgets('filled tile: brown-500 border, body text', (tester) async {
    await tester.pumpWidget(
      _wrap(const Tile(letter: 'ب', state: TileState.filled)),
    );
    final deco = _decorationOf(tester);
    expect(deco.color, Colors.transparent);
    expect((deco.border! as Border).top.color, colors.tileFilledBorder);
  });

  testWidgets('reveal shows filled face until the flip midpoint', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const Tile(letter: 'م', state: TileState.correct, reveal: true)),
    );
    // Immediately after mount (flip not yet past midpoint): filled face.
    expect(_decorationOf(tester).color, Colors.transparent);
    // After the full flip: state face.
    await tester.pumpAndSettle();
    expect(_decorationOf(tester).color, colors.tileCorrect);
  });

  testWidgets('wave edge pops the tile; mount with wave does not', (
    tester,
  ) async {
    double scale() => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(Tile),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .storage[0];

    // Mounting with wave already true must NOT replay (remount mid-wave).
    await tester.pumpWidget(
      _wrap(const Tile(letter: 'م', state: TileState.correct, wave: true)),
    );
    await tester.pump(const Duration(milliseconds: 110));
    expect(scale(), 1.0);

    // The false→true edge pops: scale rises above 1 near the pop's peak
    // (~60ms; the overshoot back half dips slightly below 1 by design).
    await tester.pumpWidget(
      _wrap(const Tile(letter: 'م', state: TileState.correct)),
    );
    await tester.pumpWidget(
      _wrap(const Tile(letter: 'م', state: TileState.correct, wave: true)),
    );
    await tester.pump(const Duration(milliseconds: 30)); // zero timer + tick
    await tester.pump(const Duration(milliseconds: 30));
    expect(scale(), greaterThan(1.01));
    await tester.pumpAndSettle();
    expect(scale(), 1.0);
  });
}
