import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../application/project_controller.dart';
import '../data/project_model.dart';

class ProjectListWidget extends StatefulWidget {
  const ProjectListWidget({super.key, this.controller});

  final ProjectController? controller;

  @override
  State<ProjectListWidget> createState() => _ProjectListWidgetState();
}

class _ProjectListWidgetState extends State<ProjectListWidget> {
  late final ProjectController _controller =
      widget.controller ?? ProjectController();

  @override
  void initState() {
    super.initState();
    // Nur selbst initial laden, wenn wir den Controller selbst besitzen.
    // Ein von außen injizierter Controller wurde vom Owner bereits geladen.
    if (widget.controller == null) {
      _controller.loadProjects();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _showCreateProjectDialog() async {
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Neues Projekt'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Projektname',
                hintText: 'z.B. Marketing Q3',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte geben Sie einen Projektnamen ein.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Erstellen'),
            ),
          ],
        );
      },
    );

    if (created == true && mounted) {
      final success = await _controller.createProject(textController.text);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Projekt erfolgreich erstellt!')),
        );
      } else if (_controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
    textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoading && _controller.projects.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_controller.errorMessage != null) ...[
                GlassContainer(child: Text(_controller.errorMessage!)),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (_controller.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              for (final project in _controller.projects)
                _ProjectTile(project: project),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _controller.isLoading
                      ? null
                      : _showCreateProjectDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Projekt hinzufügen'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final active = project.isActive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: active
            ? AppColors.accent.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: active
              ? AppColors.accent
              : Colors.white.withValues(alpha: 0.25),
          width: active ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.circle_outlined,
            color: active ? AppColors.accent : const Color(0xFF5B6A66),
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              project.name,
              style: TextStyle(
                fontSize: 17,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF263A35),
              ),
            ),
          ),
          if (active)
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.accent,
            ),
        ],
      ),
    );
  }
}
