import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../projects/application/project_controller.dart';
import '../../../projects/presentation/project_list_widget.dart';
import '../../../projects/presentation/project_archive_screen.dart';
import '../../../settings/presentation/app_settings_dialog.dart';
import '../../../user/application/user_controller.dart';
import '../../../user/presentation/profile_avatar.dart';

class UserProfileSidebar extends StatelessWidget {
  const UserProfileSidebar({
    super.key,
    required this.onLogout,
    required this.isExpanded,
    required this.onToggle,
    this.projectController,
    this.userController,
  });

  final VoidCallback onLogout;
  final bool isExpanded;
  final VoidCallback onToggle;

  /// Optional von außen injizierter Controller, damit z.B. HomeScreen
  /// per Pull-to-Refresh dieselbe Projektliste neu laden kann.
  final ProjectController? projectController;

  /// Optional von außen injizierter Controller, damit der angezeigte
  /// Nutzername mit HomeScreen synchron bleibt.
  final UserController? userController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Die kompakte Kopfzeile bleibt mit Nutzer und Projekt synchron,
          // auch wenn die darunterliegenden Details eingeklappt sind.
          AnimatedBuilder(
            animation: Listenable.merge([userController, projectController]),
            builder: (context, _) {
              final userName = userController?.currentUser?.name ?? 'Benutzer';
              final projectName =
                  projectController?.selectedProject?.name ??
                  (projectController?.isLoading == true
                      ? 'Projekte werden geladen'
                      : 'Kein Projekt');
              final toggleLabel = isExpanded
                  ? 'Profil und Projekte zuklappen'
                  : 'Profil und Projekte aufklappen';

              return Semantics(
                expanded: isExpanded,
                child: Tooltip(
                  message: '$toggleLabel: $userName > $projectName',
                  child: TextButton.icon(
                    key: const ValueKey('profile-project-toggle'),
                    onPressed: onToggle,
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.onSurface,
                      backgroundColor: scheme.surfaceContainer,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                    ),
                    icon: Icon(isExpanded ? Icons.close : Icons.menu),
                    label: Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.chevron_right, size: 18),
                        ),
                        Flexible(
                          child: Text(
                            projectName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (isExpanded) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildDetails(context),
          ],
        ],
      ),
    );
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
                'Profil',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                onTap: () => AppSettingsDialog.show(
                  context,
                  userController: userController,
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: scheme.outlineVariant, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.work_outline, color: scheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Einstellungen',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Profil, Benachrichtigungen & mehr',
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
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: boardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Projekte',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ProjectListWidget(controller: projectController),
            ],
          ),
        ),
      ],
    );
  }
}
