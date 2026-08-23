/// Accepted-guess dictionary: lazily loaded set of normalized 5-letter words.
library;

import 'package:flutter/services.dart' show rootBundle;

import '../engine/letters.dart';

class GuessDictionary {
  Set<String>? _words;

  Future<void> ensureLoaded() async {
    if (_words != null) return;
    final raw = await rootBundle.loadString('assets/words/dictionary.txt');
    _words = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toSet();
  }

  /// Whether [word] (any spelling) is an accepted guess. The word of the day
  /// itself is always accepted, dictionary or not.
  bool contains(String word, {String? answer}) {
    final n = normalizeWord(word);
    if (answer != null && n == normalizeWord(answer)) return true;
    final words = _words;
    assert(words != null, 'call ensureLoaded() first');
    return words?.contains(n) ?? true; // fail open if not loaded
  }
}
