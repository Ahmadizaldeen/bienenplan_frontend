import 'package:flutter/material.dart';

import '../data/task_model.dart';
import '../data/task_repository.dart';
import 'task_item_widget.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/start_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';

class TaskListScreen extends StatefulWidget {
  TaskListScreen({
    super.key,
    TaskRepository? taskRepository,
    AuthRepository? authRepository,
  })  : taskRepository = taskRepository ?? TaskRepository(),
        authRepository = authRepository ?? AuthRepository();

  final TaskRepository taskRepository;
  final AuthRepository authRepository;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = widget.taskRepository.fetchTasks();
    });
  }

  void _handleLogout() async {
    await widget.authRepository.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => StartScreen()));
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
            child: FutureBuilder<List<Task>>(
              future: _tasksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
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
                            Text(
                              snapshot.error.toString().replaceAll(
                                'Exception: ',
                                '',
                              ),
                              textAlign: TextAlign.center,
                            ),
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
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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

                final tasks = snapshot.data!;

                // Aufgaben nach Container gruppieren, Reihenfolge bleibt erhalten.
                final Map<int, List<Task>> grouped = {};
                final Map<int, String> containerTitles = {};
                for (final task in tasks) {
                  grouped.putIfAbsent(task.containerId, () => []).add(task);
                  containerTitles.putIfAbsent(
                    task.containerId,
                    () => task.containerTitle,
                  );
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
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}