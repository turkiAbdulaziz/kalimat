/// Keyboard hint state tracking. Pure Dart — no Flutter imports.
library;

import 'letters.dart';
import 'models.dart';

const Map<TileState, int> _rank = {
  TileState.absent: 0,
  TileState.present: 1,
  TileState.correct: 2,
};

/// Returns a new map with the best-known state per canonical letter class
/// after revealing one row. States only ever upgrade
/// (absent < present < correct).
///
/// Keys are canonical letters, so looking up `normalizeLetter(keyLabel)`
/// colors أ/إ/ا (and ه/ة, ي/ى) together for free.
Map<String, TileState> updateKeyStates(
  Map<String, TileState> current,
  List<String> guess,
  List<TileState> rowStates,
) {
  final next = Map<String, TileState>.of(current);
  for (var i = 0; i < guess.length; i++) {
    final c = normalizeLetter(guess[i]);
    final existing = next[c];
    if (existing == null || _rank[rowStates[i]]! > _rank[existing]!) {
      next[c] = rowStates[i];
    }
  }
  return next;
}
