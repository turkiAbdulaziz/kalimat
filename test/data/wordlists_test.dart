import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/game/data/bundled_word_source.dart';
import 'package:kalimat/game/engine/game_rules.dart';
import 'package:kalimat/game/engine/letters.dart';
import 'package:kalimat/game/engine/puzzle_calendar.dart';

import '../../tool/build_wordlists.dart' as pipeline;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('curated answer pools and deterministic committed outputs', () {
    final daily = pipeline.readWords('assets/words/answers.txt');
    final duels = pipeline.readWords('tool/curated/duel_answers.txt');
    final dictionary = pipeline
        .readWords('assets/words/dictionary.txt')
        .toSet();
    expect(daily, hasLength(365));
    expect(duels, hasLength(200));
    expect({
      ...daily.map(normalizeWord),
      ...duels.map(normalizeWord),
    }, hasLength(565));
    expect([...daily, ...duels].every(isPlayableWord), isTrue);
    expect(
      [
        ...daily,
        ...duels,
      ].every((word) => dictionary.contains(normalizeWord(word))),
      isTrue,
    );
    expect(dictionary.every(isPlayableWord), isTrue);
    expect(dictionary.length, greaterThan(daily.length + duels.length));
    final first = pipeline.generateWordlists();
    expect(pipeline.generateWordlists(), first);
    for (final entry in first.entries) {
      expect(
        File(entry.key).readAsStringSync(),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('all 365 online dates and answers match offline schedule', () async {
    final source = BundledWordSource();
    final daily = pipeline.readWords('assets/words/answers.txt');
    final seed = File('supabase/seed/daily_words_seed.sql').readAsStringSync();
    for (var i = 0; i < daily.length; i++) {
      final date = dateForPuzzle(i + 1);
      final offline = await source.getTodayWord(date);
      expect(offline.word, daily[i]);
      expect(offline.puzzleNo, i + 1);
      expect(
        seed,
        contains(
          "('${date.toIso8601String().substring(0, 10)}', ${i + 1}, '${offline.word}')",
        ),
      );
    }
  });

  test('invalid curation fails before any output is written', () {
    final root = Directory.current;
    final temporary = Directory.systemTemp.createTempSync('kalimat-wordlists-');
    try {
      for (final path in [
        'assets/words/answers.txt',
        'assets/words/dictionary.txt',
        'tool/raw/freq_ar_50k.txt',
        'tool/curated/duel_answers.txt',
        'tool/curated/guess_additions.txt',
        'supabase/seed/daily_words_seed.sql',
        'supabase/seed/challenge_words_seed.sql',
      ]) {
        final file = File('${temporary.path}/$path');
        file.parent.createSync(recursive: true);
        File(path).copySync(file.path);
      }
      Directory.current = temporary;
      final daily = pipeline.readWords('assets/words/answers.txt');
      final before = File('assets/words/dictionary.txt').readAsStringSync();
      for (final invalid in ['مدرسة', 'وردx', 'زززز', daily[1], 'ورده']) {
        File(
          'assets/words/answers.txt',
        ).writeAsStringSync([invalid, ...daily.skip(1)].join('\n'));
        expect(pipeline.generateWordlists, throwsStateError, reason: invalid);
        expect(File('assets/words/dictionary.txt').readAsStringSync(), before);
      }
      File('assets/words/answers.txt').writeAsStringSync(daily.join('\n'));
      final duels = pipeline.readWords('tool/curated/duel_answers.txt');
      File(
        'tool/curated/duel_answers.txt',
      ).writeAsStringSync([daily.first, ...duels.skip(1)].join('\n'));
      expect(pipeline.generateWordlists, throwsStateError);
      File(
        'assets/words/answers.txt',
      ).writeAsStringSync(daily.skip(1).join('\n'));
      expect(pipeline.generateWordlists, throwsStateError);
    } finally {
      Directory.current = root;
      temporary.deleteSync(recursive: true);
    }
  });
}
