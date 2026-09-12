import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import 'register_screen.dart';

class StartScreen extends StatefulWidget {
  StartScreen({super.key, ApiClient? apiClient})
    : apiClient = apiClient ?? ApiClient();

  final ApiClient apiClient;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  // Während der Anfrage wird der Info-Button deaktiviert und ein Spinner gezeigt.
  bool _isCheckingApi = false;

  // Prüft, ob die API über die öffentliche Route /api erreichbar ist.
  // async erlaubt es, auf die Antwort des Servers zu warten.
  Future<void> _showApiStatus() async {
    // setState teilt Flutter mit, dass sich die Oberfläche ändern soll.
    setState(() => _isCheckingApi = true);

    try {
      // baseUrl endet in diesem Projekt auf /api.
      // await wartet auf die Serverantwort, ohne die UI zu blockieren.
      final response = await widget.apiClient.get(ApiEndpoints.baseUrl);

      // Der Screen könnte während der Anfrage geschlossen worden sein.
      // Dann darf hier nicht mehr auf seinen BuildContext zugegriffen werden.
      if (!mounted) return;
      _showStatusDialog(
        title: 'API erreichbar',
        message: response?.toString() ?? 'Die API antwortet erfolgreich.',
        isError: false,
      );
    } catch (error) {
      // Netzwerkfehler oder HTTP-Fehler werden hier als Fehlermeldung angezeigt.
      if (!mounted) return;
      _showStatusDialog(
        title: 'API nicht erreichbar',
        message: error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      // Dieser Block läuft immer: bei Erfolg und auch bei einem Fehler.
      // Dadurch endet der Ladezustand zuverlässig.
      if (mounted) setState(() => _isCheckingApi = false);
    }
  }

  // Öffnet einen Dialog mit dem Ergebnis der API-Prüfung.
  // required bedeutet, dass alle drei Werte beim Aufruf angegeben werden müssen.
  void _showStatusDialog({
    required String title,
    required String message,
    required bool isError,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError
                  ? Theme.of(context).colorScheme.error
                  : AppColors.accent,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(title),
          ],
        ),
        content: SelectableText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // build beschreibt die sichtbare Oberfläche des Startscreens.
    return Scaffold(
      body: Stack(
        children: [
          // Der Farbverlauf bildet den Hintergrund.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.accent],
              ),
            ),
          ),
          // Center positioniert das Startformular in der Bildschirmmitte.
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: GlassContainer(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  // mainAxisSize.min verhindert, dass die Spalte unnötig
                  // die gesamte Bildschirmhöhe einnimmt.
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hive_outlined,
                      size: 72,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'BienenPlan',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Aufgaben gemeinsam planen und verwalten.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        // push öffnet den Login über dem Startscreen.
                        // pop im Login führt später wieder hierher zurück.
                        onPressed: () => AppRouter.goToLogin(context),
                        icon: const Icon(Icons.login),
                        label: const Text('Anmelden'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        // Die Registrierung ist momentan ein Platzhalter-Screen.
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.person_add_outlined),
                        label: const Text('Registrieren'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    IconButton(
                      // Während der Anfrage verhindert null einen zweiten Klick.
                      onPressed: _isCheckingApi ? null : _showApiStatus,
                      tooltip: 'API-Status prüfen',
                      // Je nach Zustand wird ein Spinner oder das Info-Icon gezeigt.
                      icon: _isCheckingApi
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.info_outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
