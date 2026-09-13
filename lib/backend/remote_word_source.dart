/// Fetches the word of the day from Supabase (get_daily_word RPC).
/// The server's Asia/Riyadh calendar is authoritative; the returned date may
/// differ from the device's local date.
library;

import 'package:flutter/foundation.dart';

import '../game/engine/models.dart';
import '../game/engine/game_rules.dart';
import 'supabase_config.dart';
import 'supabase_service.dart';

class RemoteWordSource {
  /// Today's word per the server, or null when unreachable/unconfigured.
  Future<DailyWord?> fetchToday() async {
    if (!isSupabaseConfigured) return null;
    try {
      final rows = await SupabaseService.client
          .rpc<List<dynamic>>('get_daily_word')
          .timeout(const Duration(seconds: 8));
      if (rows.isEmpty) return null; // no word seeded for today
      final row = rows.first as Map<String, dynamic>;
      return parseDailyWordRow(row);
    } catch (e) {
      debugPrint('kalimat: get_daily_word failed: $e');
      return null;
    }
  }
}

/// Reject an old server deployment before its answer reaches a game or cache.
DailyWord? parseDailyWordRow(Map<String, dynamic> row) {
  final word = row['word'];
  if (word is! String || !isPlayableWord(word)) return null;
  return DailyWord(
    date: DateTime.parse(row['word_date'] as String),
    puzzleNo: row['puzzle_no'] as int,
    word: word,
    fromServer: true,
  );
}
