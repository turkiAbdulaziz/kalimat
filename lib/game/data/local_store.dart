/// Local persistence: SharedPreferences JSON blobs.
///
/// Local stats are AUTHORITATIVE (Wordle convention) — the server only
/// receives raw results for the leaderboard and cross-device restore.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../engine/models.dart';
import '../engine/game_rules.dart';

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
        for (var i = 0; i < kMaxGuesses; i++)
          dist[i] + (won && guesses == i + 1 ? 1 : 0),
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
    this.haptics = true,
  });

  final bool dark;
  final bool hints;
  final bool motion;
  final bool haptics;

  GameSettings copyWith({
    bool? dark,
    bool? hints,
    bool? motion,
    bool? haptics,
  }) => GameSettings(
    dark: dark ?? this.dark,
    hints: hints ?? this.hints,
    motion: motion ?? this.motion,
    haptics: haptics ?? this.haptics,
  );

  Map<String, Object?> toJson() => {
    'dark': dark,
    'hints': hints,
    'motion': motion,
    'haptics': haptics,
  };

  static GameSettings fromJson(Map<String, Object?> j) => GameSettings(
    dark: j['dark'] as bool? ?? false,
    hints: j['hints'] as bool? ?? true,
    motion: j['motion'] as bool? ?? true,
    haptics: j['haptics'] as bool? ?? true,
  );
}

/// Daily reminder notification preference. Time is stored in 24h form.
class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.hour = 9,
    this.minute = 0,
  });

  final bool enabled;
  final int hour;
  final int minute;

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
  };

  static ReminderSettings fromJson(Map<String, Object?> j) => ReminderSettings(
    enabled: j['enabled'] as bool? ?? false,
    hour: j['hour'] as int? ?? 9,
    minute: j['minute'] as int? ?? 0,
  );
}

/// A game's board: typed guesses for one calendar date, plus the epoch ms
/// the solve clock started at (null on saves written before duels existed).
/// Row states are recomputed on load, so only typed spellings are stored.
class BoardSave {
  const BoardSave({
    required this.date,
    required this.guesses,
    this.startedAtMs,
  });

  final DateTime date;
  final List<String> guesses;
  final int? startedAtMs;

  Map<String, Object?> toJson() => {
    'date': date.toIso8601String().substring(0, 10),
    'guesses': guesses,
    'startedAtMs': startedAtMs,
  };

  static BoardSave fromJson(Map<String, Object?> j) => BoardSave(
    date: DateTime.parse(j['date'] as String),
    guesses: (j['guesses'] as List).cast<String>(),
    startedAtMs: j['startedAtMs'] as int?,
  );
}

/// One duel's board, keyed by challenge id. Duels have no calendar date, so
/// the saves are pruned by count instead ([LocalStore.kChallengeBoardLimit]).
class ChallengeBoardSave {
  const ChallengeBoardSave({required this.guesses, this.startedAtMs});

  final List<String> guesses;
  final int? startedAtMs;

  Map<String, Object?> toJson() => {
    'guesses': guesses,
    'startedAtMs': startedAtMs,
  };

