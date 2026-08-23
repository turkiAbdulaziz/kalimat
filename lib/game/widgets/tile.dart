/// A single board tile: 2px border, 6px radius, Kufi 30/700 letter.
/// Owns the pop (letter typed) and flip (reveal) animations.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/strings.dart';
import '../engine/models.dart';

class Tile extends StatefulWidget {
  const Tile({
    super.key,
    this.letter = '',
    this.state = TileState.empty,
    this.size = Metrics.tileSize,
    this.animatePop = false,
    this.reveal = false,
    this.revealDelay = Duration.zero,
  });

  final String letter;
  final TileState state;
  final double size;

  /// Pop when the letter appears (motion setting on).
  final bool animatePop;

  /// Flip from the "filled" face to the evaluated face after [revealDelay].
  final bool reveal;
  final Duration revealDelay;

  @override
  State<Tile> createState() => _TileState();
}

class _TileState extends State<Tile> with TickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: Motion.base,
  );
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );

  @override
  void initState() {
    super.initState();
    if (widget.reveal) _startReveal();
  }

  void _startReveal() {
    Future<void>.delayed(widget.revealDelay, () {
      if (mounted) _flip.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(Tile old) {
    super.didUpdateWidget(old);
    if (widget.animatePop && old.letter.isEmpty && widget.letter.isNotEmpty) {
      _pop.forward(from: 0);
    }
    if (widget.reveal && !old.reveal) _startReveal();
  }

  @override
  void dispose() {
    _pop.dispose();
    _flip.dispose();
    super.dispose();
  }

  ({Color bg, Color border, Color text}) _faceColors(
    KalimatColors c,
    TileState state,
  ) => switch (state) {
    TileState.empty => (
      bg: Colors.transparent,
      border: c.tileEmptyBorder,
      text: c.textBody,
    ),
    TileState.filled => (
      bg: Colors.transparent,
      border: c.tileFilledBorder,
      text: c.textBody,
    ),
    TileState.correct => (
      bg: c.tileCorrect,
      border: c.tileCorrect,
      text: c.tileTextOnState,
    ),
    TileState.present => (
      bg: c.tilePresent,
      border: c.tilePresent,
      text: c.tileTextOnState,
    ),
    TileState.absent => (
      bg: c.tileAbsent,
      border: c.tileAbsent,
      text: c.tileTextOnState,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.kalimatColors;

    return AnimatedBuilder(
      animation: Listenable.merge([_pop, _flip]),
      builder: (context, _) {
        // While flipping (or waiting for the stagger delay), show the
        // "filled" face until the tile is edge-on at the halfway point.
        final eased = Motion.easeInOut.transform(_flip.value);
        final revealing = widget.reveal && eased < .5 && _flip.value < 1;
        final shownState = revealing && widget.state != TileState.empty
            ? TileState.filled
            : widget.state;
        final face = _faceColors(colors, shownState);

        // Pop: scale 1 -> 1.08 -> 1 with the overshoot curve.
        final popT = Motion.easePop.transform(_pop.value);
        final scale = _pop.isAnimating
            ? 1 + .08 * math.sin(popT * math.pi)
            : 1.0;

        // Flip: rotateX 0 -> 90deg -> 0 with perspective.
        final angle = widget.reveal && _flip.value > 0 && _flip.value < 1
            ? (eased < .5 ? eased : 1 - eased) * math.pi
            : 0.0;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateX(angle)
            ..scaleByDouble(scale, scale, 1, 1),
          child: Semantics(
            label: widget.letter.isEmpty ? S.emptyTile : widget.letter,
            child: Container(
              width: widget.size,
              height: widget.size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: face.bg,
                border: Border.all(color: face.border, width: 2),
                borderRadius: BorderRadius.circular(Metrics.rTile),
              ),
              child: Text(
                widget.letter,
                style: TextStyle(
                  fontFamily: kFontDisplay,
                  fontSize: TypeScale.tile * (widget.size / Metrics.tileSize),
                  fontWeight: FontWeight.w700,
                  color: face.text,
                  letterSpacing: 0,
                  height: 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
