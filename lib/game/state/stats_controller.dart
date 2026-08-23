/// Player statistics, persisted locally (authoritative — Wordle convention).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_store.dart';
import 'settings_controller.dart';

final statsProvider =
    NotifierProvider<StatsController, GameStats>(StatsController.new);

class StatsController extends Notifier<GameStats> {
  @override
  GameStats build() => ref.read(localStoreProvider).stats;

  void recordGame({required bool won, required int guesses}) {
    final next = state.afterGame(won: won, guesses: guesses);
    state = next;
    ref.read(localStoreProvider).setStats(next);
  }
}
