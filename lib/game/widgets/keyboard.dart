/// The on-screen Arabic keyboard: 3 alphabetical rows exactly per the
/// design, with wide إدخال / حذف keys flanking the third row.
library;

import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme/metrics.dart';
import '../engine/letters.dart';
import '../engine/models.dart';
import 'key_cap.dart';

class GameKeyboard extends StatelessWidget {
  const GameKeyboard({
    super.key,
    this.letterStates = const {},
    this.disabled = false,
    this.onKey,
    this.onEnter,
    this.onDelete,
  });

  /// Best-known state per canonical letter class; empty map = no hints.
  final Map<String, TileState> letterStates;
  final bool disabled;
  final ValueChanged<String>? onKey;
  final VoidCallback? onEnter;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < kKeyboardRows.length; i++) ...[
          if (i > 0) const SizedBox(height: Metrics.keyGap),
          Row(
            children: [
              if (i == 2) ...[
                _wide(S.enterKey, onEnter),
                const SizedBox(width: Metrics.keyGap),
              ],
              for (final (j, letter) in kKeyboardRows[i].indexed) ...[
                if (j > 0) const SizedBox(width: Metrics.keyGap),
                Expanded(
                  child: KeyCap(
                    label: letter,
                    state: letterStates[normalizeLetter(letter)],
                    disabled: disabled,
                    onPress: () => onKey?.call(letter),
                  ),
                ),
              ],
              if (i == 2) ...[
                const SizedBox(width: Metrics.keyGap),
                _wide(S.deleteKey, onDelete),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _wide(String label, VoidCallback? onPress) => SizedBox(
        width: 62,
        child: KeyCap(
          label: label,
          wide: true,
          disabled: disabled,
          onPress: onPress,
        ),
      );
}
