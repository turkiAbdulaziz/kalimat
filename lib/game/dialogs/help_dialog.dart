/// «كيف تلعب» — rules, example row, start button.
library;

import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/motion_scope.dart';
import '../engine/models.dart';
import '../widgets/kalimat_button.dart';
import '../widgets/kalimat_dialog.dart';
import '../widgets/tile.dart';

/// [greetName] swaps the title for «أهلاً {name}» — used exactly once, on
/// the first-run opening (the only time the product addresses the player
/// by name).
Future<void> showHelpDialog(BuildContext context, {String? greetName}) =>
    showKalimatDialog(
      context: context,
      builder: (context) => _HelpDialog(greetName: greetName),
    );

class _HelpDialog extends StatelessWidget {
  const _HelpDialog({this.greetName});

  final String? greetName;

  static const _example = [
    ('ك', TileState.correct),
    ('ت', TileState.present),
    ('ا', TileState.absent),
    ('ب', TileState.absent),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    final bodyStyle = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(color: c.textMuted);

    return KalimatDialogCard(
      title: greetName == null ? S.help : '${S.helloPrefix}$greetName',
      footer: KalimatButton(
        label: S.helpStart,
        block: true,
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(S.helpBody, style: bodyStyle),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Metrics.s4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Flips in once when the dialog opens — the demo teaches
                // the reveal by performing it.
                for (final (i, e) in _example.indexed) ...[
                  if (i > 0) const SizedBox(width: Metrics.tileGap),
                  Tile(
                    letter: e.$1,
                    state: e.$2,
                    size: 44,
                    reveal: context.motionEnabled,
                    revealDelay: Motion.flipStagger * i,
                  ),
                ],
              ],
            ),
          ),
          for (final rule in const [
            S.helpRuleCorrect,
            S.helpRulePresent,
            S.helpRuleAbsent,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: bodyStyle),
                  Expanded(child: Text(rule, style: bodyStyle)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
