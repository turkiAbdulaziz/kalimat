/// Puzzle numbering. Pure Dart — no Flutter imports.
///
/// The epoch date is puzzle ١ and must match tool/build_wordlists.dart and
/// the Supabase daily_words seed. The server's Asia/Riyadh calendar is the
/// authority whenever the app is online; these helpers cover the offline
/// fallback using the device's local date.
library;

/// 2026-09-01 = puzzle ١.
final DateTime kEpoch = DateTime(2026, 9, 1);

/// Date-only (strips the time component).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 1-based puzzle number for [date]. Dates before the epoch clamp to 1.
int puzzleNumberFor(DateTime date) {
  final days = dateOnly(date).difference(kEpoch).inDays;
  return days < 0 ? 1 : days + 1;
}

/// The calendar date of puzzle [puzzleNo].
DateTime dateForPuzzle(int puzzleNo) =>
    kEpoch.add(Duration(days: puzzleNo - 1));

/// Offline fallback answer index into the bundled ordered answers list.
int bundledAnswerIndex(int puzzleNo, int answersLength) =>
    (puzzleNo - 1) % answersLength;
