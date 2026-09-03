/// A keyboard cap: 52px tall, 6px radius, inset bottom lip, press scale .94.
library;

import 'package:flutter/material.dart';

import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../engine/models.dart';

class KeyCap extends StatefulWidget {
  const KeyCap({
    super.key,
    required this.label,
    this.state,
    this.wide = false,
    this.disabled = false,
    this.onPress,
  });

  final String label;

  /// Best-known evaluation state, or null when idle.
  final TileState? state;

  /// Wide action key (إدخال / حذف): fixed width, smaller label.
  final bool wide;
  final bool disabled;
  final VoidCallback? onPress;

  @override
  State<KeyCap> createState() => _KeyCapState();
}

class _KeyCapState extends State<KeyCap> {
  bool _held = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kalimatColors;
    final state = widget.state;
    final isStated =
        state != null && state != TileState.empty && state != TileState.filled;

    final bg = isStated
        ? switch (state) {
            TileState.correct => colors.tileCorrect,
            TileState.present => colors.tilePresent,
            _ => colors.tileAbsent,
          }
        : (widget.wide ? colors.keyWideBg : colors.keyBg);
    final fg = isStated ? colors.tileTextOnState : colors.keyText;

    final cap = AnimatedScale(
      scale: _held && !widget.disabled ? .94 : 1,
      duration: Motion.instant,
      curve: Motion.easeOut,
      child: AnimatedOpacity(
        duration: Motion.fast,
        curve: Motion.easeOut,
        opacity: widget.disabled ? .5 : 1,
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.easeOut,
          height: Metrics.keyHeight,
          padding: widget.wide
              ? const EdgeInsets.symmetric(horizontal: 10)
              : EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(Metrics.rKey),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: kFontUi,
                  fontSize: widget.wide ? TypeScale.xs : TypeScale.lg,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  letterSpacing: 0,
                  height: 1,
                ),
              ),
              // Inset bottom lip (inset 0 -2px rgba(46,33,26,.06)).
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SizedBox(
                  height: 2,
                  child: ColoredBox(color: Color(0x0F2E211A)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.disabled ? null : (_) => setState(() => _held = true),
      onTapUp: widget.disabled ? null : (_) => setState(() => _held = false),
      onTapCancel: widget.disabled ? null : () => setState(() => _held = false),
      onTap: widget.disabled ? null : widget.onPress,
      child: cap,
    );
  }
}
