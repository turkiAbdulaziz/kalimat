/// Duel RPCs + the Realtime channel that carries the opponent's progress.
/// Guarded by [isSupabaseConfigured] like the rest of backend/, so an
/// unconfigured build (and the test suite) never touches the network.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../challenge/models.dart';
import 'supabase_config.dart';
import 'supabase_service.dart';

const Duration _kTimeout = Duration(seconds: 8);

class ChallengeRepository {
  /// The «التحدّيات» list. Empty on failure — the screen shows its empty state.
  Future<List<ChallengeSummary>> fetchMine() async {
    final rows = await _rpc('get_my_challenges', {'p_limit': 30});
    return rows == null
        ? const []
        : rows.map(ChallengeSummary.fromRow).toList();
  }

  /// Opens a duel: this is the only call that hands the word to the client,
  /// and only to a participant.
  Future<ChallengeDetail?> open(String id) async {
    final rows = await _rpc('get_challenge', {'p_id': id});
    if (rows == null || rows.isEmpty) return null;
    return ChallengeDetail.fromRow(rows.first);
  }

  /// Creates a duel against a friend and returns it ready to play.
  Future<ChallengeDetail?> create(String opponentId) async {
    final rows = await _rpc('create_challenge', {'p_opponent_id': opponentId});
    if (rows == null || rows.isEmpty) return null;
    final row = rows.first;
    return ChallengeDetail(
      // create_challenge prefixes its OUT columns (see 0005).
      id: row['challenge_id'] as String,
      word: row['challenge_word'] as String,
      opponentId: opponentId,
      opponentName: (row['opponent_name'] as String?) ?? '',
      status: ChallengeStatus.active,
      mine: const ChallengeSide(),
      theirs: const ChallengeSide(),
    );
  }

  /// Fired per guess — this is what the opponent's board sees live.
  Future<void> pushProgress(String id, int guesses) async {
    await _rpc('update_challenge_progress', {'p_id': id, 'p_guesses': guesses});
  }

  /// Write-once; the server decides the winner when the second result lands.
  Future<bool> submitResult({
    required String id,
    required bool won,
    required int guesses,
    required int? durationMs,
    required String grid,
  }) async {
    final ok = await _rpc('submit_challenge_result', {
      'p_id': id,
      'p_won': won,
      'p_guesses': guesses,
      'p_duration_ms': durationMs,
      'p_grid': grid,
    });
    return ok != null;
  }

  /// The opponent's row on `challenge_participants`, pushed on every change.
  /// Yields nothing when unconfigured, so callers can subscribe blindly.
  Stream<ChallengeSide> watchOpponent(String challengeId, String opponentId) {
    if (!isSupabaseConfigured) return const Stream<ChallengeSide>.empty();

    final controller = StreamController<ChallengeSide>();
    RealtimeChannel? channel;

    controller.onListen = () {
      channel = SupabaseService.client
          .channel('challenge:$challengeId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'challenge_participants',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'challenge_id',
              value: challengeId,
            ),
            callback: (payload) {
              final row = payload.newRecord;
              if (row['user_id'] != opponentId) return; // my own echo
              controller.add(
                ChallengeSide(
                  guesses: (row['guesses_used'] as int?) ?? 0,
                  finished: (row['finished'] as bool?) ?? false,
                  won: (row['won'] as bool?) ?? false,
                  durationMs: row['duration_ms'] as int?,
                  grid: row['grid'] as String?,
                ),
              );
            },
          )
          .subscribe();
    };
    controller.onCancel = () async {
      final c = channel;
      channel = null;
      if (c != null) await SupabaseService.client.removeChannel(c);
    };
    return controller.stream;
  }

  Future<List<Map<String, dynamic>>?> _rpc(
    String name, [
    Map<String, Object?>? params,
  ]) async {
    if (!isSupabaseConfigured) return null;
    if (!await SupabaseService.ensureSession()) return null;
    try {
      final result = await SupabaseService.client
          .rpc<dynamic>(name, params: params)
          .timeout(_kTimeout);
      if (result is List) {
        return result.cast<Map<String, dynamic>>();
      }
      return const [];
    } catch (e) {
      debugPrint('kalimat: $name failed: $e');
      return null;
    }
  }
}
