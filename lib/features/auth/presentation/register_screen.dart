import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../application/register_controller.dart';
import '../data/auth_repository.dart';
import 'widgets/register_liquid_background.dart';

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
          const Positioned.fill(
            child: IgnorePointer(child: RegisterLiquidBackground()),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        tooltip: 'Zurück',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.register.iconSurface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: AppColors.register.iconBorder,
                              ),
                            ),
                            child: Icon(
                              Icons.person_add_alt_1_rounded,
                              color: AppColors.register.iconTint,
                              size: 32,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .scale(begin: const Offset(.8, .8)),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                            'Konto erstellen',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: AppColors.register.heading,
                                  fontWeight: FontWeight.bold,
                                ),
                          )
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 400.ms)
                          .slideY(begin: .15),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Registriere dich, um BienenPlan zu nutzen.',
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: AppColors.register.body),
                      ).animate().fadeIn(delay: 180.ms, duration: 400.ms),
                      const SizedBox(height: AppSpacing.xl),
                      GlassContainer(
                            borderRadius: AppRadius.lg,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      labelText: 'Name',
                                      prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Bitte Name eingeben.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: const InputDecoration(
                                      labelText: 'E-Mail',
                                      prefixIcon: Icon(Icons.email_outlined),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
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
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'Passwort',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                      ),
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword
                                            ? 'Passwort anzeigen'
                                            : 'Passwort ausblenden',
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
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
                                  const SizedBox(height: AppSpacing.lg),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: _controller.isLoading
                                          ? null
                                          : _register,
                                      child: _controller.isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Registrieren'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 260.ms, duration: 500.ms)
                          .slideY(begin: .12),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
