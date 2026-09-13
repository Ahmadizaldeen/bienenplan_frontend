import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../projects/application/project_controller.dart';
import '../../tasks/application/task_controller.dart';
import '../../tasks/presentation/task_list_screen.dart';
import 'widgets/project_overview_header.dart';
import 'widgets/user_profile_sidebar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // HomeScreen besitzt beide Controller zentral, damit Pull-to-Refresh und
  // der Refresh-Button in ProjectOverviewHeader dieselben Daten neu laden
  // können, die TaskListScreen und ProjectListWidget anzeigen.
  final TaskController _taskController = TaskController();
  final ProjectController _projectController = ProjectController();

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  @override
  void dispose() {
    _taskController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() {
    return Future.wait([
      _taskController.loadTasks(),
      _projectController.loadProjects(),
    ]);
  }

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

              final sidebar = UserProfileSidebar(
                onLogout: widget.onLogout,
                projectController: _projectController,
              );
              final content = _HomeContent(
                taskController: _taskController,
                onRefresh: _refreshAll,
              );

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
  const _HomeContent({required this.taskController, required this.onRefresh});

  final TaskController taskController;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProjectOverviewHeader(onRefresh: onRefresh),
            const SizedBox(height: AppSpacing.md),
            TaskListScreen(controller: taskController),
          ],
        ),
      ),
    );
  }
}