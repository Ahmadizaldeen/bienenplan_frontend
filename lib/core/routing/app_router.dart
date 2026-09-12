import 'package:flutter/material.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/start_screen.dart';
import '../../features/tasks/presentation/task_list_screen.dart';

class AppRouter {
  static const String start = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String taskList = '/tasks';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case start:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => StartScreen(),
        );
      case login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LoginScreen(),
        );
      case register:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RegisterScreen(),
        );
      case taskList:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TaskListScreen(),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route nicht gefunden'))),
        );
    }
  }

  static Future<void> goToLogin(BuildContext context) async {
    await Navigator.of(context).pushNamed(login);
  }

  static Future<void> goToRegister(BuildContext context) async {
    await Navigator.of(context).pushNamed(register);
  }

  static Future<void> goToTaskList(BuildContext context) async {
    await Navigator.of(context).pushNamed(taskList);
  }

  static Future<void> replaceWithLogin(BuildContext context) async {
    await Navigator.of(context).pushReplacementNamed(login);
  }

  static Future<void> replaceWithRegister(BuildContext context) async {
    await Navigator.of(context).pushReplacementNamed(register);
  }

  static Future<void> replaceWithTaskList(BuildContext context) async {
    await Navigator.of(context).pushReplacementNamed(taskList);
  }
}
