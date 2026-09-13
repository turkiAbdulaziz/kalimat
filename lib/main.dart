import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'backend/supabase_service.dart';
import 'game/data/startup_word.dart';
import 'game/data/dictionary.dart';
import 'game/data/local_store.dart';
import 'game/state/game_controller.dart';
import 'game/state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.init(); // no-op until the project is configured
  final store = await LocalStore.create();
  final dictionary = GuessDictionary();
  await dictionary.ensureLoaded();
  final word = await resolveStartupWord(store, DateTime.now());

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
