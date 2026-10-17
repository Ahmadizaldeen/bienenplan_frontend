import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../projects/application/project_controller.dart';
import '../../../projects/presentation/project_archive_screen.dart';
import '../../../settings/presentation/settings_sidebar_section.dart';
import '../../../user/application/user_controller.dart';
import '../../../user/presentation/profile_avatar.dart';

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
              SettingsSidebarSection(userController: userController),
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
