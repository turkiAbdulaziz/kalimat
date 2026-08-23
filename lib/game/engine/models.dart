/// Core game model types. Pure Dart — no Flutter imports.
library;

/// Visual/evaluation state of a tile. Evaluation only ever produces
/// [correct], [present], or [absent]; [empty] and [filled] are board states.
enum TileState { empty, filled, correct, present, absent }

enum GameStatus { playing, won, lost }

/// The word being played: its calendar date, ordinal puzzle number, and
/// display spelling (correct hamzas — revealed on loss).
class DailyWord {
  const DailyWord({
    required this.date,
    required this.puzzleNo,
    required this.word,
    required this.fromServer,
  });

  /// Calendar date (date-only, no time component).
  final DateTime date;
  final int puzzleNo;

  /// Display spelling; normalize before evaluating against it.
  final String word;

  /// True when fetched from Supabase, false for the bundled fallback list.
  final bool fromServer;

  Map<String, Object?> toJson() => {
        'date': date.toIso8601String().substring(0, 10),
        'puzzleNo': puzzleNo,
        'word': word,
        'fromServer': fromServer,
      };

  static DailyWord fromJson(Map<String, Object?> json) => DailyWord(
        date: DateTime.parse(json['date'] as String),
        puzzleNo: json['puzzleNo'] as int,
        word: json['word'] as String,
        fromServer: json['fromServer'] as bool? ?? false,
      );
}
