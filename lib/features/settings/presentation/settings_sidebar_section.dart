import 'package:flutter/material.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../user/application/user_controller.dart';
import '../../user/presentation/profile_picture_dialog.dart';

class SettingsSidebarSection extends StatelessWidget {
  const SettingsSidebarSection({super.key, this.userController});

  final UserController? userController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Einstellungen',
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
        const _SettingsTile(
          icon: Icons.notifications_none,
          title: 'Benachrichtigungen',
          subtitle: 'Erinnerungen und Hinweise',
        ),
        const _SettingsTile(
          icon: Icons.palette_outlined,
          title: 'Darstellung',
          subtitle: 'Theme und Oberfläche',
        ),
        const _SettingsTile(
          icon: Icons.security_outlined,
          title: 'Sicherheit',
          subtitle: 'Passwort und Zugriff',
        ),
        _SettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Datenschutzerklärung',
          subtitle: 'Informationen zur Verarbeitung deiner Daten',
          onTap: () {
            Scaffold.maybeOf(context)?.closeDrawer();
            Navigator.of(context).pushNamed(AppRouter.privacy);
          },
        ),
        _SettingsTile(
          icon: Icons.info_outline,
          title: 'Impressum',
          subtitle: 'Betreiber- und Kontaktangaben',
          onTap: () {
            Scaffold.maybeOf(context)?.closeDrawer();
            Navigator.of(context).pushNamed(AppRouter.imprint);
          },
        ),
      ],
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
      key: ValueKey('profile-setting-${title.toLowerCase()}'),
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
