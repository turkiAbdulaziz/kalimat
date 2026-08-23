/// Startup/resume synchronization: refresh the word of the day (server
/// authority, bundled fallback on day rollover) and flush queued results.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/data/bundled_word_source.dart';
import '../game/engine/models.dart';
import '../game/engine/puzzle_calendar.dart';
import '../game/state/game_controller.dart';
import '../game/state/settings_controller.dart';
import 'remote_word_source.dart';
import 'results_repository.dart';
import 'supabase_config.dart';
import 'supabase_service.dart';

final resultsRepositoryProvider = Provider<ResultsRepository>(
  (ref) => ResultsRepository(ref.watch(localStoreProvider)),
);

final syncServiceProvider = Provider<SyncService>(SyncService.new);

class SyncService {
  SyncService(this._ref);

  final Ref _ref;
  final RemoteWordSource _remote = RemoteWordSource();
  final BundledWordSource _bundled = BundledWordSource();

  /// Called after the first frame and on every app resume.
  Future<void> sync() async {
    final store = _ref.read(localStoreProvider);
    final game = _ref.read(gameProvider);

    // The RPCs are granted to `authenticated`, so the anonymous session
    // must exist before any fetch.
    DailyWord? next;
    if (isSupabaseConfigured && await SupabaseService.ensureSession()) {
      next = await _remote.fetchToday();
    }

    // Offline day rollover: fall back to the bundled list for the new date.
    final today = dateOnly(DateTime.now());
    if (next == null && dateOnly(game.word.date) != today) {
      next = await _bundled.getTodayWord(today);
    }

    if (next != null) {
      await store.setCachedWord(next);
      _ref.read(gameProvider.notifier).applyServerWord(next);
    }

    await _ref.read(resultsRepositoryProvider).flushQueue();
  }
}
