/// Arabic-Indic digit rendering. The design mandates ٠١٢٣٤٥٦٧٨٩ everywhere
/// in product UI (no intl dependency — a 10-character map suffices).
library;

const List<String> _digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Arabic percent sign (٪, U+066A).
const String arabicPercent = '٪';

/// Replaces every Western digit in [value] with its Arabic-Indic equivalent.
String toArabicDigits(String value) =>
    value.replaceAllMapped(RegExp('[0-9]'), (m) => _digits[int.parse(m[0]!)]);

/// Formats [value] as an Arabic-Indic percentage, e.g. 64 → «٦٤٪».
String toArabicPercent(int value) =>
    '${toArabicDigits('$value')}$arabicPercent';
