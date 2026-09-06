import 'package:flutter/material.dart';
import 'core/api/api_client.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/tasks/presentation/task_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bienenplan App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB703), // Honey / Bee themed primary
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: FutureBuilder<String?>(
        future: ApiClient().getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
            return const TaskListScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
