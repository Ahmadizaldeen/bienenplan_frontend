import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../application/project_controller.dart';
import '../data/project_group_model.dart';
import '../data/project_model.dart';
import '../../user/data/user_model.dart';

class ProjectGroupsDialog extends StatefulWidget {
  const ProjectGroupsDialog({
    super.key,
    required this.project,
    required this.controller,
  });

  final Project project;
  final ProjectController controller;

  @override
  State<ProjectGroupsDialog> createState() => _ProjectGroupsDialogState();
}

class _ProjectGroupsDialogState extends State<ProjectGroupsDialog> {
  List<ProjectGroup> _groups = const [];
  Set<int> _assignedIds = {};
  int? _busyGroupId;
  bool _isLoading = true;
  bool _loadFailed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.controller.fetchProjectGroups(widget.project.id),
        widget.controller.fetchAvailableGroups(widget.project.id),
      ]);
      if (!mounted) return;
      setState(() {
        _assignedIds = results[0].map((group) => group.id).toSet();
        _groups = results[1];
        _loadFailed = false;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loadFailed = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _setAssigned(ProjectGroup group, bool assigned) async {
    if (_busyGroupId != null || _isLoading || _loadFailed) return;
    setState(() {
      _busyGroupId = group.id;
      _error = null;
    });
    final success = await widget.controller.setProjectGroup(
      widget.project.id,
      group.id,
      assigned,
    );
    if (!mounted) return;
    setState(() {
      _busyGroupId = null;
      if (success) {
        if (assigned) {
          _assignedIds.add(group.id);
        } else {
          _assignedIds.remove(group.id);
        }
      } else {
        _error = widget.controller.errorMessage;
      }
    });
  }

  Future<void> _createGroup() => _openGroupEditor();

  Future<void> _openGroupEditor([ProjectGroup? group]) async {
    if (_isLoading ||
        _busyGroupId != null ||
        _loadFailed ||
        !widget.project.canManageGroups) {
      return;
    }
    setState(() {
      _error = null;
      _isLoading = true;
    });
    final List<GroupUser> users;
    final List<GroupUser> members;
    try {
      final results = await Future.wait([
        widget.controller.fetchUsers(),
        if (group != null) widget.controller.fetchGroupUsers(group.id),
      ]);
      users = results[0];
      members = group == null ? const [] : results[1];
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (users.isEmpty) {
      setState(() => _error = 'Keine Benutzer verfügbar.');
      return;
    }

    final request = await showDialog<_ProjectGroupRequest>(
      context: context,
      builder: (context) => _ProjectGroupEditorDialog(
        users: users,
        group: group,
        userIds: members.map((user) => user.id).toSet(),
      ),
    );
    if (request == null || !mounted) return;

    setState(() => _isLoading = true);
    final success = group == null
        ? await widget.controller.createProjectGroup(
            widget.project.id,
            request.name,
            request.userIds,
          )
        : await widget.controller.updateProjectGroup(
            widget.project.id,
            group.id,
            request.name,
            request.userIds,
          );
    if (!mounted) return;
    if (!success) {
      setState(() {
        _isLoading = false;
        _error = widget.controller.errorMessage;
      });
      return;
    }
    await _loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text('Projektgruppen: ${widget.project.name}'),
      content: SizedBox(
        width: 420,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed:
                          _busyGroupId == null &&
                              !_loadFailed &&
                              widget.project.canManageGroups
                          ? _createGroup
                          : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Neue lokale Gruppe'),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (_loadFailed)
                    TextButton(
                      onPressed: _loadGroups,
                      child: const Text('Erneut versuchen'),
                    ),
                  if (_groups.isEmpty && !_loadFailed)
                    const Text('Es sind keine Gruppen vorhanden.')
                  else if (_groups.isNotEmpty)
                    SizedBox(
                      height: 320,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          final isBusy = _busyGroupId == group.id;
                          final scope = group.isGlobal
                              ? 'Global'
                              : 'Nur dieses Projekt';
                          final count = group.memberCount;
                          final membersLabel = count == 1
                              ? 'Ein Teilnehmer: Aufgabe, Beschreibung und Frist bearbeitbar'
                              : '$count Teilnehmer';
                          return CheckboxListTile(
                            value: _assignedIds.contains(group.id),
                            title: Text(group.name),
                            subtitle: Text(
                              count == null ? scope : '$scope\n$membersLabel',
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            secondary: isBusy
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : !group.isGlobal &&
                                      group.projectId == widget.project.id &&
                                      widget.project.canManageGroups
                                ? IconButton(
                                    tooltip: 'Gruppe bearbeiten',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed:
                                        _busyGroupId != null || _loadFailed
                                        ? null
                                        : () => _openGroupEditor(group),
                                  )
                                : null,
                            onChanged:
                                _busyGroupId != null ||
                                    _loadFailed ||
                                    !widget.project.canManageGroups
                                ? null
                                : (value) =>
                                      _setAssigned(group, value ?? false),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schließen'),
        ),
      ],
    );
  }
}

class _ProjectGroupRequest {
  const _ProjectGroupRequest({required this.name, required this.userIds});

  final String name;
  final List<int> userIds;
}

class _ProjectGroupEditorDialog extends StatefulWidget {
  const _ProjectGroupEditorDialog({
    required this.users,
    this.group,
    this.userIds = const {},
  });

  final List<GroupUser> users;
  final ProjectGroup? group;
  final Set<int> userIds;

  @override
  State<_ProjectGroupEditorDialog> createState() =>
      _ProjectGroupEditorDialogState();
}

class _ProjectGroupEditorDialogState extends State<_ProjectGroupEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final Set<int> _userIds;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    _userIds = widget.userIds.intersection(
      widget.users.map((user) => user.id).toSet(),
    );
    if (_userIds.length != widget.userIds.length) {
      _error =
          'Einige Mitglieder sind nicht mehr verfügbar. Bitte Auswahl prüfen.';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? get _rightsWarning {
    final oldIds = widget.userIds;
    final changes =
        widget.group != null &&
        _userIds.isNotEmpty &&
        ((oldIds.length == 1) != (_userIds.length == 1) ||
            (oldIds.length == 1 &&
                _userIds.length == 1 &&
                oldIds.single != _userIds.single));
    if (!changes) return null;
    return _userIds.length == 1
        ? 'Diese Änderung gibt dem ausgewählten Benutzer Zusatzrechte bei '
              'zugewiesenen Aufgaben: Inhalte und Frist bearbeiten, lokale Gruppen '
              'zuweisen und Unteraufgaben erstellen. Bisherige Zusatzrechte dieser '
              'Gruppe entfallen für entfernte Mitglieder. Andere Rollen bleiben erhalten.'
        : 'Diese Änderung entzieht die Zusatzrechte dieser Ein-Personen-Gruppe: '
              'Inhalte und Frist bearbeiten, lokale Gruppen zuweisen und Unteraufgaben '
              'erstellen. Rechte aus anderen Rollen oder Zuweisungen bleiben erhalten.';
  }

  void _submit() {
    if (_userIds.isEmpty) {
      setState(() => _error = 'Bitte mindestens einen Benutzer auswählen.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final enteredName = _nameController.text.trim();
    final name = enteredName.isNotEmpty
        ? enteredName
        : widget.users.firstWhere((user) => user.id == _userIds.single).name;
    Navigator.of(
      context,
    ).pop(_ProjectGroupRequest(name: name, userIds: _userIds.toList()..sort()));
  }

  @override
  Widget build(BuildContext context) {
    final rightsWarning = _rightsWarning;
    return AlertDialog(
      scrollable: true,
      title: Text(
        widget.group == null ? 'Neue Gruppe erstellen' : 'Gruppe bearbeiten',
      ),
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
                autofocus: true,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: _userIds.length == 1
                      ? 'Gruppenname (optional)'
                      : 'Gruppenname',
                  helperText: _userIds.length == 1
                      ? 'Ohne Gruppennamen wird der Benutzername verwendet.'
                      : null,
                ),
                validator: (value) =>
                    _userIds.length != 1 &&
                        (value == null || value.trim().isEmpty)
                    ? 'Bitte einen Gruppennamen eingeben.'
                    : null,
              ),
              Text(
                'Benutzer auswählen',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(
                height: 240,
                child: ListView.builder(
                  itemCount: widget.users.length,
                  itemBuilder: (context, index) {
                    final user = widget.users[index];
                    return CheckboxListTile(
                      value: _userIds.contains(user.id),
                      title: Text(user.name),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (selected) => setState(() {
                        if (selected ?? false) {
                          _userIds.add(user.id);
                        } else {
                          _userIds.remove(user.id);
                        }
                        _error = null;
                      }),
                    );
                  },
                ),
              ),
              if (rightsWarning != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(rightsWarning),
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.group == null ? 'Erstellen' : 'Speichern'),
        ),
      ],
    );
  }
}
