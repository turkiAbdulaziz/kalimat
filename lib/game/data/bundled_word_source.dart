/// Offline fallback word source reading the bundled ordered answers list.
///
/// The Supabase daily_words table is seeded from the same file in the same
/// order, so offline and online agree on the word for any given date.
library;

import 'package:flutter/services.dart' show rootBundle;

import '../engine/models.dart';
import '../engine/game_rules.dart';
import '../engine/puzzle_calendar.dart';
import 'word_source.dart';

class BundledWordSource implements WordSource {
  List<String>? _answers;

  Future<List<String>> _load() async {
    final cached = _answers;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/words/answers.txt');
    final answers = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .toList(growable: false);
    if (answers.isEmpty || !answers.every(isPlayableWord)) {
      throw StateError('Bundled answers are incompatible with game rules');
    }
    _answers = answers;
    return answers;
  }

  @override
  Future<DailyWord> getTodayWord(DateTime today) async {
    final answers = await _load();
    final no = puzzleNumberFor(today);
    return DailyWord(
      date: dateOnly(today),
      puzzleNo: no,
      word: answers[bundledAnswerIndex(no, answers.length)],
      fromServer: false,
    );
  }
}
