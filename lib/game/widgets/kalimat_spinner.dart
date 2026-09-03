/// The house loading spinner: system-standard indeterminate ring (the one
/// loop that earns its keep) in the accent brown, consistent 20px sizing.
library;

import 'package:flutter/material.dart';

import '../../core/theme/kalimat_colors.dart';

class KalimatSpinner extends StatelessWidget {
  const KalimatSpinner({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.kalimatColors.accent,
        ),
      ),
    );
  }
}
