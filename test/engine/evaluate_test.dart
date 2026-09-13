import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/game/engine/evaluate.dart';
import 'package:kalimat/game/engine/models.dart';

List<TileState> eval(String guess, String target) =>
    evaluateGuess(guess.split(''), target.split(''));
const c = TileState.correct;
const p = TileState.present;
const a = TileState.absent;

void main() {
  test('four-letter correct, absent and mixed rows', () {
    expect(eval('كتاب', 'كتاب'), [c, c, c, c]);
    expect(eval('جميل', 'وردة'), [a, a, a, a]);
    expect(eval('كاتب', 'كتاب'), [c, p, p, c]);
  });
  test('correct copies consume the pool before misplaced copies', () {
    expect(eval('دددد', 'دودو'), [c, a, c, a]);
    expect(eval('وددد', 'دودو'), [p, p, c, a]);
  });
  test('one target letter allows only one present copy', () {
    expect(eval('رررر', 'وردة'), [a, c, a, a]);
    expect(eval('ررxx', 'وردة'), [a, c, a, a]);
    expect(eval('رخرخ', 'وردة'), [p, a, a, a]);
  });
  test('lenient Arabic spellings produce four correct cells', () {
    for (final pair in [
      ('ورده', 'وردة'),
      ('احمر', 'أحمر'),
      ('مبني', 'مبنى'),
      ('لولو', 'لؤلؤ'),
      ('شاطي', 'شاطئ'),
      ('اوزة', 'إوزة'),
      ('امال', 'آمال'),
    ]) {
      expect(eval(pair.$1, pair.$2), [c, c, c, c]);
    }
  });
  test('standalone hamza stays separate; equivalents share a pool', () {
    expect(eval('ءحمر', 'أحمر'), [a, c, c, c]);
    expect(eval('هخخخ', 'وردة'), [p, a, a, a]);
    expect(eval('ااخخ', 'رأفة'), [a, c, a, a]);
  });
}
