import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/game/engine/evaluate.dart';
import 'package:kalimat/game/engine/models.dart';

List<TileState> eval(String guess, String target) =>
    evaluateGuess(guess.split(''), target.split(''));

const c = TileState.correct;
const p = TileState.present;
const a = TileState.absent;

void main() {
  group('basic evaluation', () {
    test('all correct', () {
      expect(eval('مدرسة', 'مدرسة'), [c, c, c, c, c]);
    });

    test('all absent', () {
      expect(eval('خبزنا', 'مدرسة'), [a, a, a, a, a]);
    });

    test('mixed correct/present/absent', () {
      // target كتابة, guess كتوبا: ك ت aligned, و absent, ب aligned,
      // trailing ا present (target's ا at index 2).
      expect(eval('كتوبا', 'كتابة'), [c, c, a, c, p]);
    });
  });

  group('duplicate letters (two-pass pool semantics)', () {
    test('guess repeats a letter the target has once: second copy absent', () {
      // target مدرسة: م only at index 0. guess ممنوع:
      // i0 م correct; i1 م — pool {د,ر,س,ه} has no م — absent.
      final r = eval('ممنوع', 'مدرسة');
      expect(r[0], c);
      expect(r[1], a);
    });

    test('guess letter twice, target has it once elsewhere: one present', () {
      // target مدرسة, guess سمسار: no exact matches; pool {م,د,ر,س,ه}.
      // i0 س present, i1 م present, i2 س pool exhausted absent, ا absent,
      // ر present.
      expect(eval('سمسار', 'مدرسة'), [p, p, a, a, p]);
    });

    test('correct copies consume before present copies', () {
      // target سلسال (س at 0 and 2): guess سسسسس marks exactly the two
      // aligned positions correct, the rest absent.
      expect(eval('سسسسس', 'سلسال'), [c, a, c, a, a]);
    });

    test('present copies limited by remaining pool count', () {
      // target سلسال, guess خسسسخ: i2 س correct (aligned), pool has one more
      // س -> i1 present, i3 absent.
      expect(eval('خسسسخ', 'سلسال'), [a, p, c, a, a]);
    });
  });

  group('normalized (lenient) matching', () {
    test('typed ه matches target ة in place', () {
      expect(eval('مدرسه', 'مدرسة'), [c, c, c, c, c]);
    });

    test('typed ا matches target أ in place', () {
      expect(eval('اسواق', 'أسواق'), [c, c, c, c, c]);
    });

    test('typed ي matches target ى in place', () {
      expect(eval('مستوي', 'مستوى'), [c, c, c, c, c]);
    });

    test('typed و matches target ؤ, typed ي matches target ئ', () {
      expect(eval('مسوول', 'مسؤول'), [c, c, c, c, c]);
      expect(eval('طواري', 'طوارئ'), [c, c, c, c, c]);
    });

    test('ء does NOT match أ (hamza is its own letter)', () {
      final r = eval('ءسواق', 'أسواق');
      expect(r[0], a);
    });

    test('cross-class present: typed ه counts for a target ة elsewhere', () {
      // target مدرسة normalizes to مدرسه; a ه anywhere in the guess is
      // present via the pool.
      expect(eval('هخخخخ', 'مدرسة')[0], p);
    });

    test('normalized letter counts share one pool', () {
      // target مأمور: single alef-class letter (أ at index 1). Guess with
      // both ا and أ: the aligned أ is correct, the extra ا finds an empty
      // pool and is absent.
      final r = eval('اأخخخ', 'مأمور');
      expect(r[0], a); // ا at index 0: target has م there, pool ا exhausted
      expect(r[1], c); // أ aligns with target أ (both normalize to ا)
    });
  });
}
