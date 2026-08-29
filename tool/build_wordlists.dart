// Word-list preprocessing pipeline for كلمات (Kalimat).
//
// Reads raw sources under tool/raw/ (git-ignored, see download URLs below),
// and emits:
//   assets/words/dictionary.txt        - normalized accepted-guess set, sorted
//   tool/out/answers_candidates.txt    - frequency-ranked candidates for human curation
//   assets/words/answers.txt           - provisional answers (only if file is missing;
//                                        replace with the curated list before release)
//   supabase/seed/daily_words_seed.sql - server seed matching answers.txt ordering
//   supabase/seed/challenge_words_seed.sql - duel word pool, disjoint from answers.txt
//
// Raw sources (all MIT):
//   tool/raw/hugo0_ar_5words.txt      https://github.com/Hugo0/wordle (webapp/data/languages/ar/ar_5words.txt)
//   tool/raw/freq_ar_50k.txt          https://github.com/hermitdave/FrequencyWords (content/2018/ar/ar_50k.txt)
//   tool/raw/mustafa_arabic_words.txt https://github.com/MustafaLinux/arabic-words-list (arabic-words.txt)
//
// Run from the project root:  dart run tool/build_wordlists.dart

import 'dart:io';

/// Launch epoch: this date is puzzle ١. Must match lib/game/engine/puzzle_calendar.dart.
const String kEpochDate = '2026-09-01';

/// How many words the duel pool holds (supabase/seed/challenge_words_seed.sql).
const int kChallengePoolSize = 2000;

/// The 33 on-screen keyboard letters (design keyboard) …
const Set<String> kKeyboardLetters = {
  'ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', //
  'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ك', //
  'ل', 'م', 'ن', 'ه', 'و', 'ي', 'ة', 'ى', 'ء', 'أ', 'إ',
};

/// … plus letters that may appear in stored words but have no key
/// (normalization maps them onto keyboard letters).
const Set<String> kTargetOnlyLetters = {'آ', 'ؤ', 'ئ'};

final Set<String> kAllowedLetters = {
  ...kKeyboardLetters,
  ...kTargetOnlyLetters,
};

/// Must mirror normalizeLetter in lib/game/engine/letters.dart exactly.
String normalizeLetter(String c) => switch (c) {
  'أ' || 'إ' || 'آ' => 'ا',
  'ة' => 'ه',
  'ى' => 'ي',
  'ؤ' => 'و',
  'ئ' => 'ي',
  _ => c,
};

String normalizeWord(String w) => w.split('').map(normalizeLetter).join();

/// Strip harakat (U+064B..U+0652), superscript alef (U+0670), tatweel (U+0640),
/// and zero-width/bidi control characters.
String stripMarks(String w) {
  final buf = StringBuffer();
  for (final r in w.runes) {
    if (r >= 0x064B && r <= 0x0652) continue; // harakat
    if (r == 0x0670 || r == 0x0640) continue; // superscript alef, tatweel
    if (r >= 0x200B && r <= 0x200F) continue; // zero-width + bidi marks
    if (r == 0xFEFF) continue; // BOM
    buf.writeCharCode(r);
  }
  return buf.toString();
}

/// Returns the cleaned 5-letter word, or null if the entry doesn't qualify.
String? clean(String raw) {
  final w = stripMarks(raw.trim());
  final letters = w.split('');
  if (letters.length != 5) return null;
  if (!letters.every(kAllowedLetters.contains)) return null;
  return w;
}

