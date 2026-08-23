// Renders the app icon: the كلمات wordmark in Noto Kufi Arabic on brown.
// Run explicitly (not picked up by `flutter test` which only scans test/):
//
//   flutter test tool/generate_icon.dart
//
// Outputs:
//   assets/icon/icon_full.png  1024x1024 opaque   (legacy Android + iOS)
//   assets/icon/icon_fg.png    1024x1024 transparent foreground (adaptive)
// then run: dart run flutter_launcher_icons

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _accent = Color(0xFF8A6544); // brown-600
const _textColor = Color(0xFFFFFDFA); // brown-0

Future<void> _loadFont() async {
  final data = File(
    'assets/fonts/NotoKufiArabic-ExtraBold.ttf',
  ).readAsBytesSync().buffer.asByteData();
  final loader = FontLoader('NotoKufiArabic')..addFont(Future.value(data));
  await loader.load();
}

Future<void> _render({
  required String path,
  required bool opaque,
  required double fontSize,
}) async {
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  if (opaque) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, size, size),
      Paint()..color = _accent,
    );
  }

  final painter = TextPainter(
    text: TextSpan(
      text: 'كلمات',
      style: TextStyle(
        fontFamily: 'NotoKufiArabic',
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: _textColor,
        letterSpacing: 0,
        height: 1,
      ),
    ),
    textDirection: TextDirection.rtl,
  )..layout();
  painter.paint(
    canvas,
    Offset((size - painter.width) / 2, (size - painter.height) / 2),
  );

  final image = await recorder.endRecording().toImage(
    size.toInt(),
    size.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('generate icon PNGs', (tester) async {
    await tester.runAsync(() async {
      await _loadFont();
      await _render(
        path: 'assets/icon/icon_full.png',
        opaque: true,
        fontSize: 300,
      );
      // Adaptive foreground: keep the mark inside the ~66% safe zone.
      await _render(
        path: 'assets/icon/icon_fg.png',
        opaque: false,
        fontSize: 210,
      );
      expect(File('assets/icon/icon_full.png').existsSync(), isTrue);
    });
  });
}
