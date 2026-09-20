import 'package:flutter/material.dart';

import '../application/task_controller.dart';
import '../data/container_model.dart' as container_model;
import '../data/task_model.dart';
import 'task_create_dialog.dart';
import 'task_detail_dialog.dart';
import 'task_item_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key, this.controller, this.projectId});

  /// Optionaler von außen injizierter Controller (z.B. von HomeScreen,
  /// damit ein Pull-to-Refresh von außen dieselben Daten neu laden kann).
  /// Wird keiner übergeben, verwaltet der Screen seinen eigenen Controller
  /// (z.B. bei eigenständiger Nutzung/Tests).
  final TaskController? controller;
  final int? projectId;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late final TaskController _controller = widget.controller ?? TaskController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerUpdate);
    // Nur selbst initial laden, wenn wir den Controller selbst besitzen.
    // Ein von außen injizierter Controller wurde vom Owner (z.B. HomeScreen)
    // bereits geladen bzw. wird von diesem verwaltet.
    if (widget.controller == null) {
      _refreshTasks();
    }
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
    // Nur aufräumen, wenn dieser Screen den Controller selbst erzeugt hat.
    // Ein von außen injizierter Controller gehört dem Owner (HomeScreen) und
    // darf hier nicht disposed werden, sonst crasht der Owner beim nächsten Zugriff.
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _showCreateContainerDialog() async {
    if (widget.projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte wählen Sie zuerst ein Projekt aus.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Neuer Container'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Container-Titel',
                hintText: 'z.B. To Do, In Progress, Sprint 1',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte geben Sie einen Container-Titel ein.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Erstellen'),
            ),
          ],
        );
      },
    );

    if (created == true && mounted) {
      final success = await _controller.createContainer(
        textController.text,
        projectId: widget.projectId,
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Container erfolgreich erstellt!')),
        );
      } else if (_controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.errorMessage!),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
    textController.dispose();
  }

  Future<void> _showCreateTaskDialog(int containerId) async {
    final success = await showCreateTaskDialog(
      context,
      controller: _controller,
      containerId: containerId,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aufgabe erfolgreich erstellt!')),
      );
    } else if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _showTaskDetailDialog(Task task) async {
    final changed = await showTaskDetailDialog(
      context,
      controller: _controller,
      task: task,
    );
    if (!mounted) return;
    if (changed) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Aufgabe aktualisiert.')));
    }
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

    final visibleTasks = widget.projectId == null
        ? _controller.tasks
        : _controller.tasks.where((task) {
            // Manche Task-Antworten liefern kein eigenes project_id, daher
            // zusätzlich über den zugehörigen Container abgleichen.
            if (task.projectId == widget.projectId) return true;
            for (final container in _controller.extraContainers) {
              if (container.id == task.containerId) {
                return container.projectId == widget.projectId;
              }
            }
            return false;
          }).toList();

    final matchingExtraContainers = widget.projectId == null
        ? _controller.extraContainers
        : _controller.extraContainers
              .where((c) => c.projectId == widget.projectId)
              .toList();

    if (visibleTasks.isEmpty && matchingExtraContainers.isEmpty) {
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
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: _showCreateContainerDialog,
                icon: const Icon(Icons.add),
                label: const Text('Neuer Container'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildTaskOverview(visibleTasks, matchingExtraContainers);
  }

  Widget _buildTaskOverview(
    List<Task> tasks,
    List<container_model.Container> extraContainers,
  ) {
    final grouped = <int, List<Task>>{};
    final containerTitles = <int, String>{};

    for (final task in tasks) {
      grouped.putIfAbsent(task.containerId, () => []).add(task);
      containerTitles.putIfAbsent(task.containerId, () => task.containerTitle);
    }

    for (final container in extraContainers) {
      grouped.putIfAbsent(container.id, () => []);
      containerTitles.putIfAbsent(container.id, () => container.title);
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
                            color: AppColors.surfaceWhiteSoft.withValues(
                              alpha: 0.25,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '${grouped[containerId]!.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.sm),
                    if (grouped[containerId]!.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Center(
                          child: Text(
                            'Keine Aufgaben in diesem Container',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      for (final task in grouped[containerId]!)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: TaskItemWidget(
                            task: task,
                            onStatusChanged: () => _refreshTasks(),
                            onTap: () => _showTaskDetailDialog(task),
                            showContainerBadge: false,
                          ),
                        ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    TextButton.icon(
                      onPressed: () => _showCreateTaskDialog(containerId),
                      icon: const Icon(Icons.add),
                      label: const Text('Aufgabe hinzufügen'),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(
            width: 220,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.5),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onPressed: _showCreateContainerDialog,
              icon: const Icon(Icons.add),
              label: const Text('Neuer Container'),
            ),
          ),
        ],
      ),
    );
  }
}
