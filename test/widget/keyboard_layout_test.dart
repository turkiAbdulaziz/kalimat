import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/core/strings.dart';
import 'package:kalimat/core/theme/kalimat_colors.dart';
import 'package:kalimat/core/theme/kalimat_theme.dart';
import 'package:kalimat/game/engine/letters.dart';
import 'package:kalimat/game/engine/models.dart';
import 'package:kalimat/game/widgets/keyboard.dart';
import 'package:kalimat/game/widgets/key_cap.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: kalimatTheme(brightness),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    );

BoxDecoration _keyDecoration(WidgetTester tester, String label) {
  final key = find.ancestor(
    of: find.text(label),
    matching: find.byType(KeyCap),
  );
  final container = tester.widget<AnimatedContainer>(
    find.descendant(of: key, matching: find.byType(AnimatedContainer)),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('keyboard renders all 33 letters plus enter/delete', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const GameKeyboard()));
    for (final row in kKeyboardRows) {
      for (final letter in row) {
        expect(find.text(letter), findsOneWidget, reason: 'key $letter');
      }
    }
    expect(find.text(S.enterKey), findsOneWidget);
    expect(find.text(S.deleteKey), findsOneWidget);
  });

  testWidgets('RTL: alphabetical order runs right-to-left', (tester) async {
    await tester.pumpWidget(_wrap(const GameKeyboard()));
    final alef = tester.getCenter(find.text('ا'));
    final ba = tester.getCenter(find.text('ب'));
    final zay = tester.getCenter(find.text('ز'));
    expect(alef.dx, greaterThan(ba.dx), reason: 'ا is right of ب');
    expect(ba.dx, greaterThan(zay.dx), reason: 'row runs toward the left');
  });

  testWidgets('enter key sits at the right edge of row 3 (RTL start)', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const GameKeyboard()));
    final enter = tester.getCenter(find.text(S.enterKey));
    final delete = tester.getCenter(find.text(S.deleteKey));
    final lam = tester.getCenter(find.text('ل')); // first letter of row 3
    expect(enter.dx, greaterThan(lam.dx));
    expect(delete.dx, lessThan(lam.dx));
  });

  testWidgets('key presses reach callbacks', (tester) async {
    final pressed = <String>[];
    var enters = 0, deletes = 0;
    await tester.pumpWidget(
      _wrap(
        GameKeyboard(
          onKey: pressed.add,
          onEnter: () => enters++,
          onDelete: () => deletes++,
        ),
      ),
    );
    await tester.tap(find.text('م'));
    await tester.tap(find.text(S.enterKey));
    await tester.tap(find.text(S.deleteKey));
    expect(pressed, ['م']);
    expect(enters, 1);
    expect(deletes, 1);
  });

  testWidgets('hint states color equivalence classes together', (tester) async {
    await tester.pumpWidget(
      _wrap(
        GameKeyboard(letterStates: {normalizeLetter('أ'): TileState.correct}),
      ),
    );
    await tester.pump();
    // Both أ and إ and ا share the canonical ا class — all should resolve
    // the same state through normalizeLetter at lookup time.
    // (Visual color assertions are covered in tile_state_test.)
    expect(find.text('أ'), findsOneWidget);
    expect(find.text('إ'), findsOneWidget);
    expect(find.text('ا'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('${brightness.name} keys match board state colors', (
      tester,
    ) async {
      final colors = brightness == Brightness.dark
          ? KalimatColors.dark()
          : KalimatColors.light();
      await tester.pumpWidget(
        _wrap(
          GameKeyboard(
            letterStates: {
              normalizeLetter('ا'): TileState.correct,
              normalizeLetter('ح'): TileState.present,
              normalizeLetter('ج'): TileState.absent,
            },
          ),
          brightness: brightness,
        ),
      );
      await tester.pump();

      expect(_keyDecoration(tester, 'ا').color, colors.tileCorrect);
      expect(_keyDecoration(tester, 'ح').color, colors.tilePresent);
      expect(_keyDecoration(tester, 'ج').color, colors.tileAbsent);
      expect(
        tester.widget<Text>(find.text('ا')).style!.color,
        colors.tileTextCorrect,
      );
      expect(
        tester.widget<Text>(find.text('ح')).style!.color,
        colors.tileTextPresent,
      );
      expect(
        tester.widget<Text>(find.text('ج')).style!.color,
        colors.tileTextAbsent,
      );
    });
  }
}
