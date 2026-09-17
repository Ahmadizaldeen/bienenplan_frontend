import 'package:flutter/material.dart';

import '../application/task_controller.dart';
import '../data/group_model.dart';
import '../../../core/theme/app_theme.dart';

/// Zeigt die Task-Einzelsicht als Dialog zum Erstellen einer neuen Aufgabe
/// im übergebenen Container. Gibt `true` zurück, wenn die Aufgabe erfolgreich
/// erstellt wurde.
Future<bool> showCreateTaskDialog(
  BuildContext context, {
  required TaskController controller,
  required int containerId,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) =>
        _CreateTaskDialog(controller: controller, containerId: containerId),
  );
  return result ?? false;
}

class _CreateTaskDialog extends StatefulWidget {
  const _CreateTaskDialog({
    required this.controller,
    required this.containerId,
  });

  final TaskController controller;
  final int containerId;

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _attachmentController = TextEditingController();
  String _status = 'pending';
  DateTime? _deadline;
  bool _isSubmitting = false;
  bool _isLoadingGroups = true;
  List<Group> _allGroups = const [];
  final Set<int> _selectedGroupIds = {};

  static const _statusOptions = {
    'pending': 'Offen',
    'in_progress': 'In Bearbeitung',
    'done': 'Erledigt',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final groups = await widget.controller.fetchAllGroups();
    if (!mounted) return;
    setState(() {
      _allGroups = groups;
      _isLoadingGroups = false;
    });
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
    );
    if (!mounted) return;

    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final success = await widget.controller.createTask(
      containerId: widget.containerId,
      title: _titleController.text,
      description: _descriptionController.text,
      status: _status,
      deadline: _deadline?.toIso8601String(),
      attachment: _attachmentController.text.trim(),
      groupIds: _selectedGroupIds,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deadlineLabel = _deadline == null
        ? 'Keine Frist ausgewählt'
        : '${_deadline!.day.toString().padLeft(2, '0')}.'
              '${_deadline!.month.toString().padLeft(2, '0')}.'
              '${_deadline!.year} '
              '${_deadline!.hour.toString().padLeft(2, '0')}:'
              '${_deadline!.minute.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: const Text('Neue Aufgabe'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Titel'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bitte einen Titel angeben.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Beschreibung'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: _statusOptions.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Gruppen-Zuweisung',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                if (_isLoadingGroups)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_allGroups.isEmpty)
                  const Text('Keine Gruppen vorhanden.')
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: _allGroups.map((group) {
                      return FilterChip(
                        label: Text(group.name),
                        selected: _selectedGroupIds.contains(group.id),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedGroupIds.add(group.id);
                            } else {
                              _selectedGroupIds.remove(group.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: Text(deadlineLabel)),
                    TextButton.icon(
                      onPressed: _pickDeadline,
                      icon: const Icon(Icons.event),
                      label: const Text('Frist wählen'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _attachmentController,
                  decoration: const InputDecoration(
                    labelText: 'Anhang (URL/Dateiname, optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Erstellen'),
        ),
      ],
    );
  }
}
