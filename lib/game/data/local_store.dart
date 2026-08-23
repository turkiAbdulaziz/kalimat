/// Local persistence: SharedPreferences JSON blobs.
///
/// Local stats are AUTHORITATIVE (Wordle convention) — the server only
/// receives raw results for the leaderboard and cross-device restore.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../engine/models.dart';

/// Player statistics. dist[i] = wins in (i+1) guesses.
class GameStats {
  const GameStats({
    this.played = 0,
    this.wins = 0,
    this.streak = 0,
    this.best = 0,
    this.dist = const [0, 0, 0, 0, 0, 0],
  });

  final int played;
  final int wins;
  final int streak;
  final int best;
  final List<int> dist;

  int get winRatePercent => played == 0 ? 0 : (wins * 100 / played).round();

  GameStats afterGame({required bool won, required int guesses}) {
    final newStreak = won ? streak + 1 : 0;
    return GameStats(
      played: played + 1,
      wins: wins + (won ? 1 : 0),
      streak: newStreak,
      best: newStreak > best ? newStreak : best,
      dist: [
        for (var i = 0; i < 6; i++) dist[i] + (won && guesses == i + 1 ? 1 : 0),
      ],
    );
  }

  Map<String, Object?> toJson() => {
    'played': played,
    'wins': wins,
    'streak': streak,
    'best': best,
    'dist': dist,
  };

  static GameStats fromJson(Map<String, Object?> j) => GameStats(
    played: j['played'] as int? ?? 0,
    wins: j['wins'] as int? ?? 0,
    streak: j['streak'] as int? ?? 0,
    best: j['best'] as int? ?? 0,
    dist: (j['dist'] as List?)?.cast<int>() ?? const [0, 0, 0, 0, 0, 0],
  );
}

class GameSettings {
  const GameSettings({
    this.dark = false,
    this.hints = true,
    this.motion = true,
  });

  final bool dark;
  final bool hints;
  final bool motion;

  GameSettings copyWith({bool? dark, bool? hints, bool? motion}) =>
      GameSettings(
        dark: dark ?? this.dark,
        hints: hints ?? this.hints,
        motion: motion ?? this.motion,
      );

  Map<String, Object?> toJson() => {
    'dark': dark,
    'hints': hints,
    'motion': motion,
  };

  static GameSettings fromJson(Map<String, Object?> j) => GameSettings(
    dark: j['dark'] as bool? ?? false,
    hints: j['hints'] as bool? ?? true,
    motion: j['motion'] as bool? ?? true,
  );
}

/// A finished game's board: typed guesses for one calendar date.
/// Row states are recomputed on load, so only typed spellings are stored.
class BoardSave {
  const BoardSave({required this.date, required this.guesses});

  final DateTime date;
  final List<String> guesses;

  Map<String, Object?> toJson() => {
    'date': date.toIso8601String().substring(0, 10),
    'guesses': guesses,
  };

  static BoardSave fromJson(Map<String, Object?> j) => BoardSave(
    date: DateTime.parse(j['date'] as String),
    guesses: (j['guesses'] as List).cast<String>(),
  );
}

/// A finished result queued for upload to Supabase.
class PendingResult {
  const PendingResult({
    required this.date,
    required this.won,
    required this.guesses,
    required this.grid,
    this.durationMs,
  });

  final DateTime date;
  final bool won;
  final int? guesses; // null on loss
  final String grid; // e.g. "01201|22222" (0=absent,1=present,2=correct)
  final int? durationMs;

  Map<String, Object?> toJson() => {
    'date': date.toIso8601String().substring(0, 10),
    'won': won,
    'guesses': guesses,
    'grid': grid,
    'durationMs': durationMs,
  };

  static PendingResult fromJson(Map<String, Object?> j) => PendingResult(
    date: DateTime.parse(j['date'] as String),
    won: j['won'] as bool,
    guesses: j['guesses'] as int?,
    grid: j['grid'] as String,
    durationMs: j['durationMs'] as int?,
  );
}

class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static const _kWord = 'cached_word';
  static const _kBoard = 'board';
  static const _kStats = 'stats';
  static const _kSettings = 'settings';
  static const _kQueue = 'pending_results';
  static const _kHelpSeen = 'help_seen';

  static Future<LocalStore> create() async => LocalStore(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    ),
  );

  Map<String, Object?>? _json(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, Object?>;
    } on FormatException {
      return null;
    }
  }

  Future<void> _setJson(String key, Object value) =>
      _prefs.setString(key, jsonEncode(value));

  DailyWord? get cachedWord {
    final j = _json(_kWord);
    return j == null ? null : DailyWord.fromJson(j);
  }

  Future<void> setCachedWord(DailyWord w) => _setJson(_kWord, w.toJson());

  BoardSave? get board {
    final j = _json(_kBoard);
    return j == null ? null : BoardSave.fromJson(j);
  }

  Future<void> setBoard(BoardSave b) => _setJson(_kBoard, b.toJson());

  GameStats get stats {
    final j = _json(_kStats);
    return j == null ? const GameStats() : GameStats.fromJson(j);
  }

  Future<void> setStats(GameStats s) => _setJson(_kStats, s.toJson());

  /// Whether the user has ever explicitly saved settings (used to decide
  /// accessibility-driven defaults).
  bool get hasStoredSettings => _prefs.getString(_kSettings) != null;

  GameSettings get settings {
    final j = _json(_kSettings);
    return j == null ? const GameSettings() : GameSettings.fromJson(j);
  }

  Future<void> setSettings(GameSettings s) => _setJson(_kSettings, s.toJson());

  bool get helpSeen => _prefs.getBool(_kHelpSeen) ?? false;

  Future<void> setHelpSeen() => _prefs.setBool(_kHelpSeen, true);

  List<PendingResult> get pendingResults {
    final raw = _prefs.getString(_kQueue);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, Object?>>()
          .map(PendingResult.fromJson)
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> setPendingResults(List<PendingResult> q) =>
      _setJson(_kQueue, [for (final r in q) r.toJson()]);
}
