import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'backend/supabase_service.dart';
import 'game/data/bundled_word_source.dart';
import 'game/data/dictionary.dart';
import 'game/data/local_store.dart';
import 'game/engine/models.dart';
import 'game/engine/puzzle_calendar.dart';
import 'game/state/game_controller.dart';
import 'game/state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.init(); // no-op until the project is configured
  final store = await LocalStore.create();
  final dictionary = GuessDictionary();
  await dictionary.ensureLoaded();
  final word = await _resolveTodayWord(store);

  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        dictionaryProvider.overrideWithValue(dictionary),
        initialWordProvider.overrideWithValue(word),
      ],
      child: const KalimatApp(),
    ),
  );
}

/// Cached word for today if present, else the bundled fallback.
/// M3 adds a background Supabase fetch that supersedes this when it lands.
Future<DailyWord> _resolveTodayWord(LocalStore store) async {
  final today = dateOnly(DateTime.now());
  final cached = store.cachedWord;
  if (cached != null && dateOnly(cached.date) == today) return cached;
  final word = await BundledWordSource().getTodayWord(today);
  await store.setCachedWord(word);
  return word;
}
