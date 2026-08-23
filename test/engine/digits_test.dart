import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/core/utils/arabic_digits.dart';

void main() {
  test('digit conversion', () {
    expect(toArabicDigits('247'), '٢٤٧');
    expect(toArabicDigits('0123456789'), '٠١٢٣٤٥٦٧٨٩');
    expect(toArabicDigits('4/6'), '٤/٦');
  });

  test('non-digits untouched', () {
    expect(toArabicDigits('كلمات 247'), 'كلمات ٢٤٧');
  });

  test('percent formatting', () {
    expect(toArabicPercent(64), '٦٤٪');
  });
}
