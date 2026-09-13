import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../tasks/presentation/task_list_screen.dart';
import 'widgets/project_overview_header.dart';
import 'widgets/user_profile_sidebar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.accent],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;

              final sidebar = UserProfileSidebar(onLogout: onLogout);
              final content = _HomeContent();

              if (isWide) {
                final sidebarWidth =
                    ((constraints.maxWidth -
                                2 * AppSpacing.lg -
                                AppSpacing.lg) /
                            3)
                        .clamp(260.0, 420.0);

                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: sidebarWidth, child: sidebar),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: content),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    sidebar,
                    const SizedBox(height: AppSpacing.md),
                    Expanded(child: content),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => Future.value(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProjectOverviewHeader(onRefresh: _noop),
            const SizedBox(height: AppSpacing.md),
            TaskListScreen(),
          ],
        ),
      ),
    );
  }

  static void _noop() {}
}
