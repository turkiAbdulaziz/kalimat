/// The duels tab: «تحدَّ صديقًا» plus the match list, split into دورك /
/// بانتظار الخصم / انتهت.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/backend_providers.dart';
import '../core/rise_route.dart';
import '../core/strings.dart';
import '../core/theme/metrics.dart';
import '../game/state/settings_controller.dart';
import '../core/motion/staggered_rise.dart';
import '../core/theme/motion_scope.dart';
import '../game/widgets/kalimat_button.dart';
import '../game/widgets/kalimat_spinner.dart';
import '../game/widgets/section_card.dart';
import 'challenge_row.dart';
import 'challenge_screen.dart';
import 'models.dart';
import 'pick_friend_dialog.dart';

class ChallengesTab extends ConsumerWidget {
  const ChallengesTab({super.key, required this.onGoToFriends});

  /// «تحدَّ صديقًا» with an empty friend list sends the player to the other tab.
  final VoidCallback onGoToFriends;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myChallengesProvider);
    final myId = ref.watch(currentUserIdProvider);
    final list = async.value ?? const <ChallengeSummary>[];

    List<ChallengeSummary> of(ChallengeTurn turn) =>
        list.where((c) => c.turn == turn).toList();

    final yours = of(ChallengeTurn.yours);
    final waiting = of(ChallengeTurn.waiting);
    final done = of(ChallengeTurn.done);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KalimatButton(
          label: S.challengeFriend,
          large: true,
          block: true,
          onPressed: () => _startChallenge(context, ref),
        ),
        if (async.isLoading && list.isEmpty) ...[
          const SizedBox(height: Metrics.s6),
          const _Loading(),
        ],
        if (!async.isLoading && list.isEmpty) ...[
          const SizedBox(height: Metrics.s6),
          const SectionNote(S.noChallengesHint),
        ],
        _Group(
          label: S.yourTurn,
          items: yours,
          myId: myId,
          onOpen: (c) => _open(context, ref, c),
        ),
        _Group(
          label: S.waitingOpponent,
          items: waiting,
          myId: myId,
          onOpen: (c) => _open(context, ref, c),
        ),
        _Group(
          label: S.challengeDone,
          items: done,
          myId: myId,
          onOpen: (c) => _open(context, ref, c),
        ),
      ],
    );
  }

  Future<void> _startChallenge(BuildContext context, WidgetRef ref) async {
    final friends = await ref.read(friendsRepositoryProvider).fetchFriends();
    if (!context.mounted) return;
    if (friends.isEmpty) {
      onGoToFriends();
      return;
    }
    final friend = await showPickFriendDialog(context, friends);
    if (friend == null || !context.mounted) return;

    final created = await ref
        .read(challengeRepositoryProvider)
        .create(friend.id);
    if (!context.mounted) return;
    if (created == null) {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text(S.createChallengeFailed)));
      return;
    }
    ref.invalidate(myChallengesProvider);
    ref.invalidate(challengeBadgeProvider);
    _push(context, ref, created.id);
  }

  void _open(BuildContext context, WidgetRef ref, ChallengeSummary c) =>
      _push(context, ref, c.id);

  void _push(BuildContext context, WidgetRef ref, String id) {
    Navigator.of(context).push(
      riseRoute(
        motion: ref.read(settingsProvider).motion,
        builder: (_) => ChallengeScreen(challengeId: id),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.label,
    required this.items,
    required this.myId,
    required this.onOpen,
  });

  final String label;
  final List<ChallengeSummary> items;
  final String? myId;
  final ValueChanged<ChallengeSummary> onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Metrics.s6),
      child: SectionCard(
        label: label,
        padded: false,
        child: StaggeredRise(
          enabled: context.motionEnabled,
          children: [
            for (final (i, c) in items.indexed)
              ChallengeRow(
                challenge: c,
                outcome: c.outcome(myId ?? ''),
                divider: i < items.length - 1,
                // A finished duel still opens — the result card is the recap.
                onTap: () => onOpen(c),
              ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const KalimatSpinner();
}
