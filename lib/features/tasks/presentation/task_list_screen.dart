import 'package:flutter/material.dart';

import '../../../core/routing/app_router.dart';
import '../application/task_controller.dart';
import '../data/task_model.dart';
import '../data/task_repository.dart';
import 'task_item_widget.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';

class TaskListScreen extends StatefulWidget {
  TaskListScreen({
    super.key,
    TaskRepositoryContract? taskRepository,
    AuthRepositoryContract? authRepository,
  }) : taskRepository = taskRepository ?? TaskRepository(),
       authRepository = authRepository ?? AuthRepository();

  final TaskRepositoryContract taskRepository;
  final AuthRepositoryContract authRepository;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late final TaskController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TaskController(taskRepository: widget.taskRepository);
    _controller.addListener(_handleControllerUpdate);
    _refreshTasks();
  }

  void _handleControllerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void _refreshTasks() {
    _controller.loadTasks();
  }

  Future<void> _handleLogout() async {
    await widget.authRepository.logout();
    if (!mounted) return;
    AppRouter.replaceWithLogin(context);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.hive_outlined),
            SizedBox(width: AppSpacing.sm),
            Text('Aufgabenübersicht'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Aktualisieren',
            onPressed: _refreshTasks,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.accent],
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: () async => _refreshTasks(),
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_controller.isLoading && _controller.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: GlassContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Fehler beim Laden',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(_controller.errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: _refreshTasks,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_controller.tasks.isEmpty) {
      return Center(
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.task_alt,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Keine Aufgaben vorhanden.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return _buildTaskList(_controller.tasks);
  }

  Widget _buildTaskList(List<Task> tasks) {
    final grouped = <int, List<Task>>{};
    final containerTitles = <int, String>{};

    for (final task in tasks) {
      grouped.putIfAbsent(task.containerId, () => []).add(task);
      containerTitles.putIfAbsent(task.containerId, () => task.containerTitle);
    }

    final containerIds = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: containerIds.length,
      itemBuilder: (context, index) {
        final containerId = containerIds[index];
        final containerTasks = grouped[containerId]!;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  containerTitles[containerId] ?? '',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Divider(height: AppSpacing.lg),
                Column(
                  children: [
                    for (final task in containerTasks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: TaskItemWidget(
                          task: task,
                          onStatusChanged: _refreshTasks,
                          showContainerBadge: false,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
