import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/core/strings.dart';
import 'package:kalimat/core/theme/kalimat_theme.dart';
import 'package:kalimat/core/theme/motion_scope.dart';
import 'package:kalimat/profile/delete_account_dialog.dart';

/// A host page whose one button opens the dialog and records the answer.
class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool? answer;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () async {
          final result = await showDeleteAccountDialog(context);
          setState(() => answer = result);
        },
        child: Text('open · ${answer ?? "-"}'),
      ),
    ),
  );
}

Widget _app() => MaterialApp(
  theme: kalimatTheme(Brightness.light),
  // Motion off keeps the dialog's rise out of the pump timeline.
  builder: (context, child) => MotionScope(enabled: false, child: child!),
  home: const Directionality(textDirection: TextDirection.rtl, child: _Host()),
);

void main() {
  testWidgets('spells out the consequences and offers confirm / cancel', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(find.text(S.deleteAccountTitle), findsOneWidget);
    expect(find.text(S.deleteAccountBody), findsOneWidget);
    expect(find.text(S.deleteConfirm), findsOneWidget);
    expect(find.text(S.cancel), findsOneWidget);
  });

  testWidgets('cancel answers false, confirm answers true', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.cancel));
    await tester.pumpAndSettle();
    expect(find.text('open · false'), findsOneWidget);

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.deleteConfirm));
    await tester.pumpAndSettle();
    expect(find.text('open · true'), findsOneWidget);
  });
}
