/// Text field per the design's forms/Input: 52px field on surface-card,
/// accent border + focus ring on focus, taupe (never red) invalid state.
library;

import 'package:flutter/material.dart';

import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';

class KalimatInput extends StatefulWidget {
  const KalimatInput({
    super.key,
    this.label,
    this.hint,
    this.invalid = false,
    this.controller,
    this.placeholder,
    this.maxLength,
    this.autofocus = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
  });

  final String? label;

  /// Line under the field; rendered in [KalimatColors.textDanger] when
  /// [invalid] is true.
  final String? hint;
  final bool invalid;
  final TextEditingController? controller;
  final String? placeholder;
  final int? maxLength;
  final bool autofocus;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<KalimatInput> createState() => _KalimatInputState();
}

class _KalimatInputState extends State<KalimatInput> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    final focused = _focusNode.hasFocus;
    final borderColor = widget.invalid
        ? c.textDanger
        : focused
        ? c.accent
        : c.line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontFamily: kFontUi,
              fontSize: TypeScale.xs,
              fontWeight: FontWeight.w500,
              color: c.textMuted,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: Metrics.s2),
        ],
        AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.easeOut,
          height: 52,
          decoration: BoxDecoration(
            color: c.surfaceCard,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(Metrics.rLg),
            boxShadow: focused
                ? [BoxShadow(color: c.focusRing, spreadRadius: 3)]
                : null,
          ),
          child: Center(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              maxLength: widget.maxLength,
              keyboardType: widget.keyboardType,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: TextStyle(
                fontFamily: kFontUi,
                fontSize: TypeScale.md,
                color: c.textBody,
                letterSpacing: 0,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Metrics.s4,
                ),
                hintText: widget.placeholder,
                hintStyle: TextStyle(
                  fontFamily: kFontUi,
                  fontSize: TypeScale.md,
                  color: c.textSubtle,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
        if (widget.hint != null) ...[
          const SizedBox(height: Metrics.s2),
          Text(
            widget.hint!,
            style: TextStyle(
              fontFamily: kFontUi,
              fontSize: TypeScale.xs2,
              color: widget.invalid ? c.textDanger : c.textSubtle,
              letterSpacing: 0,
            ),
          ),
        ],
      ],
    );
  }
}
