import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/game/engine/puzzle_calendar.dart';

void main() {
  test('epoch date is puzzle 1', () {
    expect(puzzleNumberFor(DateTime(2026, 9, 1)), 1);
    expect(puzzleNumberFor(DateTime(2026, 9, 1, 23, 59)), 1);
  });

  test('sequential days increment', () {
    expect(puzzleNumberFor(DateTime(2026, 9, 2)), 2);
    expect(puzzleNumberFor(DateTime(2026, 10, 1)), 31);
  });

  test('pre-epoch clamps to 1', () {
    expect(puzzleNumberFor(DateTime(2026, 8, 31)), 1);
  });

  test('round trip', () {
    expect(dateForPuzzle(247), DateTime(2027, 5, 5));
    expect(puzzleNumberFor(dateForPuzzle(247)), 247);
  });

  test('bundled answer index wraps', () {
    expect(bundledAnswerIndex(1, 500), 0);
    expect(bundledAnswerIndex(500, 500), 499);
    expect(bundledAnswerIndex(501, 500), 0);
  });
}
