/// Guess evaluation. Pure Dart — no Flutter imports.
library;

import 'letters.dart';
import 'models.dart';

/// Evaluates [guess] against [target], both as lists of single letters.
///
/// Duplicate-safe two-pass algorithm (Wordle semantics): exact positions are
/// marked correct first, then remaining guess letters consume a pool of the
/// target's unmatched letters right-to-left in typing order for present marks.
/// Both sides are normalized, so e.g. a typed ه matches a target ة in place.
List<TileState> evaluateGuess(List<String> guess, List<String> target) {
  assert(guess.length == target.length);
  final g = guess.map(normalizeLetter).toList();
  final t = target.map(normalizeLetter).toList();
  final res = List.filled(g.length, TileState.absent);
  final pool = <String, int>{};
  for (var i = 0; i < g.length; i++) {
    if (g[i] == t[i]) {
      res[i] = TileState.correct;
    } else {
      pool[t[i]] = (pool[t[i]] ?? 0) + 1;
    }
  }
  for (var i = 0; i < g.length; i++) {
    if (res[i] != TileState.correct && (pool[g[i]] ?? 0) > 0) {
      res[i] = TileState.present;
      pool[g[i]] = pool[g[i]]! - 1;
    }
  }
  return res;
}
