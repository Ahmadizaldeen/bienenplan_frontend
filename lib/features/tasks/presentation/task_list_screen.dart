import 'package:flutter/material.dart';

import '../data/task_model.dart';
import '../data/task_repository.dart';
import 'task_item_widget.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/start_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskRepository _taskRepository = TaskRepository();
  final AuthRepository _authRepository = AuthRepository();
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = _taskRepository.fetchTasks();
    });
  }

  void _handleLogout() async {
    await _authRepository.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const StartScreen()));
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

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return TaskItemWidget(
                      task: tasks[index],
                      onStatusChanged: _refreshTasks,
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
