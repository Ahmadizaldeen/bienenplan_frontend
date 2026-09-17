import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bienenplan_frontend/core/routing/app_router.dart';

void main() {
  testWidgets('AppRouter resolves known routes', (tester) async {
    // final startRoute = AppRouter.onGenerateRoute(
    //   const RouteSettings(name: AppRouter.start),
    // );
    final loginRoute = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppRouter.login),
    );
    final registerRoute = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppRouter.register),
    );
    final taskRoute = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppRouter.taskList),
    );

    // expect(startRoute.settings.name, AppRouter.start);
    expect(loginRoute.settings.name, AppRouter.login);
    expect(registerRoute.settings.name, AppRouter.register);
    expect(taskRoute.settings.name, AppRouter.taskList);
  });
}
