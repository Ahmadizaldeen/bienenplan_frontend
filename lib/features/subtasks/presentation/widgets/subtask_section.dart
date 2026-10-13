import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/subtask_controller.dart';
import '../../data/subtask_model.dart';
import '../../data/subtask_repository.dart';

class SubtaskSection extends StatelessWidget {
  const SubtaskSection({
    super.key,
    required this.taskId,
    required this.repository,
    required this.onChanged,
    required this.onBusyChanged,
    this.draftSubtasks = const [],
    this.onDraftSubtasksChanged,
    this.disabled = false,
  });

  final int? taskId;
  final SubtaskRepositoryContract repository;
  final VoidCallback onChanged;
  final ValueChanged<bool> onBusyChanged;
  final List<String> draftSubtasks;
  final ValueChanged<List<String>>? onDraftSubtasksChanged;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final persistedTaskId = taskId;
    // Unsaved tasks show the section without sending requests with a missing ID.
    if (persistedTaskId == null) {
      return _NewTaskSubtaskSection(
        draftSubtasks: draftSubtasks,
        onDraftSubtasksChanged: onDraftSubtasksChanged,
        disabled: disabled,
      );
    }
    return ChangeNotifierProvider(
      key: ValueKey(persistedTaskId),
      create: (_) =>
          SubtaskController(taskId: persistedTaskId, repository: repository)
            ..load(),
      child: _SubtaskSectionBody(
        disabled: disabled,
        onChanged: onChanged,
        onBusyChanged: onBusyChanged,
      ),
    );
  }
}

class _NewTaskSubtaskSection extends StatelessWidget {
  const _NewTaskSubtaskSection({
    required this.draftSubtasks,
    required this.onDraftSubtasksChanged,
    required this.disabled,
  });

  final List<String> draftSubtasks;
  final ValueChanged<List<String>>? onDraftSubtasksChanged;
  final bool disabled;

  Future<void> _edit(BuildContext context, [int? index]) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => _SubtaskTitleDialog(
        initialTitle: index == null ? null : draftSubtasks[index],
      ),
    );
    if (title == null || disabled) return;

    final updated = [...draftSubtasks];
    if (index == null) {
      updated.add(title);
    } else {
      updated[index] = title;
    }
    onDraftSubtasksChanged?.call(updated);
  }

  void _remove(int index) {
    if (disabled) return;
    final updated = [...draftSubtasks]..removeAt(index);
    onDraftSubtasksChanged?.call(updated);
  }

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('subtask-section'),
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          Text(
            'Teilaufgaben',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
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
            onPressed: disabled || onDraftSubtasksChanged == null
                ? null
                : () => _edit(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Teilaufgabe hinzufügen'),
          ),
        ],
      ),
      for (var index = 0; index < draftSubtasks.length; index++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            key: ValueKey('draft-subtask-$index'),
            children: [
              const Icon(Icons.check_box_outline_blank),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(draftSubtasks[index])),
              IconButton(
                tooltip: 'Teilaufgabe bearbeiten',
                onPressed: disabled ? null : () => _edit(context, index),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Teilaufgabe entfernen',
                onPressed: disabled ? null : () => _remove(index),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
    ],
  );
}

class _SubtaskSectionBody extends StatefulWidget {
  const _SubtaskSectionBody({
    required this.disabled,
    required this.onChanged,
    required this.onBusyChanged,
  });

  final bool disabled;
  final VoidCallback onChanged;
  final ValueChanged<bool> onBusyChanged;

  @override
  State<_SubtaskSectionBody> createState() => _SubtaskSectionBodyState();
}

class _SubtaskSectionBodyState extends State<_SubtaskSectionBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SubtaskController>().load();
    });
  }

  Future<void> _run(Future<bool> Function() action) async {
    widget.onBusyChanged(true);
    try {
      final changed = await action();
      if (!mounted) return;
      // Subtask writes are immediate, not part of the parent task's save action.
      if (changed) widget.onChanged();
    } finally {
      if (mounted) widget.onBusyChanged(false);
    }
  }

  Future<void> _edit(SubtaskController controller, [Subtask? item]) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => _SubtaskTitleDialog(initialTitle: item?.title),
    );
    if (!mounted || title == null || widget.disabled || controller.mutating) {
      return;
    }
    await _run(
      () => item == null
          ? controller.create(title)
          : controller.update(item, title: title),
    );
  }

  Future<void> _delete(SubtaskController controller, Subtask item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Teilaufgabe loeschen?'),
        content: Text(item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Loeschen'),
          ),
        ],
      ),
    );
    if (!mounted ||
        confirmed != true ||
        widget.disabled ||
        controller.mutating) {
      return;
    }
    await _run(() => controller.delete(item));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SubtaskController>();
    final busy = widget.disabled || controller.mutating || controller.loading;
    return Column(
      key: const ValueKey('subtask-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            Text(
              'Teilaufgaben',
              style:
                  Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold) ??
                  const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (controller.canCreate)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
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
                onPressed: busy ? null : () => _edit(controller),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Teilaufgabe hinzufügen'),
              ),
          ],
        ),
        if (controller.loading) ...[
          const SizedBox(height: AppSpacing.xs),
          const LinearProgressIndicator(),
        ],
        if (controller.items.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          for (final item in controller.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                key: ValueKey('subtask-${item.id}'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: item.completed,
                    semanticLabel: item.title,
                    onChanged: busy || !item.canComplete
                        ? null
                        : (value) {
                            if (value != null) {
                              _run(
                                () => controller.update(item, completed: value),
                              );
                            }
                          },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        item.title,
                        style: TextStyle(
                          decoration: item.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ),
                  if (item.canEdit)
                    IconButton(
                      tooltip: 'Teilaufgabe bearbeiten',
                      onPressed: busy ? null : () => _edit(controller, item),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  if (item.canDelete)
                    IconButton(
                      tooltip: 'Teilaufgabe loeschen',
                      onPressed: busy ? null : () => _delete(controller, item),
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
            ),
        ],
        if (controller.mutating) ...[
          const SizedBox(height: AppSpacing.xs),
          const LinearProgressIndicator(),
        ],
        if (controller.error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton.icon(
                  onPressed: busy ? null : () => controller.load(force: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut laden'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SubtaskTitleDialog extends StatefulWidget {
  const _SubtaskTitleDialog({this.initialTitle});
  final String? initialTitle;

  @override
  State<_SubtaskTitleDialog> createState() => _SubtaskTitleDialogState();
}

class _SubtaskTitleDialogState extends State<_SubtaskTitleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle ?? '');
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _title.text.trim());
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.initialTitle == null
          ? 'Neue Teilaufgabe'
          : 'Teilaufgabe bearbeiten',
    ),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _title,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Titel'),
        validator: (value) {
          final title = (value ?? '').trim();
          if (title.isEmpty) return 'Bitte einen Titel eingeben.';
          if (title.runes.length > 100) return 'Maximal 100 Zeichen erlaubt.';
          return null;
        },
        onFieldSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Abbrechen'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Speichern')),
    ],
  );
}
