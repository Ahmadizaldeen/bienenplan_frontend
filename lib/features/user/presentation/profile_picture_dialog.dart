import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../application/profile_image_validator.dart';
import '../application/user_controller.dart';
import 'profile_avatar.dart';

/// Öffnet die Dateiauswahl und Upload-Oberfläche für das Profilbild.
Future<void> showProfilePictureDialog(
  BuildContext context, {
  required UserController controller,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ProfilePictureDialog(controller: controller),
  );
}

class _ProfilePictureDialog extends StatefulWidget {
  const _ProfilePictureDialog({required this.controller});

  final UserController controller;

  @override
  State<_ProfilePictureDialog> createState() => _ProfilePictureDialogState();
}

class _ProfilePictureDialogState extends State<_ProfilePictureDialog> {
  Uint8List? _selectedBytes;
  String? _selectedFilename;
  String? _error;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    // Die Picker-Einschränkung ist nur die erste Schutzschicht; anschließend
    // werden Dateiendung und binäre Signatur unabhängig geprüft.
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (files.isEmpty) return;

    final file = files.single;
    final bytes = await file.readAsBytes();
    final error = ProfileImageValidator.validate(bytes, file.name);
    if (!mounted) return;

    setState(() {
      _error = error;
      _selectedBytes = error == null ? bytes : null;
      _selectedFilename = error == null ? file.name : null;
    });
  }

  Future<void> _upload() async {
    final bytes = _selectedBytes;
    final filename = _selectedFilename;
    if (bytes == null || filename == null) return;

    setState(() {
      _isUploading = true;
      _error = null;
    });
    // Netzwerk- und Zustandslogik bleibt im injizierten Controller.
    final success = await widget.controller.uploadProfilePicture(
      bytes,
      filename,
    );
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isUploading = false;
      _error = widget.controller.errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Profilbild ändern'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedBytes != null)
              ClipOval(
                child: Image.memory(
                  _selectedBytes!,
                  width: 112,
                  height: 112,
                  fit: BoxFit.cover,
                ),
              )
            else
              ProfileAvatar(user: widget.controller.currentUser, size: 112),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Bild auswählen'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: _selectedBytes == null || _isUploading ? null : _upload,
          icon: _isUploading
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload),
          label: Text(_isUploading ? 'Wird hochgeladen' : 'Hochladen'),
        ),
      ],
    );
  }
}
