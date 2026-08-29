/// Digit code in board clothing (design/components/forms/CodeInput.jsx): the
/// tiles are the game's own [Tile], so a friend code carries the same visual
/// language as a guess. Displayed in Arabic-Indic digits, ASCII on the wire.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/metrics.dart';
import '../../core/utils/arabic_digits.dart';
import '../engine/models.dart';
import 'tile.dart';

const int kFriendCodeLength = 6;

/// ٠-٩ typed on an Arabic keyboard are the same digits — accept both.
String normalizeCodeDigits(String raw) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  final buf = StringBuffer();
  for (final ch in raw.split('')) {
    final i = arabic.indexOf(ch);
    if (i >= 0) {
      buf.write(i);
    } else if (ch.codeUnitAt(0) >= 0x30 && ch.codeUnitAt(0) <= 0x39) {
      buf.write(ch);
    }
  }
  return buf.toString();
}

/// Read-only row of code tiles — «رمزي» on the friends tab.
class CodeDisplay extends StatelessWidget {
  const CodeDisplay({super.key, required this.code, this.tileSize = 44});

  final String code;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    final digits = code.padRight(kFriendCodeLength).split('');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (i, d) in digits.indexed) ...[
          if (i > 0) const SizedBox(width: Metrics.tileGap),
          Tile(
            letter: toArabicDigits(d.trim()),
            state: d.trim().isEmpty ? TileState.empty : TileState.filled,
            size: tileSize,
          ),
        ],
      ],
    );
  }
}

/// Editable code entry: the tiles are the visible field, a transparent
/// numeric input sits on top of them.
class CodeField extends StatefulWidget {
  const CodeField({
    super.key,
    required this.onChanged,
    this.length = kFriendCodeLength,
    this.autofocus = true,
    this.tileSize = 44,
    this.onSubmitted,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final int length;
  final bool autofocus;
  final double tileSize;

  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  String _value = '';

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    final digits = normalizeCodeDigits(raw);
    final clamped = digits.length > widget.length
        ? digits.substring(0, widget.length)
        : digits;
    if (clamped != raw) {
      _controller.value = TextEditingValue(
        text: clamped,
        selection: TextSelection.collapsed(offset: clamped.length),
      );
    }
    setState(() => _value = clamped);
    widget.onChanged(clamped);
    if (clamped.length == widget.length) widget.onSubmitted?.call(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final digits = _value.padRight(widget.length).split('');
    return GestureDetector(
      onTap: _focus.requestFocus,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (i, d) in digits.indexed) ...[
                if (i > 0) const SizedBox(width: Metrics.tileGap),
                Tile(
                  letter: toArabicDigits(d.trim()),
                  state: d.trim().isEmpty ? TileState.empty : TileState.filled,
                  size: widget.tileSize,
                  animatePop: i == _value.length - 1,
                ),
              ],
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                onChanged: _onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
