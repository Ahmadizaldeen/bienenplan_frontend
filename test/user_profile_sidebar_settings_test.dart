import 'package:bienenplan_frontend/core/routing/app_router.dart';
import 'package:bienenplan_frontend/features/home/presentation/widgets/user_profile_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings are listed directly and scroll on a short phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRouter.imprint: (_) =>
              const Scaffold(body: Text('Impressum-Seite')),
        },
        home: Scaffold(
          body: SingleChildScrollView(
            child: UserProfileSidebar(onLogout: () {}),
          ),
        ),
      ),
    );

    for (final title in [
      'Profil',
      'Benachrichtigungen',
      'Darstellung',
      'Sicherheit',
      'Datenschutzerklärung',
      'Impressum',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Impressum'));
    await tester.tap(find.text('Impressum'));
    await tester.pumpAndSettle();

    expect(find.text('Impressum-Seite'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
