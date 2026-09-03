import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/core/theme/kalimat_colors.dart';
import 'package:kalimat/core/theme/kalimat_theme.dart';
import 'package:kalimat/game/engine/models.dart';
import 'package:kalimat/game/widgets/tile.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: kalimatTheme(Brightness.light),
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

void main() {
  final colors = KalimatColors.light();

  testWidgets('correct tile: brown-700 fill, white text', (tester) async {
    await tester.pumpWidget(
      _wrap(const Tile(letter: 'م', state: TileState.correct)),
    );
    final deco = _decorationOf(tester);
    expect(deco.color, colors.tileCorrect);
    final text = tester.widget<Text>(find.text('م'));
    expect(text.style!.color, colors.tileTextOnState);
  });

  testWidgets('present tile: brown-400 fill', (tester) async {
    await tester.pumpWidget(
      _wrap(const Tile(letter: 'ك', state: TileState.present)),
    );
    expect(_decorationOf(tester).color, colors.tilePresent);
  });

  testWidgets('absent tile: taupe-500 fill', (tester) async {
    await tester.pumpWidget(
      _wrap(const Tile(letter: 'ت', state: TileState.absent)),
    );
    expect(_decorationOf(tester).color, colors.tileAbsent);
  });

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
              .descendant(of: find.byType(Tile), matching: find.byType(Transform))
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
