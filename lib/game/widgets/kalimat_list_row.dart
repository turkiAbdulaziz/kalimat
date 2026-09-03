/// Tappable settings row (components/core/ListRow.jsx): leading icon,
/// label, optional trailing value, chevron when tappable, danger variant.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/motion_scope.dart';

class KalimatListRow extends StatefulWidget {
  const KalimatListRow({
    super.key,
    this.icon,
    required this.label,
    this.value,
    this.danger = false,
    this.divider = true,
    this.onTap,
  });

  final IconData? icon;
  final String label;
  final String? value;
  final bool danger;
  final bool divider;
  final VoidCallback? onTap;

  @override
  State<KalimatListRow> createState() => _KalimatListRowState();
}

class _KalimatListRowState extends State<KalimatListRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    final tappable = widget.onTap != null;

    final row = AnimatedContainer(
      duration: Motion.fast,
      curve: Motion.easeOut,
      padding: const EdgeInsets.symmetric(
        horizontal: Metrics.s2,
        vertical: Metrics.s3,
      ),
      decoration: BoxDecoration(
        color: _hover && tappable ? c.surfaceSunken : Colors.transparent,
        borderRadius: BorderRadius.circular(Metrics.rKey),
        border: widget.divider
            ? Border(bottom: BorderSide(color: c.lineSoft))
            : null,
      ),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 18, color: c.textSubtle),
            const SizedBox(width: Metrics.s3),
          ],
          Expanded(
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: kFontUi,
                fontSize: TypeScale.sm,
                color: widget.danger ? c.textDanger : c.textBody,
                letterSpacing: 0,
                height: 1.4,
              ),
            ),
          ),
          if (widget.value != null) ...[
            // A changed value (── → the loaded record, a new reminder time)
            // crossfades instead of snapping.
            AnimatedSwitcher(
              duration: context.motionDuration(Motion.fast),
              switchInCurve: Motion.easeOut,
              switchOutCurve: Motion.easeOut,
              child: Text(
                widget.value!,
                key: ValueKey(widget.value),
                style: TextStyle(
                  fontFamily: kFontUi,
                  fontSize: TypeScale.xs,
                  color: c.textSubtle,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: Metrics.s2),
          ],
          if (tappable)
            Icon(LucideIcons.chevronLeft, size: 16, color: c.textSubtle),
        ],
      ),
    );

    if (!tappable) return row;
    return Semantics(
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(onTap: widget.onTap, child: row),
      ),
    );
  }
}
