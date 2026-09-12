import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../application/auth_controller.dart';
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

  late final AuthController _controller;

  // Steuert, ob das Passwort als Punkte oder als Klartext dargestellt wird.
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = AuthController(authRepository: widget.authRepository);
    _controller.addListener(_handleControllerUpdate);
  }

  void _handleControllerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Prüft die Eingaben, ruft die API auf und navigiert bei Erfolg weiter.
  Future<void> _login() async {
    // Bei ungültigen Eingaben wird die API gar nicht erst aufgerufen.
    if (!_formKey.currentState!.validate()) return;

    final success = await _controller.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => TaskListScreen()),
      );
    } else if (_controller.errorMessage != null) {
      _showErrorSnackBar(_controller.errorMessage!);
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
                    _controller.isLoading
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
