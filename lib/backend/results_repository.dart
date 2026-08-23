/// Uploads finished games (submit_result RPC) from the local pending queue.
/// The queue survives restarts; server-side unique(user_id, word_date) makes
/// retries idempotent.
library;

import 'package:flutter/foundation.dart';

import '../game/data/local_store.dart';
import 'supabase_config.dart';
import 'supabase_service.dart';

class ResultsRepository {
  ResultsRepository(this._store);

  final LocalStore _store;
  bool _flushing = false;

  /// Tries to upload every queued result; keeps what fails for next time.
  Future<void> flushQueue() async {
    if (!isSupabaseConfigured || _flushing) return;
    final queue = _store.pendingResults;
    if (queue.isEmpty) return;
    if (!await SupabaseService.ensureSession()) return;

    _flushing = true;
    try {
      final remaining = [...queue];
      for (final r in queue) {
        try {
          await SupabaseService.client.rpc<void>('submit_result', params: {
            'p_word_date': r.date.toIso8601String().substring(0, 10),
            'p_won': r.won,
            'p_guesses': r.guesses,
            'p_grid': r.grid,
            'p_duration_ms': r.durationMs,
          }).timeout(const Duration(seconds: 8));
          remaining.remove(r);
        } catch (e) {
          // 'date out of range' means it can never succeed — drop it.
          if ('$e'.contains('date out of range')) {
            remaining.remove(r);
          } else {
            debugPrint('kalimat: submit_result failed, keeping queued: $e');
            break; // likely offline; retry the rest later
          }
        }
      }
      await _store.setPendingResults(remaining);
    } finally {
      _flushing = false;
    }
  }
}
