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
    this.disabled = false,
  });

  final int? taskId;
  final SubtaskRepositoryContract repository;
  final VoidCallback onChanged;
  final ValueChanged<bool> onBusyChanged;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final persistedTaskId = taskId;
    // Unsaved tasks show the section without sending requests with a missing ID.
    if (persistedTaskId == null) {
      return const ListTile(
        key: ValueKey('subtask-section'),
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.info_outline),
        title: Text('Teilaufgaben'),
        subtitle: Text(
          'Teilaufgaben können nach dem Erstellen der Aufgabe hinzugefügt und bearbeitet werden.',
        ),
      );
    }
    return ChangeNotifierProvider(
      key: ValueKey(persistedTaskId),
      create: (_) =>
          SubtaskController(taskId: persistedTaskId, repository: repository),
      child: _SubtaskSectionBody(
        disabled: disabled,
        onChanged: onChanged,
        onBusyChanged: onBusyChanged,
      ),
    );
  }
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
    return ExpansionTile(
      key: const ValueKey('subtask-section'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
      title: const Text('Teilaufgaben'),
      onExpansionChanged: (expanded) {
        if (expanded) controller.load();
      },
      children: [
        if (controller.loading) const LinearProgressIndicator(),
        if (controller.loaded && controller.items.isEmpty)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Noch keine Teilaufgaben.'),
          ),
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
        if (controller.canCreate)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: busy ? null : () => _edit(controller),
              icon: const Icon(Icons.add),
              label: const Text('Teilaufgabe hinzufuegen'),
            ),
          ),
        if (controller.mutating) const LinearProgressIndicator(),
        if (controller.error != null)
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
