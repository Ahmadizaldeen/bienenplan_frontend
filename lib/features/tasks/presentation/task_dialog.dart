import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../application/task_controller.dart';
import '../data/group_model.dart';
import '../data/task_model.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/files/file_validation_service.dart';
import '../../../core/theme/app_theme.dart';
import 'create_group_dialog.dart';

/// Zeigt dieselbe Aufgabenmaske zum Erstellen und Bearbeiten.
/// Gibt `true` zurück, wenn die Aufgabe erstellt oder geändert wurde.
Future<bool> showTaskDialog(
  BuildContext context, {
  required TaskController controller,
  required int containerId,
  Task? task,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _TaskDialog(
      controller: controller,
      containerId: containerId,
      task: task,
    ),
  );
  return result ?? false;
}

class _TaskDialog extends StatefulWidget {
  const _TaskDialog({
    required this.controller,
    required this.containerId,
    this.task,
  });

  final TaskController controller;
  final int containerId;
  final Task? task;

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  static const _statusOptions = {
    'open': 'Offen',
    'in_progress': 'In Bearbeitung',
    'done': 'Erledigt',
  };
  static const _allowedExtensions = {
    'pdf',
    'txt',
    'png',
    'jpg',
    'jpeg',
    'gif',
    'docx',
    'xlsx',
  };

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _attachmentController;
  late String _status;
  DateTime? _deadline;

  bool _isLoadingGroups = true;
  bool _isCreatingGroup = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isUploading = false;
  bool _changed = false;
  String? _error;
  String? _groupNotice;
  List<Group> _allGroups = const [];
  late final Set<int> _assignedGroupIds;
  int? _createdTaskId;
  Uint8List? _queuedFileBytes;
  String? _queuedFileName;

