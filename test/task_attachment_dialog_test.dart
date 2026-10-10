import 'dart:typed_data';

import 'package:bienenplan_frontend/core/api/api_exception.dart';
import 'package:bienenplan_frontend/features/subtasks/data/subtask_model.dart';
import 'package:bienenplan_frontend/features/subtasks/data/subtask_repository.dart';
import 'package:bienenplan_frontend/features/tasks/application/task_controller.dart';
import 'package:bienenplan_frontend/features/tasks/data/group_model.dart';
import 'package:bienenplan_frontend/features/tasks/data/group_repository.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_attachment.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_attachment_repository.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_model.dart';
import 'package:bienenplan_frontend/features/tasks/presentation/task_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'controllers_test.dart' show FakeTaskRepository, FakeContainerRepository;

final _bytes = Uint8List.fromList('Gruppendatei'.codeUnits);

final class _File extends PlatformFile {
  @override
  String get name => 'Team.txt';
  @override
  Uri get uri => Uri.parse('memory:Team.txt');
  @override
  Never get xFile => throw StateError('Nicht verwendet');
  @override
  int lengthSync() => _bytes.length;
  @override
  Future<int> length() async => _bytes.length;
  @override
  Future<Uint8List> readAsBytes() async => _bytes;
  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(_bytes);
}

class _Picker extends FilePickerPlatform {
  Uint8List? saved;
  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => [_File()];

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    expect(fileName, 'Team.txt');
    saved = bytes;
    return Uri.parse('memory:Team.txt');
  }
}

class _Tasks extends FakeTaskRepository {
  int updates = 0;
  int creates = 0;
  bool denyEdit = true;
  final task = Task(
    id: 7,
    containerId: 10,
    projectId: 1,
    createdBy: 2,
    title: 'Aufgabe',
    description: 'Alte Beschreibung',
    status: 'open',
    createdAt: '',
    updatedAt: '',
    containerTitle: 'Container',
    creatorName: 'Owner',
  );

  @override
  Future<void> updateTask(
    int taskId, {
    required String title,
    String description = '',
    String status = 'open',
    String? deadline,
    String? attachment,
  }) async {
    updates++;
    if (denyEdit) {
      throw const ApiException(
        statusCode: 403,
        message: 'Keine Berechtigung zum Bearbeiten',
      );
    }
  }

  @override
  Future<int> createTask({
    required int containerId,
    required String title,
    String description = '',
    String status = 'open',
    String? deadline,
    String? attachment,
  }) async {
    creates++;
    return 7;
  }
}

class _Attachments extends TaskAttachmentRepository {
  bool fail = false;
  int uploads = 0;
  int downloads = 0;
  final items = <TaskAttachment>[];
  @override
  Future<List<TaskAttachment>> list(int taskId) async => List.of(items);
  @override
  Future<List<TaskAttachment>> upload(
    int taskId,
    List<({String name, Uint8List bytes})> files,
  ) async {
    uploads++;
    if (fail) {
      throw const ApiException(
        statusCode: 503,
        message: 'Upload fehlgeschlagen',
      );
    }
    expect(taskId, 7);
    expect(files.single.bytes, _bytes);
    final item = TaskAttachment(
      id: 1,
      originalName: files.single.name,
      sizeBytes: _bytes.length,
      canDelete: false,
    );
    items.add(item);
    return [item];
  }

  @override
  Future<Uint8List> download(int taskId, int attachmentId) async {
    downloads++;
    expect(taskId, 7);
    expect(attachmentId, 1);
    return _bytes;
  }
}

class _Groups implements GroupRepositoryContract {
  @override
  Future<List<Group>> fetchGroupsForProject(int projectId) async => [];
  @override
  Future<List<Group>> fetchGroupsForTask(int taskId) async => [];
  @override
  Future<void> assignGroupToTask(int taskId, int groupId) async {}
  @override
  Future<void> removeGroupFromTask(int taskId, int groupId) async {}
}

class _Subtasks extends SubtaskRepository {
  @override
  Future<SubtaskList> list(int taskId) async =>
      SubtaskList(items: const [], canCreate: false);
}

void main() {
  late _Tasks tasks;
  late _Attachments attachments;
  late _Picker picker;
  late TaskController controller;

  setUp(() {
    tasks = _Tasks();
    attachments = _Attachments();
    picker = _Picker();
    final originalPicker = FilePickerPlatform.instance;
    FilePickerPlatform.instance = picker;
    addTearDown(() => FilePickerPlatform.instance = originalPicker);
    controller = TaskController(
      taskRepository: tasks,
      containerRepository: FakeContainerRepository(),
      groupRepository: _Groups(),
      attachmentRepository: attachments,
    );
    addTearDown(controller.dispose);
  });

  Future<void> open(WidgetTester tester, {bool create = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showTaskDialog(
                context,
                controller: controller,
                containerId: 10,
                projectId: 1,
                task: create ? null : tasks.task,
                subtaskRepository: _Subtasks(),
              ),
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
  }

  Future<void> upload(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Dateien hinzufügen'));
    await tester.tap(find.text('Dateien hinzufügen'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'assigned member uploads, downloads and saves without task edit',
    (tester) async {
      await open(tester);
      await upload(tester);
      expect(attachments.uploads, 1);
      expect(tasks.updates, 0);
      expect(find.text('Team.txt'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Herunterladen'));
      await tester.tap(find.byTooltip('Herunterladen'));
      await tester.pumpAndSettle();
      expect(attachments.downloads, 1);
      expect(picker.saved, _bytes);
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(tasks.updates, 0);
      expect(find.text('Keine Berechtigung zum Bearbeiten'), findsNothing);
      expect(find.text('Aufgabe bearbeiten'), findsNothing);
    },
  );

  testWidgets('upload retry does not send a task update', (tester) async {
    attachments.fail = true;
    await open(tester);
    await upload(tester);
    expect(find.text('Upload fehlgeschlagen'), findsOneWidget);
    attachments.fail = false;
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(attachments.uploads, 2);
    expect(tasks.updates, 0);
    expect(find.text('Aufgabe bearbeiten'), findsNothing);
  });

  testWidgets('unchanged legacy description does not cause implicit edit', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(tasks.updates, 0);
    expect(find.text('Aufgabe bearbeiten'), findsNothing);
  });

  testWidgets('actual field changes still respect task edit permission', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Geändert');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(tasks.updates, 1);
    expect(find.text('Keine Berechtigung zum Bearbeiten'), findsOneWidget);
    expect(find.text('Aufgabe bearbeiten'), findsOneWidget);
  });

  testWidgets(
    'upload retry after successful edit does not repeat task update',
    (tester) async {
      tasks.denyEdit = false;
      attachments.fail = true;
      await open(tester);
      await tester.enterText(find.byType(TextFormField).first, 'Geändert');
      await upload(tester);
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(tasks.updates, 1);
      attachments.fail = false;
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(tasks.updates, 1);
      expect(find.text('Aufgabe bearbeiten'), findsNothing);
    },
  );

  testWidgets('upload retry after creation does not recreate or edit task', (
    tester,
  ) async {
    attachments.fail = true;
    await open(tester, create: true);
    await tester.enterText(find.byType(TextFormField).first, 'Neue Aufgabe');
    await upload(tester);
    await tester.tap(find.text('Erstellen'));
    await tester.pumpAndSettle();
    expect(tasks.creates, 1);
    expect(tasks.updates, 0);
    attachments.fail = false;
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(tasks.creates, 1);
    expect(tasks.updates, 0);
    expect(find.text('Neue Aufgabe'), findsNothing);
  });
}