  static ChallengeBoardSave fromJson(Map<String, Object?> j) =>
      ChallengeBoardSave(
        guesses: (j['guesses'] as List).cast<String>(),
        startedAtMs: j['startedAtMs'] as int?,
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
  final String grid; // e.g. "0120|2222" (0=absent,1=present,2=correct)
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

  static const _kGameplayVersion = 'gameplay_version';

  /// Run before resolving the startup word or creating any game providers.
  /// Write the marker last: interrupted/failed clearing retries next launch.
  Future<void> migrateGameplay() async {
    if ((_prefs.getInt(_kGameplayVersion) ?? 0) >= kGameplayVersion) return;
    for (final key in [
      _kWord,
      _kBoard,
      _kChallengeBoards,
      _kQueue,
      _kStats,
      _kHelpSeen,
    ]) {
      await _prefs.remove(key);
    }
    await _prefs.setInt(_kGameplayVersion, kGameplayVersion);
  }

  static const _kWord = 'cached_word';
  static const _kBoard = 'board';
  static const _kStats = 'stats';
  static const _kSettings = 'settings';
  static const _kQueue = 'pending_results';
  static const _kHelpSeen = 'help_seen';
  static const _kOnboarded = 'onboarded';
  static const _kDisplayName = 'display_name';
  static const _kReminder = 'reminder';
  static const _kChallengeBoards = 'challenge_boards';

  /// Duel boards kept on device; the oldest are dropped past this.
  static const int kChallengeBoardLimit = 10;

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
    } on TypeError {
      return null;
    }
  }

  Future<void> _setJson(String key, Object value) =>
      _prefs.setString(key, jsonEncode(value));

  T? _read<T>(String key, T? Function(Map<String, Object?>) decode) {
    try {
      final json = _json(key);
      return json == null ? null : decode(json);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  DailyWord? get cachedWord => _read(_kWord, (json) {
    final word = DailyWord.fromJson(json);
    return isPlayableWord(word.word) ? word : null;
  });

  Future<void> setCachedWord(DailyWord w) => _setJson(_kWord, w.toJson());

  BoardSave? get board => _read(_kBoard, (json) {
    final saved = BoardSave.fromJson(json);
    return isCompatibleBoard(saved.guesses) ? saved : null;
  });

  Future<void> setBoard(BoardSave b) => _setJson(_kBoard, b.toJson());

  Future<void> clearBoard() => _prefs.remove(_kBoard);

  GameStats get stats {
    final j = _json(_kStats);
    return j == null ? const GameStats() : GameStats.fromJson(j);
  }

  Future<void> setStats(GameStats s) => _setJson(_kStats, s.toJson());

  /// Account deletion only — sign-out keeps stats (they are authoritative).
  Future<void> clearStats() => _prefs.remove(_kStats);

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

  /// Whether the first-run sign-in flow has been completed (or skipped).
  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;

  Future<void> setOnboarded() => _prefs.setBool(_kOnboarded, true);

  Future<void> clearOnboarded() => _prefs.remove(_kOnboarded);

  /// Local cache of the display name, so the profile renders offline.
  String? get displayName => _prefs.getString(_kDisplayName);

  Future<void> setDisplayName(String name) =>
      _prefs.setString(_kDisplayName, name);

  Future<void> clearDisplayName() => _prefs.remove(_kDisplayName);

  ReminderSettings get reminder {
    final j = _json(_kReminder);
    return j == null ? const ReminderSettings() : ReminderSettings.fromJson(j);
  }

  Future<void> setReminder(ReminderSettings r) =>
      _setJson(_kReminder, r.toJson());

  /// Duel boards, newest last (insertion order is the prune order).
  Map<String, ChallengeBoardSave> get challengeBoards {
    final j = _json(_kChallengeBoards);
    if (j == null) return const {};
    final out = <String, ChallengeBoardSave>{};
    j.forEach((id, value) {
      if (value is Map) {
        try {
          final saved = ChallengeBoardSave.fromJson(
            Map<String, Object?>.from(value),
          );
          if (isCompatibleBoard(saved.guesses)) out[id] = saved;
        } on TypeError {
          // Ignore malformed saved duels.
        }
      }
    });
    return out;
  }

  ChallengeBoardSave? challengeBoard(String id) => challengeBoards[id];

  Future<void> setChallengeBoard(String id, ChallengeBoardSave board) {
    final all = {...challengeBoards}..remove(id);
    all[id] = board;
    final keys = all.keys.toList();
    for (final stale in keys.take(
      (keys.length - kChallengeBoardLimit).clamp(0, keys.length),
    )) {
      all.remove(stale);
    }
    return _setJson(_kChallengeBoards, {
      for (final e in all.entries) e.key: e.value.toJson(),
    });
  }

  Future<void> clearChallengeBoards() => _prefs.remove(_kChallengeBoards);

  List<PendingResult> get pendingResults {
    final raw = _prefs.getString(_kQueue);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, Object?>>()
          .map(PendingResult.fromJson)
          .where((result) => isCompatibleGrid(result.grid))
          .toList();
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  Future<void> clearPendingResults() => _prefs.remove(_kQueue);

  Future<void> setPendingResults(List<PendingResult> q) =>
      _setJson(_kQueue, [for (final r in q) r.toJson()]);
}
