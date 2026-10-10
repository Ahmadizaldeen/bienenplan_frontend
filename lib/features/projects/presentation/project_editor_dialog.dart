import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../application/project_controller.dart';
import '../data/project_model.dart';
import 'project_groups_dialog.dart';

enum ProjectEditorResult {
  saved,
  archived,
  savedRefreshFailed,
  archivedRefreshFailed,
}

class ProjectEditorDialog extends StatefulWidget {
  const ProjectEditorDialog({
    super.key,
    required this.controller,
    this.project,
  });

  final ProjectController controller;
  final Project? project;

  @override
  State<ProjectEditorDialog> createState() => _ProjectEditorDialogState();
}

class _ProjectEditorDialogState extends State<ProjectEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || (_isEditing && !widget.project!.canEdit)) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final project = widget.project;
    final result = project == null
        ? await widget.controller.createProject(_nameController.text)
        : await widget.controller.updateProject(
            project.id,
            _nameController.text,
          );
    if (!mounted) return;
    if (result != ProjectMutationResult.failed) {
      Navigator.of(context).pop(
        result == ProjectMutationResult.refreshFailed
            ? ProjectEditorResult.savedRefreshFailed
            : ProjectEditorResult.saved,
      );
    } else {
      setState(() {
        _isSaving = false;
        _error = widget.controller.errorMessage;
      });
    }
  }

  Future<void> _archiveProject() async {
    final project = widget.project;
    if (_isSaving || project == null || !project.canDelete) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Projekt archivieren?'),
        content: Text(
          '„${project.name}“ wird aus der aktiven Projektliste entfernt. '
          'Projekt und Daten bleiben für spätere Statistiken erhalten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archivieren'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });
    final result = await widget.controller.archiveProject(project.id);
    if (!mounted) return;
    if (result != ProjectMutationResult.failed) {
      Navigator.of(context).pop(
        result == ProjectMutationResult.refreshFailed
            ? ProjectEditorResult.archivedRefreshFailed
            : ProjectEditorResult.archived,
      );
    } else {
      setState(() {
        _isSaving = false;
        _error = widget.controller.errorMessage;
      });
    }
  }

  Future<void> _manageGroups() async {
    final project = widget.project;
    if (project == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) =>
          ProjectGroupsDialog(project: project, controller: widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Projekt bearbeiten' : 'Neues Projekt'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !_isSaving && (!_isEditing || widget.project!.canEdit),
                autofocus: true,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Projektname'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Bitte geben Sie einen Projektnamen ein.'
                    : null,
                onFieldSubmitted: (_) => _save(),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_isEditing && widget.project!.canManageGroups) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _manageGroups,
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Projektgruppen verwalten'),
                ),
              ],
              if (_isEditing && widget.project!.canDelete)
                TextButton.icon(
                  onPressed: _isSaving ? null : _archiveProject,
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Projekt archivieren'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: _isSaving || (_isEditing && !widget.project!.canEdit)
              ? null
              : _save,
          icon: _isSaving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_isEditing ? 'Speichern' : 'Erstellen'),
        ),
      ],
    );
  }
}
