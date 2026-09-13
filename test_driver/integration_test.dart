/// Host-side driver for `integration_test/screenshots_test.dart`.
///
/// Each `binding.takeScreenshot(name)` in the test is captured on the device
/// by the integration_test plugin and handed to this callback once the run is
/// over (the callback is post-hoc, not live — so it can't shell out to
/// `simctl` for a status-bar shot; the eight frames would all show the last
/// screen). The PNGs are the full Flutter view at device resolution —
/// 1320×2868 on the iPhone 17 Pro Max — with the status-bar strip left to the
/// app's own background.
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/screenshots_test.dart -d $UDID
library;

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final dir = Directory('store/screenshots')..createSync(recursive: true);
    final file = File('${dir.path}/$name.png')..writeAsBytesSync(bytes);
    stdout.writeln('screenshot → ${file.path} (${bytes.length} bytes)');
    return true;
  },
);
