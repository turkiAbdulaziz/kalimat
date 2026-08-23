/// Share-text builder. Pure Dart — no Flutter imports.
///
/// Format (design: «مربعات فقط، بلا نص إضافي» — squares only, no extra text):
///
///     كلمات ٢٤٧ — ٤/٦
///     🟫🟨⬜⬜🟫
///     ...
///
/// Each square line is prefixed with U+200F (RLM) so bidi keeps letter
/// index 0 rightmost — matching the RTL board — in share targets.
library;

import '../../core/utils/arabic_digits.dart';
import 'models.dart';

const String _rlm = '‏';
const String _squareCorrect = '🟫';
const String _squarePresent = '🟨';
const String _squareAbsent = '⬜';

String _square(TileState s) => switch (s) {
  TileState.correct => _squareCorrect,
  TileState.present => _squarePresent,
  _ => _squareAbsent,
};

/// Builds the complete share text for a finished game.
///
/// [rows] holds the evaluated states of each guessed row, in guess order.
/// On a loss pass [won] = false; the score renders as «—/٦».
String buildShareText({
  required int puzzleNo,
  required bool won,
  required List<List<TileState>> rows,
}) {
  final score = won ? toArabicDigits('${rows.length}') : '—';
  final header = '$_rlmكلمات ${toArabicDigits('$puzzleNo')} — $score/٦';
  final lines = [
    header,
    for (final row in rows) _rlm + row.map(_square).join(),
  ];
  return lines.join('\n');
}
