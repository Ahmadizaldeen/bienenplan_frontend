import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../application/project_controller.dart';
import '../data/project_model.dart';
import 'project_editor_dialog.dart';

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

  Future<void> _showProjectEditor(Project? project) async {
    final result = await showDialog<ProjectEditorResult>(
      context: context,
      builder: (context) =>
          ProjectEditorDialog(controller: _controller, project: project),
    );
    if (result != null && mounted) {
      final refreshFailed =
          result == ProjectEditorResult.savedRefreshFailed ||
          result == ProjectEditorResult.archivedRefreshFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (result) {
            ProjectEditorResult.saved =>
              project == null ? 'Projekt erstellt.' : 'Projekt gespeichert.',
            ProjectEditorResult.archived => 'Projekt archiviert.',
            ProjectEditorResult.savedRefreshFailed =>
              'Projekt gespeichert, aber die Projektliste konnte nicht aktualisiert werden: ${_controller.errorMessage}',
            ProjectEditorResult.archivedRefreshFailed =>
              'Projekt archiviert, aber die Projektliste konnte nicht aktualisiert werden: ${_controller.errorMessage}',
          }),
          action: refreshFailed
              ? SnackBarAction(
                  label: 'Neu laden',
                  onPressed: _controller.loadProjects,
                )
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: scheme.outlineVariant, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_controller.errorMessage != null) ...[
                GlassContainer(child: Text(_controller.errorMessage!)),
                TextButton(
                  onPressed: _controller.isLoading
                      ? null
                      : _controller.loadProjects,
                  child: const Text('Projektliste erneut laden'),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (_controller.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              for (final project in _controller.projects)
                _ProjectTile(
                  project: project,
                  active: project.id == _controller.selectedProject?.id,
                  onSelect: () => _controller.selectProject(project.id),
                  onEditProject:
                      project.canEdit ||
                          project.canDelete ||
                          project.canManageGroups
                      ? () => _showProjectEditor(project)
                      : null,
                ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _controller.isLoading
                      ? null
                      : () => _showProjectEditor(null),
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
  const _ProjectTile({
    required this.project,
    required this.active,
    required this.onSelect,
    required this.onEditProject,
  });

  final Project project;
  final bool active;
  final VoidCallback onSelect;
  final VoidCallback? onEditProject;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: active ? scheme.primaryContainer : scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: active ? scheme.primary : scheme.outlineVariant,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? scheme.primary : scheme.outline,
                  width: 2,
                ),
                color: active ? scheme.primary : Colors.transparent,
              ),
              child: active
                  ? Icon(Icons.check, size: 12, color: scheme.onPrimary)
                  : null,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                project.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
            ),
            if (active)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: scheme.primary,
              ),
            if (onEditProject != null)
              IconButton(
                tooltip: 'Projekt bearbeiten',
                onPressed: onEditProject,
                icon: const Icon(Icons.settings_outlined),
              ),
          ],
        ),
      ),
    );
  }
}
