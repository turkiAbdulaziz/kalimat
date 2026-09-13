import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/game/engine/models.dart';
import 'package:kalimat/game/engine/share_grid.dart';

const c = TileState.correct;
const p = TileState.present;
const a = TileState.absent;

void main() {
  test('win share text: Arabic-Indic digits, RLM-prefixed lines', () {
    final text = buildShareText(
      puzzleNo: 247,
      won: true,
      rows: [
        [c, p, a, c],
        [c, c, c, c],
      ],
    );
    expect(text, '‏كلمات ٢٤٧ — ٢/٦\n‏🟫🟨⬜🟫\n‏🟫🟫🟫🟫');
  });

  test('loss renders —/٦', () {
    final text = buildShareText(
      puzzleNo: 3,
      won: false,
      rows: [
        [a, a, a, a],
      ],
    );
    expect(text.split('\n').first, '‏كلمات ٣ — —/٦');
  });

  test('duel sharing decodes four-cell server-only recaps', () {
    final rows = decodeResultGrid('0120|2222');
    final text = buildChallengeShareText(
      myName: 'ليلى',
      opponentName: 'تركي',
      won: true,
      opponentWon: false,
      opponentGuesses: 6,
      rows: rows,
    );
    expect(text, '‏كلمات — تحدٍّ\n‏ليلى ٢/٦ · تركي —/٦\n‏⬜🟨🟫⬜\n‏🟫🟫🟫🟫');
    expect(decodeResultGrid('22222'), isEmpty);
    expect(
      () => buildShareText(
        puzzleNo: 1,
        won: true,
        rows: [
          [c, c, c, c, c],
        ],
      ),
      throwsArgumentError,
    );
  });

  test('no extra text beyond header and rows', () {
    final text = buildShareText(
      puzzleNo: 1,
      won: true,
      rows: [
        [c, c, c, c],
      ],
    );
    expect(text.split('\n').length, 2);
  });
}
