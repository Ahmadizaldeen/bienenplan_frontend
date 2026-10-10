import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../application/task_controller.dart';
import '../application/task_text_parser.dart';
import '../data/group_model.dart';
import '../data/task_model.dart';
import '../data/task_attachment.dart';
import '../../../core/files/file_validation_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../subtasks/data/subtask_repository.dart';
import '../../subtasks/presentation/widgets/subtask_section.dart';

/// Zeigt dieselbe Aufgabenmaske zum Erstellen und Bearbeiten.
/// Gibt `true` zurück, wenn die Aufgabe erstellt oder geändert wurde.
Future<bool> showTaskDialog(
  BuildContext context, {
  required TaskController controller,
  required int containerId,
  int? projectId,
  Task? task,
  SubtaskRepositoryContract? subtaskRepository,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _TaskDialog(
      controller: controller,
      containerId: containerId,
      projectId: projectId ?? task?.projectId,
      task: task,
      subtaskRepository: subtaskRepository ?? SubtaskRepository(),
    ),
  );
  return result ?? false;
}

class _TaskDialog extends StatefulWidget {
  const _TaskDialog({
    required this.controller,
    required this.containerId,
    this.projectId,
    this.task,
    required this.subtaskRepository,
  });

  final TaskController controller;
  final int containerId;
  final int? projectId;
  final Task? task;
  final SubtaskRepositoryContract subtaskRepository;

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
  late final TextEditingController _textController;
  late String _status;
  DateTime? _deadline;

  bool _isLoadingGroups = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isUploading = false;
  bool _changed = false;
  bool _subtasksBusy = false;
  String? _error;
  List<Group> _allGroups = const [];
  late final Set<int> _assignedGroupIds;
  int? _createdTaskId;
  List<({String name, Uint8List bytes})> _queuedFiles = [];
  List<TaskAttachment> _attachments = [];

  bool get _isEditing => widget.task != null;
  int? get _taskId => widget.task?.id ?? _createdTaskId;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _textController = TextEditingController(
      text: task == null ? '' : composeTaskText(task.title, task.description),
    );
    _status = _statusOptions.containsKey(task?.status) ? task!.status : 'open';
    _deadline = task?.deadlineDateTime;
    _assignedGroupIds = task?.groupIds.toSet() ?? {};
    _loadGroups();
    if (task != null) _loadAttachments(task.id);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    final projectId = widget.projectId;
    final allGroups = projectId == null
        ? const <Group>[]
        : await widget.controller.fetchGroupsForProject(projectId);
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

