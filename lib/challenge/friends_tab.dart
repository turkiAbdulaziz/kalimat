/// The friends tab: «رمزي» (your permanent code), incoming requests, and the
/// friend list with a duel button per row.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../backend/backend_providers.dart';
import '../core/motion/staggered_rise.dart';
import '../core/rise_route.dart';
import '../core/strings.dart';
import '../core/theme/kalimat_colors.dart';
import '../core/theme/kalimat_theme.dart';
import '../core/theme/metrics.dart';
import '../core/theme/motion.dart';
import '../core/theme/motion_scope.dart';
import '../core/utils/arabic_digits.dart';
import '../game/state/settings_controller.dart';
import '../game/widgets/code_field.dart';
import '../game/widgets/kalimat_avatar.dart';
import '../game/widgets/kalimat_button.dart';
import '../game/widgets/kalimat_spinner.dart';
import '../game/widgets/press_scale.dart';
import '../game/widgets/section_card.dart';
import 'add_friend_dialog.dart';
import 'challenge_screen.dart';
import 'models.dart';
import 'remove_friend_dialog.dart';

class FriendsTab extends ConsumerWidget {
  const FriendsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(myPlayerCardProvider).value;
    final requests = ref.watch(friendRequestsProvider).value ?? const [];
    final friends = ref.watch(friendsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          label: S.myCode,
          child: Column(
            children: [
              CodeDisplay(code: card?.friendCode ?? ''),
              const SizedBox(height: Metrics.s3),
              Text(
                S.myCodeHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: kFontUi,
                  fontSize: TypeScale.xs2,
                  color: context.kalimatColors.textSubtle,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: Metrics.s3),
              Row(
                children: [
                  Expanded(
                    child: KalimatButton(
                      label: S.copyCode,
                      variant: KalimatButtonVariant.secondary,
                      block: true,
                      disabled: card == null,
                      onPressed: card == null
                          ? null
                          : () => _copy(context, card.friendCode),
                    ),
                  ),
                  const SizedBox(width: Metrics.s2),
                  Expanded(
                    child: KalimatButton(
                      label: S.shareMyCode,
                      variant: KalimatButtonVariant.secondary,
                      block: true,
                      disabled: card == null,
                      onPressed: card == null
                          ? null
                          : () => SharePlus.instance.share(
                              ShareParams(
                                text:
                                    '${S.shareCodePrefix}'
                                    '${toArabicDigits(card.friendCode)}',
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (requests.isNotEmpty) ...[
          const SizedBox(height: Metrics.s6),
          SectionCard(
            label: '${S.requests} ${toArabicDigits('${requests.length}')}',
            padded: false,
            child: Column(
              children: [
                StaggeredRise(
                  enabled: context.motionEnabled,
                  children: [
                    for (final (i, r) in requests.indexed)
                      _RequestRow(
                        request: r,
                        divider: i < requests.length - 1,
                        onRespond: (accept) => _respond(ref, r.id, accept),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: Metrics.s6),
        SectionCard(
          label: S.friends,
          padded: false,
          trailing: _AddButton(
            onPressed: () async {
              final added = await showAddFriendDialog(context);
              if (added ?? false) _refresh(ref);
            },
          ),
          child: friends.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: Metrics.s4),
              child: KalimatSpinner(),
            ),
            error: (_, _) => const SectionNote(S.leaderboardError),
            data: (list) {
              if (list.isEmpty) return const SectionNote(S.noFriends);
              return StaggeredRise(
                enabled: context.motionEnabled,
                children: [
                  for (final (i, f) in list.indexed)
                    _FriendRow(
                      friend: f,
                      divider: i < list.length - 1,
                      onChallenge: () => _challenge(context, ref, f),
                      onRemove: () => _remove(ref, f.id),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  static void _copy(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(const SnackBar(content: Text(S.codeCopied)));
  }

  static void _refresh(WidgetRef ref) {
    ref.invalidate(friendsProvider);
    ref.invalidate(friendRequestsProvider);
    ref.invalidate(challengeBadgeProvider);
  }

  static Future<void> _respond(WidgetRef ref, String id, bool accept) async {
    await ref.read(friendsRepositoryProvider).respond(id, accept: accept);
    _refresh(ref);
  }

  static Future<void> _remove(WidgetRef ref, String id) async {
    await ref.read(friendsRepositoryProvider).remove(id);
    _refresh(ref);
  }

  static Future<void> _challenge(
    BuildContext context,
    WidgetRef ref,
    Friend friend,
  ) async {
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
    Navigator.of(context).push(
      riseRoute(
        motion: ref.read(settingsProvider).motion,
        builder: (_) => ChallengeScreen(challengeId: created.id),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Semantics(
      button: true,
      child: PressScale(
        onTap: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.userPlus, size: 14, color: c.accent),
            const SizedBox(width: 4),
            Text(
              S.addFriend,
              style: TextStyle(
                fontFamily: kFontUi,
                fontSize: TypeScale.xs2,
                fontWeight: FontWeight.w600,
                color: c.accent,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestRow extends StatefulWidget {
  const _RequestRow({
    required this.request,
    required this.onRespond,
    required this.divider,
  });

  final FriendRequest request;
  final ValueChanged<bool> onRespond;
  final bool divider;

  @override
  State<_RequestRow> createState() => _RequestRowState();
}

class _RequestRowState extends State<_RequestRow> {
  bool _leaving = false;

  FriendRequest get request => widget.request;
  bool get divider => widget.divider;

  /// The row fades out before the refresh removes it — the answer is
  /// visible, not a vanish.
  Future<void> _respond(bool accept) async {
    if (_leaving) return;
    setState(() => _leaving = true);
    await Future<void>.delayed(Motion.fast);
    if (mounted) widget.onRespond(accept);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return AnimatedOpacity(
      opacity: _leaving ? 0 : 1,
      duration: Motion.fast,
      curve: Motion.easeOut,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Metrics.s2,
          vertical: Metrics.s2,
        ),
        decoration: BoxDecoration(
          border: divider
              ? Border(bottom: BorderSide(color: c.lineSoft))
              : null,
        ),
        child: Row(
          children: [
            KalimatAvatar(name: request.displayName, size: 36),
            const SizedBox(width: Metrics.s3),
            Expanded(
              child: Text(
                request.displayName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kFontUi,
                  fontSize: TypeScale.sm,
                  fontWeight: FontWeight.w600,
                  color: c.textBody,
                  letterSpacing: 0,
                ),
              ),
            ),
            KalimatButton(label: S.accept, onPressed: () => _respond(true)),
            const SizedBox(width: Metrics.s1),
            KalimatButton(
              label: S.decline,
              variant: KalimatButtonVariant.ghost,
              onPressed: () => _respond(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendRow extends StatefulWidget {
  const _FriendRow({
    required this.friend,
    required this.onChallenge,
    required this.onRemove,
    required this.divider,
  });

  final Friend friend;
  final VoidCallback onChallenge;
  final VoidCallback onRemove;
  final bool divider;

  @override
  State<_FriendRow> createState() => _FriendRowState();
}

class _FriendRowState extends State<_FriendRow> {
  bool _leaving = false;

  Friend get friend => widget.friend;
  VoidCallback get onChallenge => widget.onChallenge;
  bool get divider => widget.divider;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return AnimatedOpacity(
      opacity: _leaving ? 0 : 1,
      duration: Motion.fast,
      curve: Motion.easeOut,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Metrics.s2,
          vertical: Metrics.s2,
        ),
        decoration: BoxDecoration(
          border: divider
              ? Border(bottom: BorderSide(color: c.lineSoft))
              : null,
        ),
        child: Row(
          children: [
            KalimatAvatar(name: friend.displayName, size: 36),
            const SizedBox(width: Metrics.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kFontUi,
                      fontSize: TypeScale.sm,
                      fontWeight: FontWeight.w600,
                      color: c.textBody,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    '${toArabicDigits('${friend.wins}')} ${S.winsLabel} · '
                    '${toArabicDigits('${friend.losses}')} ${S.lossesLabel}',
                    style: TextStyle(
                      fontFamily: kFontUi,
                      fontSize: TypeScale.xs2,
                      color: c.textSubtle,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            KalimatButton(label: S.challengeAction, onPressed: onChallenge),
            KalimatIconButton(
              icon: LucideIcons.userMinus,
              label: S.remove,
              onPressed: () => _confirmRemove(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final ok = await showRemoveFriendDialog(context, friend.displayName);
    if (!(ok ?? false) || !mounted) return;
    // Fade out before the refresh removes the row.
    setState(() => _leaving = true);
    await Future<void>.delayed(Motion.fast);
    if (mounted) widget.onRemove();
  }
}
