import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../projects/application/project_controller.dart';
import '../../../projects/presentation/project_list_widget.dart';
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'User Profile',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (userController != null)
                          AnimatedBuilder(
                            animation: userController!,
                            builder: (context, _) {
                              return Text(
                                userController!.currentUser?.name ?? '...',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Row(
                    children: [
                      Icon(
                        Icons.crop_square,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.crop_square,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.crop_square,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
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
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhiteSoft.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.work_outline, color: AppColors.accent),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Projektmanagerin',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
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
