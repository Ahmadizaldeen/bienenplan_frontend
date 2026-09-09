import 'package:flutter/material.dart';

import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/start_screen.dart';
import 'features/tasks/presentation/task_list_screen.dart';

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
    // MaterialApp stellt Navigation, Theme, Titel und Material-Komponenten
    // für die gesamte Anwendung bereit.
    return MaterialApp(
      title: 'BienenPlan',
      // Das Banner zeigt im Entwicklungsmodus, dass die App im Debug-Modus läuft.
      debugShowCheckedModeBanner: true,
      // Beide Themes werden zentral in AppTheme definiert.
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Das Theme folgt automatisch den Einstellungen des Betriebssystems.
      themeMode: ThemeMode.system,
      // FutureBuilder wartet auf den gespeicherten JWT-Token.
      home: FutureBuilder<String?>(
        future: ApiClient().getToken(),
        builder: (context, snapshot) {
          // Während der Token gelesen wird, zeigen wir einen Ladeindikator.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Ein nicht leerer Token bedeutet: Der Benutzer ist bereits angemeldet.
          final hasToken =
              snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.isNotEmpty;

          // Angemeldete Benutzer starten direkt bei den Aufgaben.
          // Ohne Token beginnt der Ablauf auf dem Startscreen.
          return hasToken ? const TaskListScreen() : const StartScreen();
        },
      ),
    );
  }
}
