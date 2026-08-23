/// Pill buttons + circular icon button, per the design's core components.
library;

import 'package:flutter/material.dart';

import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/motion.dart';

enum KalimatButtonVariant { primary, secondary, ghost }

class KalimatButton extends StatefulWidget {
  const KalimatButton({
    super.key,
    required this.label,
    this.variant = KalimatButtonVariant.primary,
    this.block = false,
    this.disabled = false,
    this.onPressed,
  });

  final String label;
  final KalimatButtonVariant variant;
  final bool block;
  final bool disabled;
  final VoidCallback? onPressed;

  @override
  State<KalimatButton> createState() => _KalimatButtonState();
}

class _KalimatButtonState extends State<KalimatButton> {
  bool _held = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;

    final (Color bg, Color fg, Color border) = switch (widget.variant) {
      KalimatButtonVariant.primary => (c.accent, c.textOnAccent, c.accent),
      KalimatButtonVariant.secondary => (
        _hover ? c.surfaceSunken : c.surfaceCard,
        c.textBody,
        c.line,
      ),
      KalimatButtonVariant.ghost => (
        _hover ? c.surfaceSunken : Colors.transparent,
        c.textMuted,
        Colors.transparent,
      ),
    };
    // Primary hover darkens (filter brightness .93 equivalent).
    final effBg = widget.variant == KalimatButtonVariant.primary && _hover
        ? Color.lerp(bg, Colors.black, .07)!
        : bg;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) => setState(() => _held = true),
        onTapUp: widget.disabled ? null : (_) => setState(() => _held = false),
        onTapCancel: widget.disabled
            ? null
            : () => setState(() => _held = false),
        onTap: widget.disabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _held && !widget.disabled ? .97 : 1,
          duration: Motion.instant,
          child: Opacity(
            opacity: widget.disabled ? .45 : 1,
            child: AnimatedContainer(
              duration: Motion.fast,
              curve: Motion.easeOut,
              height: 44,
              width: widget.block ? double.infinity : null,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: effBg,
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontFamily: kFontUi,
                  fontSize: TypeScale.sm,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  letterSpacing: 0,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 40px circular hit area, 20px stroke icon, sunken hover fill.
class KalimatIconButton extends StatefulWidget {
  const KalimatIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  State<KalimatIconButton> createState() => _KalimatIconButtonState();
}

class _KalimatIconButtonState extends State<KalimatIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: Motion.fast,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hover ? c.surfaceSunken : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, size: 20, color: c.textMuted),
          ),
        ),
      ),
    );
  }
}
