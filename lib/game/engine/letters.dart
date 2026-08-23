/// Arabic alphabet + normalization rules for كلمات.
///
/// The game uses lenient (normalized) matching: hamza-carrier forms, taa
/// marbuta, and alef maqsura are folded onto canonical letters for
/// evaluation, while the board always displays what the player typed and
/// stored answers keep their correct spelling.
library;

/// The on-screen keyboard: 3 alphabetical rows, exactly per the design.
/// Row 3 is flanked by the wide إدخال / حذف keys (added by the widget).
const List<List<String>> kKeyboardRows = [
  ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز'],
  ['س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ك'],
  ['ل', 'م', 'ن', 'ه', 'و', 'ي', 'ة', 'ى', 'ء', 'أ', 'إ'],
];

/// Letters that can appear in stored words but have no key of their own;
/// normalization maps them onto keyboard letters.
const Set<String> kTargetOnlyLetters = {'آ', 'ؤ', 'ئ'};

final Set<String> kKeyboardLetters = {for (final row in kKeyboardRows) ...row};

/// Folds a letter onto its canonical equivalence class.
///
/// أ إ آ → ا, ة → ه, ى → ي, ؤ → و, ئ → ي; the standalone hamza ء stays its
/// own letter (it has a dedicated key).
String normalizeLetter(String c) => switch (c) {
  'أ' || 'إ' || 'آ' => 'ا',
  'ة' => 'ه',
  'ى' => 'ي',
  'ؤ' => 'و',
  'ئ' => 'ي',
  _ => c,
};

/// Strips harakat, superscript alef, tatweel, and zero-width/bidi marks,
/// then folds every letter onto its canonical class.
String normalizeWord(String word) =>
    stripMarks(word).split('').map(normalizeLetter).join();

/// Removes diacritics and invisible characters, keeping base letters only.
String stripMarks(String word) {
  final buf = StringBuffer();
  for (final r in word.runes) {
    if (r >= 0x064B && r <= 0x0652) continue; // harakat
    if (r == 0x0670 || r == 0x0640) continue; // superscript alef, tatweel
    if (r >= 0x200B && r <= 0x200F) continue; // zero-width + bidi marks
    if (r == 0xFEFF) continue; // BOM
    buf.writeCharCode(r);
  }
  return buf.toString();
}
