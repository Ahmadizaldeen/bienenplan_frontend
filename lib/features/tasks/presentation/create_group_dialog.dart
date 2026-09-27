import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../user/data/user_model.dart';

class NewGroupRequest {
  const NewGroupRequest({required this.name, required this.userIds});

  final String name;
  final List<int> userIds;
}

class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key, required this.users});

  final List<GroupUser> users;

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final Set<int> _selectedUserIds = {};
  String _name = '';
  String? _selectionError;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedUserIds.isEmpty) {
      setState(
        () => _selectionError = 'Bitte mindestens einen Benutzer auswählen.',
      );
      return;
    }
    _formKey.currentState?.save();
    Navigator.of(context).pop(
      NewGroupRequest(name: _name, userIds: _selectedUserIds.toList()..sort()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neue Gruppe erstellen'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  autofocus: true,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Gruppenname'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bitte einen Gruppennamen eingeben.';
                    }
                    return null;
                  },
                  onSaved: (value) => _name = value?.trim() ?? '',
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Benutzer auswählen',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                if (widget.users.isEmpty)
                  const Text('Keine Benutzer verfügbar.')
                else
                  SizedBox(
                    height: 240,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.users.length,
                      itemBuilder: (context, index) {
                        final user = widget.users[index];
                        return CheckboxListTile(
                          value: _selectedUserIds.contains(user.id),
                          title: Text(user.name),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (selected) {
                            setState(() {
                              if (selected ?? false) {
                                _selectedUserIds.add(user.id);
                              } else {
                                _selectedUserIds.remove(user.id);
                              }
                              _selectionError = null;
                            });
                          },
                        );
                      },
                    ),
                  ),
                if (_selectionError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _selectionError!,
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Gruppe erstellen'),
        ),
      ],
    );
  }
}
