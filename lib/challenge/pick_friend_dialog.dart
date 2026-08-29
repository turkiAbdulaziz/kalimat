/// «تحدَّ صديقًا» — pick who to duel. A plain list of friends in the house
/// dialog chrome; tapping one returns it to the caller.
library;

import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme/kalimat_colors.dart';
import '../core/theme/kalimat_theme.dart';
import '../core/theme/metrics.dart';
import '../core/utils/arabic_digits.dart';
import '../game/widgets/kalimat_avatar.dart';
import '../game/widgets/kalimat_dialog.dart';
import 'models.dart';

Future<Friend?> showPickFriendDialog(
  BuildContext context,
  List<Friend> friends,
) => showKalimatDialog<Friend>(
  context: context,
  builder: (context) => KalimatDialogCard(
    title: S.challengeFriend,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, f) in friends.indexed)
          _FriendChoice(
            friend: f,
            divider: i < friends.length - 1,
            onTap: () => Navigator.of(context).pop(f),
          ),
      ],
    ),
  ),
);

class _FriendChoice extends StatelessWidget {
  const _FriendChoice({
    required this.friend,
    required this.onTap,
    required this.divider,
  });

  final Friend friend;
  final VoidCallback onTap;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Metrics.s3),
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
                child: Text(
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
              ),
              Text(
                '${toArabicDigits('${friend.wins}')}-'
                '${toArabicDigits('${friend.losses}')}',
                style: TextStyle(
                  fontFamily: kFontUi,
                  fontSize: TypeScale.xs,
                  color: c.textSubtle,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
