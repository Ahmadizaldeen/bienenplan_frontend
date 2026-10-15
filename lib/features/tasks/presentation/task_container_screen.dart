import 'package:flutter/material.dart';

import '../application/task_controller.dart';
import '../data/container_model.dart' as container_model;
import '../data/container_order_store.dart';
import '../data/task_model.dart';
import 'task_dialog.dart';
import 'task_item_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../../user/application/user_controller.dart';

enum _ContainerAction { rename, delete }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({
    super.key,
    this.controller,
    this.projectId,
    this.userController,
    this.containerOrderStore,
  });

  /// Optionaler von außen injizierter Controller (z.B. von HomeScreen,
  /// damit ein Pull-to-Refresh von außen dieselben Daten neu laden kann).
  /// Wird keiner übergeben, verwaltet der Screen seinen eigenen Controller
  /// (z.B. bei eigenständiger Nutzung/Tests).
  final TaskController? controller;
  final int? projectId;
  final UserController? userController;
  final ContainerOrderStoreContract? containerOrderStore;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late final TaskController _controller = widget.controller ?? TaskController();
  late final UserController _userController =
      widget.userController ?? UserController();
  late final ContainerOrderStoreContract _containerOrderStore =
      widget.containerOrderStore ??
      const SharedPreferencesContainerOrderStore();
  final ScrollController _horizontalContainersScrollController =
      ScrollController();
  // Container-IDs halten den Klappzustand auch über Widget-Rebuilds hinweg fest.
  final Set<int> _collapsedContainerIds = {};
  List<int> _containerOrder = const [];
  int? _orderUserId;
  int? _orderProjectId;
  int _orderLoadVersion = 0;
  int _orderSaveVersion = 0;
  bool _orderReady = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerUpdate);
    _userController.addListener(_handleUserUpdate);
    // Nur selbst initial laden, wenn wir den Controller selbst besitzen.
    // Ein von außen injizierter Controller wurde vom Owner (z.B. HomeScreen)
    // bereits geladen bzw. wird von diesem verwaltet.
    if (widget.controller == null) {
      _refreshTasks();
    }
    if (widget.userController == null) {
      _loadCurrentUser();
    } else {
      _handleUserUpdate();
    }
  }

  @override
  void didUpdateWidget(covariant TaskListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _loadContainerOrder();
    }
  }

  void _handleControllerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleUserUpdate() {
    _loadContainerOrder();
  }

  Future<void> _loadCurrentUser() async {
    final loaded = await _userController.loadCurrentUser();
    if (!mounted) return;
    if (!loaded && _userController.errorMessage != null) {
      _showOrderError(
        'Benutzer konnte nicht geladen werden: ${_userController.errorMessage!}',
      );
    }
  }

  void _loadContainerOrder() {
    final userId = _userController.currentUser?.id;
    final projectId = widget.projectId;
    if (userId == _orderUserId && projectId == _orderProjectId && _orderReady) {
      return;
    }

    _orderUserId = userId;
    _orderProjectId = projectId;
    final version = ++_orderLoadVersion;
    if (userId == null) {
      setState(() {
        _orderReady = false;
        _containerOrder = const [];
      });
      return;
    }

    setState(() {
      _orderReady = false;
      _containerOrder = const [];
    });
    _containerOrderStore
        .loadOrder(userId: userId, projectId: projectId)
        .then((order) {
          if (!mounted || version != _orderLoadVersion) return;
          setState(() {
            _containerOrder = order;
            _orderReady = true;
          });
        })
        .catchError((Object error) {
          if (!mounted || version != _orderLoadVersion) return;
          setState(() {
            _containerOrder = const [];
            _orderReady = true;
          });
          _showOrderError(
            'Container-Reihenfolge konnte nicht geladen werden: $error',
          );
        });
  }

  List<int> _orderedContainerIds(Iterable<int> ids) {
    // Ignore removed/hidden IDs and append newly created containers stably.
    final remaining = ids.toSet();
    final ordered = <int>[];
    for (final id in _containerOrder) {
      if (remaining.remove(id)) ordered.add(id);
    }
    final newIds = remaining.toList()..sort();
    return [...ordered, ...newIds];
  }

  Future<void> _moveContainer(
    int draggedId,
    int targetId,
    List<int> containerIds,
  ) async {
    final userId = _userController.currentUser?.id;
    if (!_orderReady || userId == null || draggedId == targetId) return;

    final previousOrder = _orderedContainerIds(containerIds);
    final updatedOrder = List<int>.from(previousOrder);
    updatedOrder.remove(draggedId);
    updatedOrder.insert(updatedOrder.indexOf(targetId), draggedId);

    // Show the new order immediately; a failed write restores the snapshot.
    setState(() {
      _containerOrder = updatedOrder;
    });
    final loadVersion = _orderLoadVersion;
    final saveVersion = ++_orderSaveVersion;
    try {
      await _containerOrderStore.saveOrder(
        userId: userId,
        projectId: widget.projectId,
        containerIds: updatedOrder,
      );
    } catch (error) {
      if (!mounted ||
          loadVersion != _orderLoadVersion ||
          saveVersion != _orderSaveVersion) {
        return;
      }
      setState(() {
        _containerOrder = previousOrder;
      });
      _showOrderError(
        'Container-Reihenfolge konnte nicht gespeichert werden: $error',
      );
    }
  }

  void _showOrderError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _refreshTasks() {
    _controller.loadTasks();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);
    _userController.removeListener(_handleUserUpdate);
    // Nur aufräumen, wenn dieser Screen den Controller selbst erzeugt hat.
    // Ein von außen injizierter Controller gehört dem Owner (HomeScreen) und
    // darf hier nicht disposed werden, sonst crasht der Owner beim nächsten Zugriff.
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.userController == null) {
      _userController.dispose();
    }
    _horizontalContainersScrollController.dispose();
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

  void _handleContainerAction(
    _ContainerAction action,
    int containerId,
    String title,
  ) {
    switch (action) {
      case _ContainerAction.rename:
        _showRenameContainerDialog(containerId, title);
      case _ContainerAction.delete:
        _confirmDeleteContainer(containerId, title);
    }
  }

  Future<void> _showRenameContainerDialog(
    int containerId,
    String currentTitle,
  ) async {
    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => _RenameContainerDialog(currentTitle: currentTitle),
    );
    if (!mounted || newTitle == null || newTitle == currentTitle) return;

    try {
      await _controller.updateContainerTitle(containerId, newTitle);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Container wurde umbenannt.')),
      );
    } catch (error) {
      if (!mounted) return;
      _showContainerActionError('Umbenennen fehlgeschlagen', error);
    }
  }

  Future<void> _confirmDeleteContainer(int containerId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Container löschen?'),
        content: Text(
          '„$title“ wird gelöscht. Das ist nur möglich, wenn der Container '
          'keine unerledigten Aufgaben enthält.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    try {
      await _controller.deleteContainer(containerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Container wurde gelöscht.')),
      );
    } catch (error) {
      if (!mounted) return;
      _showContainerActionError('Löschen fehlgeschlagen', error);
    }
  }

  void _showContainerActionError(String action, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$action: ${error.toString().replaceFirst('Exception: ', '')}',
        ),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  Future<void> _showCreateTaskDialog(int containerId) async {
    int? projectId = widget.projectId;
    // Ohne aktive Projektauswahl bestimmt der Container den Scope der Gruppen.
    for (final container in _controller.extraContainers) {
      if (container.id == containerId) {
        projectId ??= container.projectId;
        break;
      }
    }
    final success = await showTaskDialog(
      context,
      controller: _controller,
      containerId: containerId,
      projectId: projectId,
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
    final changed = await showTaskDialog(
      context,
      controller: _controller,
      containerId: task.containerId,
      task: task,
    );
    if (!mounted) return;
    if (changed) {
      final wasDeleted = !_controller.tasks.any(
        (currentTask) => currentTask.id == task.id,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasDeleted
                ? 'Aufgabe erfolgreich gelöscht.'
                : 'Aufgabe aktualisiert.',
          ),
        ),
      );
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

    final containerIds = _orderedContainerIds(grouped.keys);
    final canReorderContainers =
        _orderReady && _userController.currentUser != null;
    final manageableContainerIds = {
      for (final container in extraContainers)
        if (container.canManage) container.id,
    };

    Widget buildContainer(
      int containerId, {
      required bool compact,
      bool showDragHandle = false,
    }) {
      return SizedBox(
        width: compact ? double.infinity : 320,
        child: GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (showDragHandle)
                    Tooltip(
                      message: 'Container verschieben',
                      child: Draggable<int>(
                        key: ValueKey('container-drag-$containerId'),
                        data: containerId,
                        feedback: Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: compact
                                ? (MediaQuery.sizeOf(context).width - 48).clamp(
                                    240.0,
                                    320.0,
                                  )
                                : 320,
                            child: Opacity(
                              opacity: 0.9,
                              child: buildContainer(
                                containerId,
                                compact: compact,
                              ),
                            ),
                          ),
                        ),
                        childWhenDragging: Icon(
                          Icons.drag_indicator,
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.35),
                        ),
                        child: Icon(
                          Icons.drag_indicator,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      containerTitles[containerId] ?? '',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    key: ValueKey('container-toggle-$containerId'),
                    tooltip: _collapsedContainerIds.contains(containerId)
                        ? 'Container ausklappen'
                        : 'Container einklappen',
                    // add() liefert false, wenn der Container bereits eingeklappt war.
                    onPressed: () => setState(() {
                      if (!_collapsedContainerIds.add(containerId)) {
                        _collapsedContainerIds.remove(containerId);
                      }
                    }),
                    icon: Icon(
                      _collapsedContainerIds.contains(containerId)
                          ? Icons.expand_more
                          : Icons.expand_less,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (manageableContainerIds.contains(containerId))
                    PopupMenuButton<_ContainerAction>(
                      key: ValueKey('container-settings-$containerId'),
                      tooltip: 'Container-Einstellungen',
                      onSelected: (action) => _handleContainerAction(
                        action,
                        containerId,
                        containerTitles[containerId] ?? '',
                      ),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _ContainerAction.rename,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Name ändern'),
                          ),
                        ),
                        PopupMenuItem(
                          value: _ContainerAction.delete,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.delete_outline),
                            title: Text('Container löschen'),
                          ),
                        ),
                      ],
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhiteSoft.withValues(alpha: 0.25),
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
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _collapsedContainerIds.contains(containerId)
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: AppSpacing.sm),
                          if (grouped[containerId]!.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
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
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: SizedBox(
                                  key: ValueKey('task-card-${task.id}'),
                                  width: double.infinity,
                                  child: TaskItemWidget(
                                    task: task,
                                    onStatusChanged: () => _refreshTasks(),
                                    onTap: () => _showTaskDetailDialog(task),
                                    showContainerBadge: false,
                                  ),
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
            ],
          ),
        ),
      );
    }

    Widget buildSortableContainer(int containerId, {required bool compact}) {
      final child = buildContainer(
        containerId,
        compact: compact,
        showDragHandle: canReorderContainers,
      );
      if (!canReorderContainers) return child;

      return DragTarget<int>(
        key: ValueKey('container-drop-$containerId'),
        onWillAcceptWithDetails: (details) => details.data != containerId,
        onAcceptWithDetails: (details) =>
            _moveContainer(details.data, containerId, containerIds),
        builder: (context, candidates, rejected) => Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: candidates.isEmpty
                  ? null
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
              child: child,
            ),
            if (candidates.isNotEmpty)
              Positioned(
                key: ValueKey('container-drop-indicator-$containerId'),
                left: compact ? 0 : -AppSpacing.xs,
                right: compact ? 0 : null,
                top: compact ? -AppSpacing.xs : 0,
                bottom: compact ? null : 0,
                child: IgnorePointer(
                  child: Container(
                    width: compact ? null : 4,
                    height: compact ? 4 : null,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.35),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    Widget buildAddContainerButton({required bool compact}) {
      return SizedBox(
        width: compact ? double.infinity : 220,
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
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final containerId in containerIds) ...[
                  buildSortableContainer(containerId, compact: true),
                  const SizedBox(height: AppSpacing.md),
                ],
                buildAddContainerButton(compact: true),
              ],
            ),
          );
        }

        // A top-positioned scrollbar keeps horizontal navigation visible
        // above the complete row of containers.
        return Scrollbar(
          key: const ValueKey('container-overview-scrollbar'),
          controller: _horizontalContainersScrollController,
          thumbVisibility: true,
          scrollbarOrientation: ScrollbarOrientation.top,
          child: SingleChildScrollView(
            controller: _horizontalContainersScrollController,
            scrollDirection: Axis.horizontal,
            child: Padding(
              key: const ValueKey('container-overview-items-spacing'),
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final containerId in containerIds) ...[
                    buildSortableContainer(containerId, compact: false),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  buildAddContainerButton(compact: false),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RenameContainerDialog extends StatefulWidget {
  const _RenameContainerDialog({required this.currentTitle});

  final String currentTitle;

  @override
  State<_RenameContainerDialog> createState() => _RenameContainerDialogState();
}

class _RenameContainerDialogState extends State<_RenameContainerDialog> {
  late final TextEditingController _textController = TextEditingController(
    text: widget.currentTitle,
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Container umbenennen'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _textController,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(labelText: 'Container-Name'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bitte geben Sie einen Container-Namen ein.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_textController.text.trim());
            }
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
