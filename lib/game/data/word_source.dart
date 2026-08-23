/// Source of the word of the day.
library;

import '../engine/models.dart';

abstract interface class WordSource {
  /// The word for [today] (device-local date for offline sources; the
  /// server source uses its own calendar and may return a different date).
  Future<DailyWord> getTodayWord(DateTime today);
}
