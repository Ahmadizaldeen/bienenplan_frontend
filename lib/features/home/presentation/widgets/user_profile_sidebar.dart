import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../projects/application/project_controller.dart';
import '../../../projects/presentation/project_list_widget.dart';
import '../../../settings/presentation/app_settings_dialog.dart';
import '../../../user/application/user_controller.dart';

class UserProfileSidebar extends StatelessWidget {
  const UserProfileSidebar({
    super.key,
    required this.onLogout,
    this.projectController,
    this.userController,
  });

  final VoidCallback onLogout;

  /// Optional von außen injizierter Controller, damit z.B. HomeScreen
  /// per Pull-to-Refresh dieselbe Projektliste neu laden kann.
  final ProjectController? projectController;

  /// Optional von außen injizierter Controller, damit der angezeigte
  /// Nutzername mit HomeScreen synchron bleibt.
  final UserController? userController;

  @override
  Widget build(BuildContext context) {
    final boardDecoration = BoxDecoration(
      color: AppColors.warmPanel.withValues(alpha: 0.52),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(
        color: AppColors.warmPanelBorder.withValues(alpha: 0.85),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowSoft,
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
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.whiteOverlay,
                    ),
                  ),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userEmail,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
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
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '...@example.com',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Profil',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
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
                    color: AppColors.surfaceWhiteSoft.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: AppColors.warmPanelBorder.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.work_outline, color: AppColors.accent),
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
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
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
              const Text(
                'Projekte',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
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
