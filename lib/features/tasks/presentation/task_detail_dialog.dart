import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../application/task_controller.dart';
import '../data/group_model.dart';
import '../data/task_model.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';

/// Zeigt die Detailansicht einer Aufgabe als Dialog. Erlaubt das Bearbeiten
/// von Titel, Beschreibung, Status, Gruppen-Zuweisung und Datei-Anhang.
/// Gibt `true` zurück, wenn Änderungen gespeichert wurden (damit die
/// aufrufende Liste neu geladen werden kann).
Future<bool> showTaskDetailDialog(
  BuildContext context, {
  required TaskController controller,
  required Task task,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) =>
        _TaskDetailDialog(controller: controller, task: task),
  );
  return result ?? false;
}

class _TaskDetailDialog extends StatefulWidget {
  const _TaskDetailDialog({required this.controller, required this.task});

  final TaskController controller;
  final Task task;

  @override
  State<_TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends State<_TaskDetailDialog> {
  static const _statusOptions = {
    'pending': 'Offen',
    'in_progress': 'In Bearbeitung',
    'done': 'Erledigt',
  };

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _status;
  String? _attachment;

  bool _isLoadingGroups = true;
  bool _isSaving = false;
  bool _isUploading = false;
  bool _changed = false;
  String? _error;

  List<Group> _allGroups = const [];
  Set<int> _assignedGroupIds = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    // "open" ist der Backend-Default für neu erstellte Tasks, wird aber im
    // Dropdown als "pending"/Offen geführt; unbekannte Werte auf "pending"
    // abbilden, damit die Auswahl nie einen ungültigen Wert enthält.
    _status = _statusOptions.containsKey(widget.task.status)
        ? widget.task.status
        : 'pending';
    _attachment = widget.task.attachment;
    _assignedGroupIds = widget.task.groupIds.toSet();
    _loadGroups();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    final allGroups = await widget.controller.fetchAllGroups();
    final assigned = await widget.controller.fetchGroupsForTask(widget.task.id);
    if (!mounted) return;
    setState(() {
      _allGroups = allGroups;
      _assignedGroupIds = assigned.map((g) => g.id).toSet();
      _isLoadingGroups = false;
    });
  }

  Future<void> _toggleGroup(Group group, bool assign) async {
    setState(() {
      if (assign) {
        _assignedGroupIds.add(group.id);
      } else {
        _assignedGroupIds.remove(group.id);
      }
    });

    final success = assign
        ? await widget.controller.assignGroupToTask(widget.task.id, group.id)
        : await widget.controller.removeGroupFromTask(widget.task.id, group.id);

    if (!mounted) return;

    if (success) {
      _changed = true;
    } else {
      // Bei Fehler den ursprünglichen Zustand wiederherstellen.
      setState(() {
        if (assign) {
          _assignedGroupIds.remove(group.id);
        } else {
          _assignedGroupIds.add(group.id);
        }
        _error = widget.controller.errorMessage;
      });
    }
  }

  Future<void> _pickAndUploadFile() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return;

    final file = files.single;
    if (!mounted) return;

    setState(() => _isUploading = true);

    final bytes = await file.readAsBytes();

    if (!mounted) return;

    final attachment = await widget.controller.uploadTaskAttachment(
      widget.task.id,
      bytes,
      file.name,
    );

    if (!mounted) return;
    setState(() {
      _isUploading = false;
      if (attachment != null) {
        _attachment = attachment;
        _changed = true;
      } else {
        _error = widget.controller.errorMessage;
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final success = await widget.controller.updateTask(
      widget.task.id,
      title: _titleController.text,
      description: _descriptionController.text,
      status: _status,
      deadline: widget.task.deadline,
      attachment: _attachment,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = widget.controller.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aufgabendetails'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titel'),
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
                    final isAssigned = _assignedGroupIds.contains(group.id);
                    return FilterChip(
                      label: Text(group.name),
                      selected: isAssigned,
                      onSelected: (selected) => _toggleGroup(group, selected),
                    );
                  }).toList(),
                ),
              const SizedBox(height: AppSpacing.md),
              Text('Anhang', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _attachment == null || _attachment!.isEmpty
                          ? 'Kein Anhang vorhanden.'
                          : _attachment!.split('/').last,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isUploading ? null : _pickAndUploadFile,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: const Text('Datei hochladen'),
                  ),
                ],
              ),
              if (_attachment != null && _attachment!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    ApiEndpoints.attachmentUrl(_attachment!),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.mutedBlack),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () => Navigator.of(context).pop(_changed),
          child: const Text('Schließen'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Speichern'),
        ),
      ],
    );
  }
}
