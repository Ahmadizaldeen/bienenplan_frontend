import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
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

    return _buildTaskOverview(_controller.tasks);
  }

  Widget _buildTaskOverview(List<Task> tasks) {
    final grouped = <int, List<Task>>{};
    final containerTitles = <int, String>{};

    for (final task in tasks) {
      grouped.putIfAbsent(task.containerId, () => []).add(task);
      containerTitles.putIfAbsent(task.containerId, () => task.containerTitle);
    }

    final containerIds = grouped.keys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final containerId in containerIds)
            Container(
              width: 320,
              margin: const EdgeInsets.only(right: AppSpacing.md),
              child: GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            containerTitles[containerId] ?? '',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '${grouped[containerId]!.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF263A35),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.sm),
                    ...[
                      for (final task in grouped[containerId]!)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: TaskItemWidget(
                            task: task,
                            onStatusChanged: () => _refreshTasks(),
                            showContainerBadge: false,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
