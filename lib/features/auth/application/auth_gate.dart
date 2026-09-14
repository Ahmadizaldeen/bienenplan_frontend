import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/routing/app_router.dart';
import '../presentation/start_screen.dart';
import '../../home/presentation/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, Future<String?> Function()? tokenReader})
    : _tokenReader = tokenReader ?? _defaultTokenReader;

  static Future<String?> _defaultTokenReader() => ApiClient().getToken();

  final Future<String?> Function() _tokenReader;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _tokenReader(),
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
