import 'package:flutter/material.dart';

import '../../../core/routing/app_router.dart';
import '../../home/presentation/home_screen.dart';
import '../application/auth_session_controller.dart';
import 'start_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.tokenReader, this.sessionController});

  final Future<String?> Function()? tokenReader;
  final AuthSessionController? sessionController;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthSessionController _sessionController =
      widget.sessionController ?? AuthSessionController();
  late final Future<String?> _token =
      widget.tokenReader?.call() ?? _sessionController.getToken();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _token,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasToken =
            snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty;

        return hasToken
            ? HomeScreen(
                onLogout: () async {
                  await AppRouter.logoutAndNavigateToLogin(context);
                },
              )
            : StartScreen();
      },
    );
  }
}
