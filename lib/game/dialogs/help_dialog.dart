/// «كيف تلعب» — rules, example row, start button.
library;

import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/metrics.dart';
import '../engine/models.dart';
import '../widgets/kalimat_button.dart';
import '../widgets/kalimat_dialog.dart';
import '../widgets/tile.dart';

Future<void> showHelpDialog(BuildContext context) => showKalimatDialog(
  context: context,
  builder: (context) => const _HelpDialog(),
);

class _HelpDialog extends StatelessWidget {
  const _HelpDialog();

  static const _example = [
    ('م', TileState.correct),
    ('ك', TileState.absent),
    ('ت', TileState.present),
    ('ب', TileState.absent),
    ('ة', TileState.absent),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    final bodyStyle = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(color: c.textMuted);

    return KalimatDialogCard(
      title: S.help,
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
                for (final (i, e) in _example.indexed) ...[
                  if (i > 0) const SizedBox(width: Metrics.tileGap),
                  Tile(letter: e.$1, state: e.$2, size: 44),
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