  bool get _isEditing => widget.task != null;
  int? get _taskId => widget.task?.id ?? _createdTaskId;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _attachmentController = TextEditingController(text: task?.attachment ?? '');
    _status = _statusOptions.containsKey(task?.status) ? task!.status : 'open';
    _deadline = task?.deadlineDateTime;
    _assignedGroupIds = task?.groupIds.toSet() ?? {};
    _loadGroups();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    final allGroups = await widget.controller.fetchAllGroups();
    final task = widget.task;
    final assigned = task == null
        ? const <Group>[]
        : await widget.controller.fetchGroupsForTask(task.id);
    if (!mounted) return;
    setState(() {
      _allGroups = allGroups;
      if (task != null) {
        _assignedGroupIds
          ..clear()
          ..addAll(assigned.map((group) => group.id));
      }
      _isLoadingGroups = false;
    });
  }

  Future<void> _toggleGroup(Group group, bool assign) async {
    final taskId = _taskId;
    if (taskId == null) {
      setState(() {
        if (assign) {
          _assignedGroupIds.add(group.id);
        } else {
          _assignedGroupIds.remove(group.id);
        }
      });
      return;
    }

    setState(() {
      if (assign) {
        _assignedGroupIds.add(group.id);
      } else {
        _assignedGroupIds.remove(group.id);
      }
    });

    final success = assign
        ? await widget.controller.assignGroupToTask(taskId, group.id)
        : await widget.controller.removeGroupFromTask(taskId, group.id);

    if (!mounted) return;
    if (success) {
      _changed = true;
    } else {
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

  Future<void> _createAndAssignGroup() async {
    setState(() {
      _isCreatingGroup = true;
      _error = null;
      _groupNotice = null;
    });
    final users = await widget.controller.fetchAllUsers();
    if (!mounted) return;
    if (users == null) {
      setState(() {
        _isCreatingGroup = false;
        _error = widget.controller.errorMessage;
      });
      return;
    }
    setState(() => _isCreatingGroup = false);

    final request = await showDialog<NewGroupRequest>(
      context: context,
      builder: (dialogContext) => CreateGroupDialog(users: users),
    );
    if (request == null || !mounted) return;

    final normalizedName = request.name.toLowerCase();
    Group? existingGroup;
    for (final group in _allGroups) {
      if (group.name.trim().toLowerCase() == normalizedName) {
        existingGroup = group;
        break;
      }
    }

    if (existingGroup != null) {
      if (!_assignedGroupIds.contains(existingGroup.id)) {
        await _toggleGroup(existingGroup, true);
      }
      if (!mounted) return;
      setState(() {
        _groupNotice = 'Die Gruppe existiert bereits und wurde ausgewählt; ihre Mitglieder wurden nicht geändert.';
      });
      return;
    }

    setState(() => _isCreatingGroup = true);
    final group = await widget.controller.createGroup(
      request.name,
      userIds: request.userIds,
    );
    if (!mounted) return;
    if (group == null) {
      setState(() {
        _isCreatingGroup = false;
        _error = widget.controller.errorMessage;
      });
      return;
    }

    setState(() {
      _isCreatingGroup = false;
      _allGroups = [..._allGroups, group]
        ..sort(
          (first, second) =>
              first.label.toLowerCase().compareTo(second.label.toLowerCase()),
        );
    });
    await _toggleGroup(group, true);
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

  Future<void> _pickAndUploadFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions.toList(),
    );
    if (files.isEmpty) return;

    final file = files.single;
    final bytes = await file.readAsBytes();
    if (!mounted) return;

    final validationError = FileValidationService.validate(
      bytes,
      file.name,
      allowedExtensions: _allowedExtensions,
    );
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    final taskId = _taskId;
    if (taskId == null) {
      setState(() {
        _queuedFileBytes = bytes;
        _queuedFileName = file.name;
        _error = null;
      });
      return;
    }

    setState(() {
      _queuedFileBytes = bytes;
      _queuedFileName = file.name;
      _error = null;
    });
    await _uploadQueuedFile(taskId);
  }

  Future<bool> _uploadQueuedFile(int taskId) async {
    final bytes = _queuedFileBytes;
    final fileName = _queuedFileName;
    if (bytes == null || fileName == null) return true;

    setState(() => _isUploading = true);
    final attachment = await widget.controller.uploadTaskAttachment(
      taskId,
      bytes,
      fileName,
    );
    if (!mounted) return false;

    setState(() {
      _isUploading = false;
      if (attachment != null) {
        _attachmentController.text = attachment;
        _queuedFileBytes = null;
        _queuedFileName = null;
        _changed = true;
      } else {
        _error = widget.controller.errorMessage;
      }
    });
    return attachment != null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final taskId = _taskId;
    if (taskId == null) {
      final createdTaskId = await widget.controller.createTaskWithId(
        containerId: widget.containerId,
        title: _titleController.text,
        description: _descriptionController.text,
        status: _status,
        deadline: _deadline?.toIso8601String(),
        attachment: _queuedFileBytes == null
            ? _attachmentController.text.trim()
            : null,
        groupIds: _assignedGroupIds,
      );
      if (!mounted) return;
      if (createdTaskId == null) {
        setState(() {
          _isSaving = false;
          _error = widget.controller.errorMessage;
        });
        return;
      }
      _createdTaskId = createdTaskId;
      _changed = true;
      if (!await _uploadQueuedFile(createdTaskId)) {
        if (mounted) setState(() => _isSaving = false);
        return;
      }
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    final success = await widget.controller.updateTask(
      taskId,
      title: _titleController.text,
      description: _descriptionController.text,
      status: _status,
      deadline: _deadline?.toIso8601String(),
      attachment: _attachmentController.text.trim(),
    );

    if (!mounted) return;
    if (!success) {
      setState(() {
        _isSaving = false;
        _error = widget.controller.errorMessage;
      });
      return;
    }

    if (!await _uploadQueuedFile(taskId)) {
      if (mounted) setState(() => _isSaving = false);
      return;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _deleteTask() async {
    final task = widget.task;
    if (task == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmationContext) => AlertDialog(
        title: const Text('Aufgabe löschen?'),
        content: Text(
          '„${task.title}“ wird gelöscht und ist danach nicht mehr sichtbar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmationContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(confirmationContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
      _error = null;
    });
    final success = await widget.controller.deleteTask(task.id);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isDeleting = false;
      _error = widget.controller.errorMessage;
    });
  }

  String get _deadlineLabel {
    if (_deadline == null) return 'Keine Frist ausgewählt';
    return '${_deadline!.day.toString().padLeft(2, '0')}.'
        '${_deadline!.month.toString().padLeft(2, '0')}.'
        '${_deadline!.year} '
        '${_deadline!.hour.toString().padLeft(2, '0')}:'
        '${_deadline!.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final selectedGroupIds = _assignedGroupIds.toList()..sort();
    final availableGroups = _allGroups
        .where((group) => !_assignedGroupIds.contains(group.id))
        .toList();

    return AlertDialog(
      title: Text(_isEditing ? 'Aufgabe bearbeiten' : 'Neue Aufgabe'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: !_isEditing,
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
                  isExpanded: true,
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
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (availableGroups.isEmpty)
                        Text(
                          _allGroups.isEmpty
                              ? 'Noch keine Gruppen vorhanden.'
                              : 'Alle vorhandenen Gruppen sind ausgewählt.',
                        )
                      else
                        DropdownButtonFormField<Group>(
                          key: ValueKey(selectedGroupIds.join(',')),
                          initialValue: null,
                          isExpanded: true,
                          hint: const Text('Gruppe auswählen'),
                          items: availableGroups
                              .map(
                                (group) => DropdownMenuItem<Group>(
                                  value: group,
                                  child: Text(
                                    group.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (group) {
                            if (group != null) _toggleGroup(group, true);
                          },
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _isSaving || _isCreatingGroup
                              ? null
                              : _createAndAssignGroup,
                          icon: _isCreatingGroup
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: const Text('Neue Gruppe'),
                        ),
                      ),
                      if (_assignedGroupIds.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: AppSpacing.xs),
                          child: Text('Keine Gruppen ausgewählt.'),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: _allGroups
                                .where(
                                  (group) =>
                                      _assignedGroupIds.contains(group.id),
                                )
                                .map(
                                  (group) => InputChip(
                                    label: Text(group.label),
                                    onDeleted: _isSaving
                                        ? null
                                        : () => _toggleGroup(group, false),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      if (_groupNotice != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            _groupNotice!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final controls = [
                      TextButton.icon(
                        onPressed: _isSaving ? null : _pickDeadline,
                        icon: const Icon(Icons.event),
                        label: const Text('Frist wählen'),
                      ),
                      if (_deadline != null)
                        IconButton(
                          tooltip: 'Frist entfernen',
                          onPressed: _isSaving
                              ? null
                              : () => setState(() => _deadline = null),
                          icon: const Icon(Icons.clear),
                        ),
                    ];
                    if (constraints.maxWidth < 350) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_deadlineLabel),
                          Wrap(children: controls),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: Text(_deadlineLabel)),
                        ...controls,
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Anhang', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _attachmentController,
                  decoration: const InputDecoration(
                    labelText: 'Anhang (URL/Dateiname, optional)',
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _attachmentController,
                  builder: (context, value, child) {
                    final attachment = value.text.trim();
                    if (attachment.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        ApiEndpoints.attachmentUrl(attachment),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.mutedBlack),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _isUploading || _isSaving
                        ? null
                        : _pickAndUploadFile,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(
                      _queuedFileName == null
                          ? 'Datei hochladen'
                          : 'Ausgewählt: $_queuedFileName',
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (_isEditing)
          TextButton.icon(
            onPressed: _isSaving || _isUploading || _isDeleting
                ? null
                : _deleteTask,
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            label: const Text('Löschen'),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          ),
        TextButton(
          onPressed: _isSaving || _isUploading || _isDeleting
              ? null
              : () =>
                    Navigator.of(context)
                        .pop(_changed || _createdTaskId != null),
          child: Text(_isEditing ? 'Schließen' : 'Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isSaving || _isUploading || _isDeleting ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _isEditing || _createdTaskId != null
                      ? 'Speichern'
                      : 'Erstellen',
                ),
        ),
      ],
    );
  }
}
