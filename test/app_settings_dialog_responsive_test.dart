import 'package:bienenplan_frontend/features/settings/presentation/app_settings_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings remain scrollable on a short phone', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => AppSettingsDialog.show(context),
              child: const Text('Einstellungen öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Einstellungen öffnen'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    expect(find.text('Schließen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
