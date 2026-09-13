/// Resolve only after the one-time gameplay reset has completed.
library;

import '../engine/models.dart';
import '../engine/puzzle_calendar.dart';
import 'bundled_word_source.dart';
import 'local_store.dart';

Future<DailyWord> resolveStartupWord(LocalStore store, DateTime now) async {
  await store.migrateGameplay();
  final today = dateOnly(now);
  final cached = store.cachedWord;
  if (cached != null && dateOnly(cached.date) == today) return cached;
  final word = await BundledWordSource().getTodayWord(today);
  await store.setCachedWord(word);
  return word;
}
