import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_gate.dart';

// Einstiegspunkt der Flutter-Anwendung.
void main() {
  // Stellt sicher, dass Flutter-Plugins wie Secure Storage bereit sind,
  // bevor die App gestartet wird.
  WidgetsFlutterBinding.ensureInitialized();

  // runApp setzt das erste Widget der Anwendung in den Flutter-Widget-Baum ein.
  runApp(const BienenPlan());
}

// Wurzel-Widget der Anwendung.
// StatelessWidget reicht hier aus, weil der globale App-Aufbau selbst keinen
// veränderlichen Zustand besitzt.
class BienenPlan extends StatelessWidget {
  const BienenPlan({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BienenPlan',
      debugShowCheckedModeBanner: true,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}
