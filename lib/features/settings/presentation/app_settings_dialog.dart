import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../user/application/user_controller.dart';
import '../../user/presentation/profile_avatar.dart';
import '../../user/presentation/profile_picture_dialog.dart';

class AppSettingsDialog extends StatelessWidget {
  const AppSettingsDialog({super.key, this.userController});

  final UserController? userController;

  static Future<void> show(
    BuildContext context, {
    UserController? userController,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AppSettingsDialog(userController: userController),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final userName = userController?.currentUser?.name ?? 'Benutzer';
    final userEmail =
        userController?.currentUser?.email ?? 'keine E-Mail hinterlegt';

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (userController != null)
                    AnimatedBuilder(
                      animation: userController!,
                      builder: (_, _) => ProfileAvatar(
                        user: userController!.currentUser,
                        imageBytes: userController!.currentProfilePictureBytes,
                      ),
                    )
                  else
                    const ProfileAvatar(user: null),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'App-Einstellungen',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Profil',
                subtitle: 'Profilbild und Kontodaten verwalten',
                onTap: userController == null
                    ? null
                    : () => showProfilePictureDialog(
                        context,
                        controller: userController!,
                      ),
              ),
              _SettingsTile(
                icon: Icons.notifications_none,
                title: 'Benachrichtigungen',
                subtitle: 'Erinnerungen und Hinweise',
              ),
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Darstellung',
                subtitle: 'Theme und Oberfläche',
              ),
              _SettingsTile(
                icon: Icons.security_outlined,
                title: 'Sicherheit',
                subtitle: 'Passwort und Zugriff',
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Schließen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: scheme.outlineVariant, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
