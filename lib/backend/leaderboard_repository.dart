/// Leaderboard reads (daily + global RPCs).
library;

import 'package:flutter/foundation.dart';

import 'supabase_config.dart';
import 'supabase_service.dart';

class DailyEntry {
  const DailyEntry({
    required this.displayName,
    required this.won,
    this.guesses,
    this.durationMs,
  });

  final String displayName;
  final bool won;
  final int? guesses;
  final int? durationMs;
}

class GlobalEntry {
  const GlobalEntry({
    required this.displayName,
    required this.games,
    required this.wins,
    this.avgGuesses,
  });

  final String displayName;
  final int games;
  final int wins;
  final double? avgGuesses;
}

class LeaderboardRepository {
  Future<List<DailyEntry>?> fetchDaily({int limit = 50}) async {
    if (!isSupabaseConfigured) return null;
    try {
      final rows = await SupabaseService.client
          .rpc<List<dynamic>>(
            'get_daily_leaderboard',
            params: {'p_limit': limit},
          )
          .timeout(const Duration(seconds: 8));
      return [
        for (final r in rows.cast<Map<String, dynamic>>())
          DailyEntry(
            displayName: r['display_name'] as String? ?? 'لاعب',
            won: r['won'] as bool? ?? false,
            guesses: r['guesses'] as int?,
            durationMs: r['duration_ms'] as int?,
          ),
      ];
    } catch (e) {
      debugPrint('kalimat: daily leaderboard failed: $e');
      return null;
    }
  }

  Future<List<GlobalEntry>?> fetchGlobal({int limit = 50}) async {
    if (!isSupabaseConfigured) return null;
    try {
      final rows = await SupabaseService.client
          .rpc<List<dynamic>>(
            'get_global_leaderboard',
            params: {'p_limit': limit},
          )
          .timeout(const Duration(seconds: 8));
      return [
        for (final r in rows.cast<Map<String, dynamic>>())
          GlobalEntry(
            displayName: r['display_name'] as String? ?? 'لاعب',
            games: r['games'] as int? ?? 0,
            wins: r['wins'] as int? ?? 0,
            avgGuesses: (r['avg_guesses'] as num?)?.toDouble(),
          ),
      ];
    } catch (e) {
      debugPrint('kalimat: global leaderboard failed: $e');
      return null;
    }
  }
}
