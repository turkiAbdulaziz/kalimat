/// MaterialApp shell: Arabic locale (app-wide RTL), light/dark themes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/strings.dart';
import 'core/theme/kalimat_theme.dart';
import 'core/theme/motion_scope.dart';
import 'flow/root_flow.dart';
import 'game/state/settings_controller.dart';

class KalimatApp extends ConsumerWidget {
  const KalimatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(settingsProvider.select((s) => s.dark));
    final motion = ref.watch(settingsProvider.select((s) => s.motion));

    return MaterialApp(
      title: S.appTitle,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: kalimatTheme(Brightness.light),
      darkTheme: kalimatTheme(Brightness.dark),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      // Above the Navigator/Overlay so dialog routes and pushed screens
      // inherit the motion gate.
      builder: (context, child) => MotionScope(enabled: motion, child: child!),
      home: const RootFlow(),
    );
  }
}
