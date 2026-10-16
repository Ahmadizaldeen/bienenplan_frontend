import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../../projects/application/project_controller.dart';
import '../../../projects/presentation/project_archive_screen.dart';
import '../../../user/application/user_controller.dart';
import '../../../user/presentation/profile_avatar.dart';
import '../../../user/presentation/profile_picture_dialog.dart';

class UserProfileSidebar extends StatelessWidget {
  const UserProfileSidebar({
    super.key,
    required this.onLogout,
    this.projectController,
    this.userController,
  });

  final VoidCallback onLogout;
  final ProjectController? projectController;
  final UserController? userController;

  @override
  Widget build(BuildContext context) {
    return _buildDetails(context);
  }

  Widget _buildDetails(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final boardDecoration = BoxDecoration(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: scheme.outlineVariant, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: boardDecoration,
          child: Column(
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
                    child: userController != null
                        ? AnimatedBuilder(
                            animation: userController!,
                            builder: (context, _) {
                              final userName =
                                  userController!.currentUser?.name ?? '...';
                              final userEmail =
                                  userController!.currentUser?.email ?? '...';

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userEmail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              );
                            },
                          )
                        : const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '...@example.com',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.lg),
              if (userController != null && projectController != null)
                AnimatedBuilder(
                  animation: userController!,
                  builder: (context, _) =>
                      userController!.currentUser?.isAdmin == true
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.admin_panel_settings_outlined,
                            ),
                            label: const Text('Admin-Bereich · Projektarchiv'),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ProjectArchiveScreen(
                                  projectController: projectController!,
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Abmelden'),
                ),
              ),
            ],
          ),
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
