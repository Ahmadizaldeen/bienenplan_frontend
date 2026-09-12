import 'package:flutter/material.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../application/register_controller.dart';
import '../data/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  RegisterScreen({super.key, AuthRepositoryContract? authRepository})
    : authRepository = authRepository ?? AuthRepository();

  final AuthRepositoryContract authRepository;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final RegisterController _controller;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = RegisterController(authRepository: widget.authRepository);
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _controller.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Nach erfolgreicher Registrierung: zum Login
      // (Kein Token von Register, User muss sich anmelden)
      AppRouter.replaceWithLogin(context);
    } else if (_controller.errorMessage != null) {
      _showErrorSnackBar(_controller.errorMessage!);
    }
  }

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
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.accent],
              ),
            ),
          ),
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
                        'Konto erstellen',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Bitte Name eingeben.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-Mail',
                            ),
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
                              if (value.length < 6) {
                                return 'Das Passwort muss mindestens 6 Zeichen lang sein.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _controller.isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _register,
                            child: const Text('Registrieren'),
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
