import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../data/auth_repository.dart';
import '../../tasks/presentation/task_list_screen.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({
    super.key,
    AuthRepository? authRepository,
  }) : authRepository = authRepository ?? AuthRepository();

  final AuthRepository authRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Der Form-Key ermöglicht es, die Validierung des gesamten Formulars zu starten.
  final _formKey = GlobalKey<FormState>();

  // Controller lesen den aktuellen Text aus den Eingabefeldern aus.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ob Ladeindikator angezeigt wird.
  bool _isLoading = false;

  // Steuert, ob das Passwort als Punkte oder als Klartext dargestellt wird.
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Controller besitzen Ressourcen und müssen beim Entfernen des Widgets
    // freigegeben werden, damit kein Speicherleck entsteht.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Prüft die Eingaben, ruft die API auf und navigiert bei Erfolg weiter.
  Future<void> _login() async {
    // Bei ungültigen Eingaben wird die API gar nicht erst aufgerufen.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      
      final success = await widget.authRepository.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Das Widget könnte während des Wartens geschlossen worden sein.
      if (!mounted) return;

      if (success) {
        // pushReplacement öffnet die Aufgabenliste und entfernt den Login aus
        // dem Zurück-Verlauf, damit man nicht zurück zum Login navigiert.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => TaskListScreen()),
        );
      } else {
        // false bedeutet: Die API antwortete, aber der Login war nicht erfolgreich.
        _showErrorSnackBar('Anmeldung fehlgeschlagen. Ungültige Zugangsdaten.');
      }
    } catch (e) {
      // Netzwerk- oder Serverfehler werden hier abgefangen und angezeigt.
      if (!mounted) return;
      _showErrorSnackBar(
        'Fehler: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      // Der Ladeindikator wird nach Erfolg, Misserfolg oder Fehler beendet.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Zeigt eine kurze Fehlermeldung am unteren Bildschirmrand an.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // build beschreibt die komplette sichtbare Oberfläche des Bildschirms.
    return Scaffold(
      body: Stack(
        children: [
          // Der Hintergrund liegt hinter dem Login-Formular.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.accent],
              ),
            ),
          ),
          // Das Formular wird zentriert und in den vorhandenen Glas-Container gelegt.
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: GlassContainer(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'BienenPlan',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Form verbindet die Eingabefelder und ihre Validatoren.
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-Mail',
                            ),
                            // Validator gibt null bei gültiger Eingabe oder
                            // einen Text für die Fehlermeldung zurück.
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Bitte E-Mail eingeben.';
                              }
                              if (!value.contains('@')) {
                                return 'Bitte eine gültige E-Mail eingeben.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Passwort',
                              suffixIcon: IconButton(
                                // setState aktualisiert Icon und Passwortdarstellung.
                                tooltip: _obscurePassword
                                    ? 'Passwort anzeigen'
                                    : 'Passwort ausblenden',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Bitte Passwort eingeben.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Während des Login-Aufrufs wird der Button durch einen
                    // Ladeindikator ersetzt, damit nicht mehrfach gesendet wird.
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _login,
                            child: const Text('Login'),
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
