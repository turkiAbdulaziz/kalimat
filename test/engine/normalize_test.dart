import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/game/engine/letters.dart';

void main() {
  group('normalizeLetter', () {
    test('hamza-on-alef forms fold to alef', () {
      expect(normalizeLetter('أ'), 'ا');
      expect(normalizeLetter('إ'), 'ا');
      expect(normalizeLetter('آ'), 'ا');
    });

    test('taa marbuta folds to haa, alef maqsura to yaa', () {
      expect(normalizeLetter('ة'), 'ه');
      expect(normalizeLetter('ى'), 'ي');
    });

    test('hamza carriers fold to their seats', () {
      expect(normalizeLetter('ؤ'), 'و');
      expect(normalizeLetter('ئ'), 'ي');
    });

    test('standalone hamza stays its own letter', () {
      expect(normalizeLetter('ء'), 'ء');
    });

    test('plain letters unchanged', () {
      expect(normalizeLetter('ب'), 'ب');
      expect(normalizeLetter('ا'), 'ا');
    });
  });

  group('stripMarks', () {
    test('removes harakat', () {
      expect(stripMarks('مَدْرَسَة'), 'مدرسة');
    });

    test('removes tatweel and superscript alef', () {
      expect(stripMarks('مـدرسـة'), 'مدرسة');
      expect(stripMarks('رحمٰن'), 'رحمن');
    });

    test('removes zero-width and bidi marks', () {
      expect(stripMarks('‏مدرسة​'), 'مدرسة');
    });
  });

  group('normalizeWord', () {
    test('folds all letters', () {
      expect(normalizeWord('مدرسة'), 'مدرسه');
      expect(normalizeWord('أسماء'), 'اسماء');
      expect(normalizeWord('مستشفى'), 'مستشفي');
      expect(normalizeWord('مؤمّن'), 'مومن');
    });
  });

  group('keyboard layout', () {
    test('exactly 33 keys in 3 rows of 11', () {
      expect(kKeyboardRows.length, 3);
      for (final row in kKeyboardRows) {
        expect(row.length, 11);
      }
      expect(kKeyboardLetters.length, 33);
    });

    test('target-only letters have no key but normalize onto keys', () {
      for (final l in kTargetOnlyLetters) {
        expect(kKeyboardLetters.contains(l), isFalse);
        expect(kKeyboardLetters.contains(normalizeLetter(l)), isTrue);
      }
    });
  });
}