void main() {
  final rawDir = Directory('tool/raw');
  if (!rawDir.existsSync()) {
    stderr.writeln(
      'tool/raw/ missing - download the raw sources first (see header).',
    );
    exit(1);
  }

  // --- Load frequency list: rank + count per surface form -------------------
  final freqCount = <String, int>{}; // raw surface form -> count
  final freqRankNorm = <String, int>{}; // normalized form -> best rank
  final freqDisplay =
      <String, String>{}; // normalized form -> highest-count spelling
  var rank = 0;
  for (final line in File('tool/raw/freq_ar_50k.txt').readAsLinesSync()) {
    final parts = line.trim().split(' ');
    if (parts.length != 2) continue;
    final count = int.tryParse(parts[1]);
    if (count == null) continue;
    rank++;
    final raw = stripMarks(parts[0]);
    freqCount[raw] = count;
    final w = clean(parts[0]);
    if (w == null) continue;
    final n = normalizeWord(w);
    freqRankNorm.putIfAbsent(n, () => rank);
    // Keep the most frequent original spelling as the display form.
    final prev = freqDisplay[n];
    if (prev == null || (freqCount[prev] ?? 0) < count) freqDisplay[n] = w;
  }

  // --- Build the accepted-guess dictionary (normalized forms) ---------------
  final dictionary = <String>{};
  final sourceCounts = <String, int>{};
  void addSource(String path, String label) {
    var added = 0;
    for (final line in File(path).readAsLinesSync()) {
      final w = clean(line);
      if (w == null) continue;
      if (dictionary.add(normalizeWord(w))) added++;
    }
    sourceCounts[label] = added;
  }

  addSource('tool/raw/hugo0_ar_5words.txt', 'hugo0');
  // freq words need separate handling since lines carry counts:
  var freqAdded = 0;
  for (final n in freqRankNorm.keys) {
    if (dictionary.add(n)) freqAdded++;
  }
  sourceCounts['freq50k'] = freqAdded;
  // NOT used: MustafaLinux/arabic-words-list. Verified to be a morphologically
  // GENERATED list (457k five-letter "words" incl. junk clitic mashups like
  // بابحث/تدربأ) - it would make nearly any guess count as a valid word.

  final sortedDict = dictionary.toList()..sort();
  Directory('assets/words').createSync(recursive: true);
  File(
    'assets/words/dictionary.txt',
  ).writeAsStringSync('${sortedDict.join('\n')}\n');

  // --- Answers candidates (frequency-ranked, flagged for curation) ----------
  // Flags: AL = starts with ال (definite article); W/F/B/L = clitic prefix with a
  // known frequent remainder; SUF = pronoun-suffix suspect with a known stem.
  bool known(String s) => freqCount.containsKey(s);
  String flagsFor(String w) {
    final f = <String>[];
    if (w.startsWith('ال')) f.add('AL');
    for (final p in ['و', 'ف', 'ب', 'ل']) {
      if (w.startsWith(p) && known(w.substring(1))) {
        f.add({'و': 'W', 'ف': 'F', 'ب': 'B', 'ل': 'L'}[p]!);
      }
    }
    for (final s in ['ها', 'هم', 'كم', 'نا', 'ني', 'ته', 'تم']) {
      if (w.endsWith(s) && known(w.substring(0, w.length - 2))) f.add('SUF');
    }
    return f.isEmpty ? '-' : f.toSet().join(',');
  }

  final rankedNorms = freqRankNorm.keys.toList()
    ..sort((a, b) => freqRankNorm[a]!.compareTo(freqRankNorm[b]!));

  Directory('tool/out').createSync(recursive: true);
  final candidates = StringBuffer()
    ..writeln(
      '# word<TAB>freq_rank<TAB>flags   (flags: AL=ال prefix, W/F/B/L=clitic prefix, SUF=pronoun suffix)',
    )
    ..writeln(
      '# Curate into assets/words/answers.txt: one display-spelling word per line, order = puzzle order.',
    );
  final unflagged = <String>[];
  for (final n in rankedNorms) {
    final display = freqDisplay[n]!;
    final flags = flagsFor(display);
    candidates.writeln('$display\t${freqRankNorm[n]}\t$flags');
    if (flags == '-') unflagged.add(display);
  }
  File(
    'tool/out/answers_candidates.txt',
  ).writeAsStringSync(candidates.toString());

  // --- Provisional answers (only when no curated file exists) ---------------
  final answersFile = File('assets/words/answers.txt');
  if (!answersFile.existsSync()) {
    final provisional = unflagged.take(500).toList();
    answersFile.writeAsStringSync(
      '# PROVISIONAL - auto-generated top-frequency words; replace with curated list.\n'
      '${provisional.join('\n')}\n',
    );
    stdout.writeln(
      'Wrote PROVISIONAL assets/words/answers.txt (${provisional.length} words).',
    );
  }

  // --- Validate answers + emit Supabase seed --------------------------------
  final answers = answersFile
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toList();
  final seenNorm = <String>{};
  for (final (i, a) in answers.indexed) {
    final w = clean(a);
    if (w == null) {
      throw StateError(
        'answers.txt line ${i + 1}: "$a" is not a valid 5-letter word',
      );
    }
    final n = normalizeWord(w);
    if (!dictionary.contains(n)) {
      throw StateError('answers.txt line ${i + 1}: "$a" not in dictionary');
    }
    if (!seenNorm.add(n)) {
      throw StateError(
        'answers.txt line ${i + 1}: "$a" duplicates an earlier answer',
      );
    }
  }

  final epoch = DateTime.parse(kEpochDate);
  final seed = StringBuffer()
    ..writeln(
      '-- Generated by tool/build_wordlists.dart - do not edit by hand.',
    )
    ..writeln(
      '-- Epoch $kEpochDate = puzzle 1. Regenerate after curating answers.txt.',
    )
    ..writeln(
      'insert into public.daily_words (word_date, puzzle_no, word) values',
    );
  for (final (i, a) in answers.indexed) {
    final d = epoch.add(Duration(days: i));
    final date = d.toIso8601String().substring(0, 10);
    seed.write("('$date', ${i + 1}, '$a')");
    seed.writeln(i == answers.length - 1 ? '' : ',');
  }
  seed.writeln(
    'on conflict (word_date) do update set word = excluded.word, puzzle_no = excluded.puzzle_no;',
  );
  Directory('supabase/seed').createSync(recursive: true);
  File('supabase/seed/daily_words_seed.sql').writeAsStringSync(seed.toString());

  // --- Duel word pool -------------------------------------------------------
  // Duels must never spoil a future «كلمة اليوم», so the pool starts where the
  // curated answers stop: the next unflagged frequency ranks, minus every word
  // already used as a daily answer. Same provisional status as answers.txt —
  // it wants the same curation pass before release.
  final answerNorms = {for (final a in answers) normalizeWord(clean(a)!)};
  final pool = <String>[];
  for (final display in unflagged) {
    if (pool.length >= kChallengePoolSize) break;
    if (answerNorms.contains(normalizeWord(display))) continue;
    pool.add(display);
  }
  final challengeSeed = StringBuffer()
    ..writeln(
      '-- Generated by tool/build_wordlists.dart - do not edit by hand.',
    )
    ..writeln(
      '-- Duel word pool: disjoint from answers.txt (a duel must not spoil a',
    )
    ..writeln('-- future daily word). Regenerate whenever answers.txt changes.')
    ..writeln('insert into public.challenge_words (word) values');
  for (final (i, w) in pool.indexed) {
    challengeSeed.write("('$w')");
    challengeSeed.writeln(i == pool.length - 1 ? '' : ',');
  }
  challengeSeed.writeln('on conflict (word) do nothing;');
  File(
    'supabase/seed/challenge_words_seed.sql',
  ).writeAsStringSync(challengeSeed.toString());

  stdout
    ..writeln(
      'dictionary.txt: ${sortedDict.length} normalized words '
      '(new per source: ${sourceCounts.entries.map((e) => '${e.key}=${e.value}').join(', ')})',
    )
    ..writeln(
      'answers_candidates.txt: ${rankedNorms.length} ranked (${unflagged.length} unflagged)',
    )
    ..writeln(
      'answers.txt: ${answers.length} answers validated; seed SQL written.',
    )
    ..writeln(
      'challenge_words_seed.sql: ${pool.length} duel words (disjoint from answers).',
    );
}
