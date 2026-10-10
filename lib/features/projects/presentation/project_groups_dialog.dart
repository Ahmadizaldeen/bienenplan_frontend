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

  Future<void> _createGroup() async {
    if (_isLoading || _busyGroupId != null || _loadFailed) return;
    setState(() {
      _error = null;
      _isLoading = true;
    });
    final List<GroupUser> users;
    try {
      users = await widget.controller.fetchUsers();
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

    final request = await showDialog<_NewProjectGroup>(
      context: context,
      builder: (context) => _NewProjectGroupDialog(users: users),
    );
    if (request == null || !mounted) return;

    setState(() => _isLoading = true);
    final success = await widget.controller.createProjectGroup(
      widget.project.id,
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
                      onPressed: _busyGroupId == null && !_loadFailed
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
                          return CheckboxListTile(
                            value: _assignedIds.contains(group.id),
                            title: Text(group.name),
                            subtitle: Text(
                              group.isGlobal ? 'Global' : 'Nur dieses Projekt',
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
                                : null,
                            onChanged: _busyGroupId != null || _loadFailed
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

class _NewProjectGroup {
  const _NewProjectGroup({required this.name, required this.userIds});

  final String name;
  final List<int> userIds;
}

class _NewProjectGroupDialog extends StatefulWidget {
  const _NewProjectGroupDialog({required this.users});

  final List<GroupUser> users;

  @override
  State<_NewProjectGroupDialog> createState() => _NewProjectGroupDialogState();
}

class _NewProjectGroupDialogState extends State<_NewProjectGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Set<int> _userIds = {};
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_userIds.isEmpty) {
      setState(() => _error = 'Bitte mindestens einen Benutzer auswählen.');
      return;
    }
    Navigator.of(context).pop(
      _NewProjectGroup(
        name: _nameController.text.trim(),
        userIds: _userIds.toList()..sort(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Neue Gruppe erstellen'),
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
                decoration: const InputDecoration(labelText: 'Gruppenname'),
                validator: (value) => value == null || value.trim().isEmpty
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
        ElevatedButton(onPressed: _submit, child: const Text('Erstellen')),
      ],
    );
  }
}