    final selected = <({String name, Uint8List bytes})>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final error = FileValidationService.validate(
        bytes,
        file.name,
        allowedExtensions: _allowedExtensions,
      );
      if (error != null) {
        setState(() => _error = '${file.name}: $error');
        return;
      }
      selected.add((name: file.name, bytes: bytes));
    }

    final taskId = _taskId;
    setState(() {
      _queuedFiles.addAll(selected);
      _error = null;
    });
    if (taskId != null) await _uploadQueuedFiles(taskId);
  }

  Future<void> _loadAttachments(int taskId) async {
    try {
      final attachments = await widget.controller.listAttachments(taskId);
      if (!mounted) return;
      setState(() => _attachments = attachments);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<bool> _uploadQueuedFiles(int taskId) async {
    if (_queuedFiles.isEmpty) return true;
    setState(() => _isUploading = true);
    try {
      final uploaded = await widget.controller.uploadAttachments(
        taskId,
        _queuedFiles,
      );
      if (!mounted) return false;
      setState(() {
        _isUploading = false;
        _attachments.addAll(uploaded);
        _queuedFiles = [];
        _changed = true;
      });
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _isUploading = false;
        _error = error.toString();
      });
      return false;
    }
  }

  Future<void> _downloadAttachment(TaskAttachment attachment) async {
    final taskId = _taskId;
    if (taskId == null) return;
    try {
      final bytes = await widget.controller.downloadAttachment(
        taskId,
        attachment.id,
      );
      if (!mounted) return;
      await FilePicker.saveFile(
        fileName: attachment.originalName,
        bytes: bytes,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _deleteAttachment(TaskAttachment attachment) async {
    final taskId = _taskId;
    if (taskId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anhang löschen?'),
        content: Text('„${attachment.originalName}“ löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.controller.deleteAttachment(taskId, attachment.id);
      if (!mounted) return;
      setState(() {
        _attachments.removeWhere((item) => item.id == attachment.id);
        _changed = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final parsed = parseTaskText(_textController.text);
    if (parsed == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final taskId = _taskId;
    if (taskId == null) {
      final createdTaskId = await widget.controller.createTaskWithId(
        containerId: widget.containerId,
        title: parsed.title,
        description: parsed.description ?? '',
        status: _status,
        deadline: _deadline?.toIso8601String(),
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
      if (!await _uploadQueuedFiles(createdTaskId)) {
        if (mounted) setState(() => _isSaving = false);
        return;
      }
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    final success = await widget.controller.updateTask(
      taskId,
      title: parsed.title,
      description: parsed.description ?? '',
      status: _status,
      deadline: _deadline?.toIso8601String(),
    );

    if (!mounted) return;
    if (!success) {
      setState(() {
        _isSaving = false;
        _error = widget.controller.errorMessage;
      });
      return;
    }

    if (!await _uploadQueuedFiles(taskId)) {
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(confirmationContext).colorScheme.error,
              foregroundColor: Theme.of(confirmationContext)
                  .colorScheme
                  .onError,
            ),
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
    bool success;
    Object? deleteError;
    try {
      success = await widget.controller.deleteTask(task.id);
    } catch (error) {
      success = false;
      deleteError = error;
    }
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isDeleting = false);
    final message = deleteError is ApiException
        ? deleteError.message
        : deleteError.toString().replaceFirst('Exception: ', '');
    await showDialog<void>(
      context: context,
      builder: (errorContext) => AlertDialog(
        title: const Text('Löschen nicht möglich'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(errorContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
            // Platz für das schwebende Label, sonst schneidet der Scrollbereich es ab.
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              if (_isEditing) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(
                    widget.task!.creatorName.isEmpty
                        ? 'Unbekannt'
                        : widget.task!.creatorName,
                  ),
                  subtitle: const Text('Erstellt von'),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              TextFormField(
                  controller: _textController,
                  autofocus: !_isEditing,
                  keyboardType: TextInputType.multiline,
                  minLines: 3,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'Aufgabe',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => parseTaskText(value ?? '') == null
                      ? 'Beschreibe die Aufgabe.'
                      : null,
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
                              ? 'Diesem Projekt sind noch keine Gruppen zugeordnet.'
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
                SubtaskSection(
                  taskId: _taskId,
                  repository: widget.subtaskRepository,
                  disabled: _isSaving || _isDeleting || _isUploading,
                  onChanged: () => _changed = true,
                  onBusyChanged: (busy) {
                    if (mounted) setState(() => _subtasksBusy = busy);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Anhänge', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                if (_attachments.isEmpty && _queuedFiles.isEmpty)
                  const Text('Noch keine Dateien hochgeladen'),
                for (final attachment in _attachments)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(
                      attachment.originalName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${(attachment.sizeBytes / 1024).toStringAsFixed(1)} KB',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Herunterladen',
                          onPressed: () => _downloadAttachment(attachment),
                          icon: const Icon(Icons.download),
                        ),
                        if (attachment.canDelete)
                          IconButton(
                            tooltip: 'Anhang löschen',
                            onPressed: _isUploading
                                ? null
                                : () => _deleteAttachment(attachment),
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                  ),
                for (final file in _queuedFiles)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: const Text('Upload ausstehend'),
                    trailing: IconButton(
                      tooltip: 'Auswahl entfernen',
                      onPressed: _isUploading
                          ? null
                          : () => setState(() => _queuedFiles.remove(file)),
                      icon: const Icon(Icons.close),
                    ),
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
                    label: Text('Dateien hinzufügen'),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
            onPressed: _isSaving || _isUploading || _isDeleting || _subtasksBusy
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        TextButton(
          onPressed: _isSaving || _isUploading || _isDeleting || _subtasksBusy
              ? null
              : () =>
                    Navigator.of(context)
                        .pop(_changed || _createdTaskId != null),
          child: Text(_isEditing ? 'Schließen' : 'Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isSaving || _isUploading || _isDeleting || _subtasksBusy
              ? null
              : _submit,
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
