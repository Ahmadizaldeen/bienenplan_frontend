import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../subtasks/data/subtask_model.dart';
import '../../subtasks/data/subtask_repository.dart';
import '../../tasks/data/task_attachment.dart';
import '../../tasks/data/task_attachment_repository.dart';
import '../../tasks/data/task_model.dart';
import '../application/project_archive_controller.dart';
import '../application/project_controller.dart';
import '../data/project_archive_repository.dart';
import '../data/project_model.dart';

class ProjectArchiveScreen extends StatefulWidget {
  ProjectArchiveScreen({
    super.key,
    required this.projectController,
    ProjectArchiveRepository? repository,
    SubtaskRepositoryContract? subtaskRepository,
    TaskAttachmentRepository? attachmentRepository,
  }) : repository = repository ?? ProjectArchiveRepository(),
       subtaskRepository = subtaskRepository ?? SubtaskRepository(),
       attachmentRepository =
           attachmentRepository ?? TaskAttachmentRepository();

  final ProjectController projectController;
  final ProjectArchiveRepository repository;
  final SubtaskRepositoryContract subtaskRepository;
  final TaskAttachmentRepository attachmentRepository;

  @override
  State<ProjectArchiveScreen> createState() => _ProjectArchiveScreenState();
}

class _ProjectArchiveScreenState extends State<ProjectArchiveScreen> {
  late final _controller = ProjectArchiveController(
    repository: widget.repository,
  );
  bool _refreshingActive = false;
  String? _refreshError;

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _restore(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Projekt wiederherstellen?'),
        content: Text(
          '„${project.name}“ wird wieder aktiv. Gelöschte Inhalte und '
          'entfernte Mitgliedschaften werden nicht wiederhergestellt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wiederherstellen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (!await _controller.restore(project) || !mounted) return;
    setState(() {
      _refreshingActive = true;
      _refreshError = null;
    });
    await widget.projectController.loadProjects();
    if (!mounted) return;
    setState(() {
      _refreshingActive = false;
      _refreshError = widget.projectController.errorMessage;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _refreshError == null
              ? 'Projekt wiederhergestellt.'
              : 'Projekt wiederhergestellt, aber die aktive Projektliste konnte nicht aktualisiert werden: $_refreshError',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin · Projektarchiv')),
    body: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final busy =
            _controller.isLoading ||
            _controller.restoringId != null ||
            _refreshingActive;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Archivierte Projekte sind nur lesbar. Zum Bearbeiten zuerst wiederherstellen.',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Archiv aktualisieren',
                onPressed: busy ? null : _controller.load,
                icon: const Icon(Icons.refresh),
              ),
            ),
            if (busy) const LinearProgressIndicator(),
            if (_controller.errorMessage != null)
              Text(
                _controller.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_refreshError != null)
              Text(
                'Aktive Projektliste konnte nicht aktualisiert werden: $_refreshError',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (!busy &&
                _controller.errorMessage == null &&
                _controller.projects.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Keine archivierten Projekte.'),
              ),
            for (final project in _controller.projects)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Chip(
                        label: Text('Archiviert'),
                        avatar: Icon(Icons.archive_outlined),
                      ),
                      Text(
                        'Archiviert am: ${project.archivedAt ?? "Unbekannt"}',
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('Ansehen'),
                            onPressed: busy
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => _ArchivedProjectScreen(
                                        project: project,
                                        repository: widget.repository,
                                        subtasks: widget.subtaskRepository,
                                        attachments:
                                            widget.attachmentRepository,
                                      ),
                                    ),
                                  ),
                          ),
                          if (project.canRestore)
                            FilledButton.icon(
                              icon: const Icon(Icons.unarchive_outlined),
                              label: const Text('Wiederherstellen'),
                              onPressed: busy ? null : () => _restore(project),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

// Eigene Leseansicht statt TaskDialog: Auch vorhandene API-Rechte sollen im
// Archiv keine Bearbeitungsaktionen oder schreibenden Unteraufgaben auslösen.
class _ArchivedProjectScreen extends StatefulWidget {
  const _ArchivedProjectScreen({
    required this.project,
    required this.repository,
    required this.subtasks,
    required this.attachments,
  });

  final Project project;
  final ProjectArchiveRepository repository;
  final SubtaskRepositoryContract subtasks;
  final TaskAttachmentRepository attachments;

  @override
  State<_ArchivedProjectScreen> createState() => _ArchivedProjectScreenState();
}

class _ArchivedProjectScreenState extends State<_ArchivedProjectScreen> {
  late Future<ArchivedProjectContents> _contents;

  @override
  void initState() {
    super.initState();
    _contents = widget.repository.fetchContents(widget.project.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.project.name)),
    body: FutureBuilder<ArchivedProjectContents>(
      future: _contents,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Archiv konnte nicht geladen werden: ${snapshot.error}'),
                TextButton(
                  onPressed: () => setState(() {
                    _contents = widget.repository.fetchContents(
                      widget.project.id,
                    );
                  }),
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          );
        }
        final contents = snapshot.data;
        if (contents == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              child: ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('Archiviert – nur lesen'),
              ),
            ),
            if (contents.containers.isEmpty)
              const Text('Keine Container vorhanden.'),
            for (final container in contents.containers)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        container.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (!contents.tasks.any(
                        (task) => task.containerId == container.id,
                      ))
                        const Text('Keine Aufgaben vorhanden.'),
                      for (final task in contents.tasks.where(
                        (task) => task.containerId == container.id,
                      ))
                        _ArchivedTaskTile(
                          task: task,
                          subtasks: widget.subtasks,
                          attachments: widget.attachments,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _ArchivedTaskTile extends StatefulWidget {
  const _ArchivedTaskTile({
    required this.task,
    required this.subtasks,
    required this.attachments,
  });
  final Task task;
  final SubtaskRepositoryContract subtasks;
  final TaskAttachmentRepository attachments;

  @override
  State<_ArchivedTaskTile> createState() => _ArchivedTaskTileState();
}

class _ArchivedTaskTileState extends State<_ArchivedTaskTile> {
  Future<(SubtaskList, List<TaskAttachment>)>? _details;
  String? _downloadError;
  int? _downloading;

  Future<(SubtaskList, List<TaskAttachment>)> _load() async {
    final subtasks = await widget.subtasks.list(widget.task.id);
    final attachments = await widget.attachments.list(widget.task.id);
    return (subtasks, attachments);
  }

  Future<void> _download(TaskAttachment attachment) async {
    setState(() {
      _downloading = attachment.id;
      _downloadError = null;
    });
    try {
      // Der Repository-Download sendet das JWT; eine direkte URL-Navigation nicht.
      final bytes = await widget.attachments.download(
        widget.task.id,
        attachment.id,
      );
      if (!mounted) return;
      await FilePicker.saveFile(
        fileName: attachment.originalName,
        bytes: bytes,
      );
    } catch (error) {
      if (mounted) setState(() => _downloadError = error.toString());
    } finally {
      if (mounted) setState(() => _downloading = null);
    }
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: Text(widget.task.title),
    subtitle: Text(
      'Status: ${widget.task.status} · ${widget.task.formattedDeadline}',
    ),
    onExpansionChanged: (expanded) {
      if (expanded && _details == null) {
        setState(() {
          _details = _load();
        });
      }
    },
    children: [
      if (widget.task.description.isNotEmpty)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(widget.task.description),
        ),
      if (_details != null)
        FutureBuilder<(SubtaskList, List<TaskAttachment>)>(
          future: _details,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(
                    'Details konnten nicht geladen werden: ${snapshot.error}',
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _details = _load();
                    }),
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              );
            }
            final data = snapshot.data;
            if (data == null) return const CircularProgressIndicator();
            return Column(
              children: [
                for (final subtask in data.$1.items)
                  ListTile(
                    leading: Icon(
                      subtask.completed
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                    ),
                    title: Text(subtask.title),
                  ),
                for (final attachment in data.$2)
                  ListTile(
                    title: Text(attachment.originalName),
                    trailing: IconButton(
                      tooltip: 'Anhang herunterladen',
                      onPressed: _downloading != null
                          ? null
                          : () => _download(attachment),
                      icon: const Icon(Icons.download_outlined),
                    ),
                  ),
                if (data.$1.items.isEmpty && data.$2.isEmpty)
                  const Text('Keine Unteraufgaben oder Anhänge.'),
                if (_downloadError != null)
                  Text(
                    _downloadError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            );
          },
        ),
    ],
  );
}
