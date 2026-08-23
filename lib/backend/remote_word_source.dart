/// Fetches the word of the day from Supabase (get_daily_word RPC).
/// The server's Asia/Riyadh calendar is authoritative; the returned date may
/// differ from the device's local date.
library;

import 'package:flutter/foundation.dart';

import '../game/engine/models.dart';
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
      return DailyWord(
        date: DateTime.parse(row['word_date'] as String),
        puzzleNo: row['puzzle_no'] as int,
        word: row['word'] as String,
        fromServer: true,
      );
    } catch (e) {
      debugPrint('kalimat: get_daily_word failed: $e');
      return null;
    }
  }
}
