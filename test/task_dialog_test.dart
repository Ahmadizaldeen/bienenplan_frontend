import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bienenplan_frontend/features/tasks/application/task_controller.dart';
import 'package:bienenplan_frontend/features/tasks/data/container_model.dart'
    as task_container;
import 'package:bienenplan_frontend/features/tasks/data/container_repository.dart';
import 'package:bienenplan_frontend/features/tasks/data/group_model.dart';
import 'package:bienenplan_frontend/features/tasks/data/group_repository.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_model.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_repository.dart';
import 'package:bienenplan_frontend/features/tasks/presentation/task_dialog.dart';
import 'package:bienenplan_frontend/core/api/api_endpoints.dart';
import 'package:bienenplan_frontend/core/api/api_exception.dart';
import 'package:bienenplan_frontend/core/api/api_client.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_attachment.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_attachment_repository.dart';
import 'package:bienenplan_frontend/features/subtasks/data/subtask_model.dart';
import 'package:bienenplan_frontend/features/subtasks/data/subtask_repository.dart';

class _FakeGroupRepository implements GroupRepositoryContract {
  @override
  Future<List<Group>> fetchGroupsForProject(int projectId) async {
    expect(projectId, 4);
    return const [
      Group(id: 1, name: 'Gruppe Eins'),
      Group(id: 2, name: 'Gruppe Zwei'),
    ];
  }

  @override
  Future<List<Group>> fetchGroupsForTask(int taskId) async => const [];

  @override
  @override
  Future<void> assignGroupToTask(int taskId, int groupId) async {}

  @override
  Future<void> removeGroupFromTask(int taskId, int groupId) async {}
}

class _TestContainerRepository implements ContainerRepositoryContract {
  @override
  Future<List<task_container.Container>> fetchContainers() async => const [];

  @override
  Future<task_container.Container> createContainer(
    String title, {
    int? projectId,
  }) async =>
      task_container.Container(id: 1, title: title, projectId: projectId);
}

class _LocalGroups extends _FakeGroupRepository {
  bool ownSoloMetadata = false;
  bool secondOwnSolo = false;
  final assigned = <int>[1];
  final added = <int>[];
  final removed = <int>[];
  static const groups = [
    Group(id: 1, name: 'Solo', projectId: 4),
    Group(id: 2, name: 'Lokales Team', projectId: 4),
    Group(id: 3, name: 'Globales Team', isGlobal: true),
  ];
  @override
  Future<List<Group>> fetchGroupsForProject(int projectId) async => [
    if (ownSoloMetadata)
      const Group(
        id: 1,
        name: 'Solo',
        projectId: 4,
        memberCount: 1,
        isCurrentUserMember: true,
      )
    else
      groups[0],
    groups[1],
    groups[2],
    if (secondOwnSolo)
      const Group(
        id: 4,
        name: 'Zweite Solo',
        projectId: 4,
        memberCount: 1,
        isCurrentUserMember: true,
      ),
  ];
  @override
  Future<List<Group>> fetchGroupsForTask(int taskId) async =>
      (await fetchGroupsForProject(4))
          .where((group) => assigned.contains(group.id))
          .toList();
  @override
  Future<void> assignGroupToTask(int taskId, int groupId) async {
    added.add(groupId);
    assigned.add(groupId);
  }

  @override
  Future<void> removeGroupFromTask(int taskId, int groupId) async {
    removed.add(groupId);
    assigned.remove(groupId);
  }
}

class _PermissionAwareTaskRepository implements TaskRepositoryContract {
  String? savedTitle;
  String? savedDeadline;
  String? savedDescription;
  int titleDeadlineWrites = 0;
  ApiException? statusError;
  bool failRefresh = false;
  @override
  Future<void> updateTaskTitleDeadline(
    int taskId,
    String title,
    String? deadline,
  ) async {
    savedTitle = title;
    savedDeadline = deadline;
    titleDeadlineWrites++;
  }

  bool statusCalled = false;
  bool updateCalled = false;

  @override
  Future<List<Task>> fetchTasks() async {
    if (failRefresh) {
      throw const ApiException(
        statusCode: 503,
        message: 'Aktualisierung abgelehnt',
      );
    }
    return const [];
  }

  @override
  Future<Task> fetchTaskDetail(int taskId) async => Task(
    id: taskId,
    containerId: 1,
    projectId: 4,
    createdBy: 1,
    title: 'Demo',
    description: 'Demo',
    status: 'open',
    createdAt: '',
    updatedAt: '',
    containerTitle: 'Container',
    creatorName: 'Max',
    canEdit: false,
    canChangeStatus: true,
  );

  @override
  Future<void> deleteTask(int taskId) async {}

  @override
  Future<void> updateTaskStatus(int taskId, String newStatus) async {
    if (statusError != null) throw statusError!;
    statusCalled = true;
  }

  @override
  Future<void> updateTask(
    int taskId, {
    required String title,
    String description = '',
    String status = 'open',
    String? deadline,
    String? attachment,
  }) async {
    updateCalled = true;
    savedTitle = title;
    savedDescription = description;
    savedDeadline = deadline;
  }

  @override
  Future<String> uploadAttachment(
    int taskId,
    Uint8List bytes,
    String filename,
  ) async => 'attachment';

  @override
  Future<int> createTask({
    required int containerId,
    required String title,
    String description = '',
    String status = 'open',
    String? deadline,
    String? attachment,
  }) async => 1;
}

class _EmptyAttachments extends TaskAttachmentRepository {
  @override
  Future<List<TaskAttachment>> list(int taskId) async => [];
}

class _EmptySubtasks extends SubtaskRepository {
  @override
  Future<SubtaskList> list(int taskId) async =>
      SubtaskList(items: [], canCreate: false);
}

class _TaskApi extends ApiClient {
  String? url;
  Map<String, dynamic>? body;
  @override
  Future<dynamic> put(String url, Map<String, dynamic> body) async {
    this.url = url;
    this.body = body;
    return {};
  }
}

Future<void> _openLimitedTask(
  WidgetTester tester,
  TaskController controller, {
  bool canEditTitleDeadline = true,
  bool canEdit = false,
  bool canManageLocalGroups = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showTaskDialog(
            context,
            controller: controller,
            containerId: 1,
            projectId: 4,
            subtaskRepository: _EmptySubtasks(),
            task: Task(
              id: 9,
              containerId: 1,
              projectId: 4,
              createdBy: 7,
              title: 'Alter Titel',
              description: 'Unveränderte Beschreibung',
              status: 'open',
              createdAt: '',
              updatedAt: '',
              containerTitle: 'Container',
              creatorName: 'Owner',
              deadline: '2026-10-12T12:00:00',
              canEditTitleDeadline: canEditTitleDeadline,
              canEdit: canEdit,
              canManageLocalGroups: canManageLocalGroups,
              canChangeStatus: true,
            ),
          ),
          child: const Text('Öffnen'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Öffnen'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'last own solo assignment requires confirmation and cancel preserves it',
    (tester) async {
      final groups = _LocalGroups()..ownSoloMetadata = true;
      final controller = TaskController(
        taskRepository: _PermissionAwareTaskRepository(),
        containerRepository: _TestContainerRepository(),
        groupRepository: groups,
        attachmentRepository: _EmptyAttachments(),
      );
      addTearDown(controller.dispose);
      await _openLimitedTask(
        tester,
        controller,
        canEdit: true,
        canManageLocalGroups: true,
      );
      await tester.tap(find.text('Deine Rechte'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Gruppenzuweisung: nur lokale Gruppen'),
        findsOneWidget,
      );
      tester
          .widget<InputChip>(find.widgetWithText(InputChip, 'Solo'))
          .onDeleted!();
      await tester.pumpAndSettle();
      expect(
        find.text('Letzte Ein-Personen-Zuweisung entfernen?'),
        findsOneWidget,
      );
      expect(groups.removed, isEmpty);
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(groups.assigned, [1]);
      tester
          .widget<InputChip>(find.widgetWithText(InputChip, 'Solo'))
          .onDeleted!();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zuweisung entfernen'));
      await tester.pumpAndSettle();
      expect(groups.removed, [1]);
      expect(find.text('Aufgabe bearbeiten'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'another own solo assignment avoids last-assignment confirmation',
    (tester) async {
      final groups = _LocalGroups()
        ..ownSoloMetadata = true
        ..secondOwnSolo = true
        ..assigned.add(4);
      final controller = TaskController(
        taskRepository: _PermissionAwareTaskRepository(),
        containerRepository: _TestContainerRepository(),
        groupRepository: groups,
        attachmentRepository: _EmptyAttachments(),
      );
      addTearDown(controller.dispose);
      await _openLimitedTask(
        tester,
        controller,
        canEdit: true,
        canManageLocalGroups: true,
      );
      tester
          .widget<InputChip>(find.widgetWithText(InputChip, 'Solo'))
          .onDeleted!();
      await tester.pumpAndSettle();
      expect(
        find.text('Letzte Ein-Personen-Zuweisung entfernen?'),
        findsNothing,
      );
      expect(groups.removed, [1]);
      expect(find.text('Aufgabe bearbeiten'), findsOneWidget);
    },
  );

  testWidgets('solo member adds and removes only local task groups', (
    tester,
  ) async {
    final groups = _LocalGroups()..assigned.add(3);
    final controller = TaskController(
      taskRepository: _PermissionAwareTaskRepository(),
      containerRepository: _TestContainerRepository(),
      groupRepository: groups,
      attachmentRepository: _EmptyAttachments(),
    );
    addTearDown(controller.dispose);
    await _openLimitedTask(
      tester,
      controller,
      canEdit: true,
      canManageLocalGroups: true,
    );
    expect(
      tester
          .widget<InputChip>(find.widgetWithText(InputChip, 'Globales Team'))
          .onDeleted,
      isNull,
    );
    final dropdown = find.byType(DropdownButtonFormField<Group>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    expect(find.text('Globales Team'), findsOneWidget);
    await tester.tap(find.text('Lokales Team').last);
    await tester.pumpAndSettle();
    expect(groups.added, [2]);
    final chip = find.widgetWithText(InputChip, 'Lokales Team');
    expect(tester.widget<InputChip>(chip).onDeleted, isNotNull);
    tester.widget<InputChip>(chip).onDeleted!();
    await tester.pumpAndSettle();
    expect(groups.removed, [2]);
    expect(
      Task.fromJson({'id': 9, 'can_manage_local_groups': '1'})
          .canManageLocalGroups,
      isTrue,
    );
    final global = Group.fromJson({'id': 3, 'is_global': 1});
    expect(global.isGlobal, isTrue);
    expect(Group.fromJson({'id': 2, 'project_id': '4'}).projectId, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('solo assignee edits the full task text including description', (
    tester,
  ) async {
    final repository = _PermissionAwareTaskRepository();
    final controller = TaskController(
      taskRepository: repository,
      containerRepository: _TestContainerRepository(),
      groupRepository: _FakeGroupRepository(),
      attachmentRepository: _EmptyAttachments(),
    );
    addTearDown(controller.dispose);
    await _openLimitedTask(tester, controller, canEdit: true);
    final field = find.byType(TextFormField).first;
    expect(tester.widget<TextFormField>(field).enabled, isTrue);
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: field, matching: find.byType(TextField)),
          )
          .maxLines,
      10,
    );
    expect(
      tester.widget<TextFormField>(field).controller!.text,
      'Alter Titel\nUnveränderte Beschreibung',
    );
    expect(find.text('Aufgabe'), findsOneWidget);
    await tester.enterText(field, 'Neuer Titel\nNeue Beschreibung');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Speichern'));
    await tester.pumpAndSettle();
    expect(repository.updateCalled, isTrue);
    expect(repository.savedTitle, 'Neuer Titel');
    expect(repository.savedDescription, 'Neuer Titel\nNeue Beschreibung');
    expect(repository.savedDeadline, '2026-10-12T12:00:00.000');
    expect(repository.titleDeadlineWrites, 0);
    expect(tester.takeException(), isNull);
  });

  test('title/deadline permission parses independently and transport sends only allowed fields', () async {
    final task = Task.fromJson({'id': 9, 'can_edit_title_deadline': '1'});
    expect(task.canEdit, isFalse);
    expect(task.canEditTitleDeadline, isTrue);
    expect(task.toJson()['can_edit_title_deadline'], isTrue);
    final api = _TaskApi();
    final repository = TaskRepository(apiClient: api);
    await repository.updateTaskTitleDeadline(9, 'Neuer Titel', null);
    expect(api.url, ApiEndpoints.taskDetail(9));
    expect(api.body, {'title': 'Neuer Titel', 'deadline': null});
    await repository.updateTaskTitleDeadline(
      9,
      'Neuer Titel',
      '2026-10-13T12:00:00',
    );
    expect(api.body, {
      'title': 'Neuer Titel',
      'deadline': '2026-10-13T12:00:00',
    });
  });

  testWidgets(
    'solo assignee edits title and removes deadline without editing description',
    (tester) async {
      final repository = _PermissionAwareTaskRepository();
      final controller = TaskController(
        taskRepository: repository,
        containerRepository: _TestContainerRepository(),
        groupRepository: _FakeGroupRepository(),
        attachmentRepository: _EmptyAttachments(),
      );
      addTearDown(controller.dispose);
      await _openLimitedTask(tester, controller);
      expect(find.text('Titel'), findsOneWidget);
      expect(find.text('Unveränderte Beschreibung'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        '  Neuer Titel  ',
      );
      await tester.ensureVisible(find.byTooltip('Frist entfernen'));
      await tester.tap(find.byTooltip('Frist entfernen'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Speichern'));
      await tester.pumpAndSettle();
      expect(repository.savedTitle, 'Neuer Titel');
      expect(repository.savedDeadline, isNull);
      expect(repository.titleDeadlineWrites, 1);
      expect(repository.updateCalled, isFalse);
      expect(repository.statusCalled, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('normal member cannot edit title or deadline', (tester) async {
    final controller = TaskController(
      taskRepository: _PermissionAwareTaskRepository(),
      containerRepository: _TestContainerRepository(),
      groupRepository: _FakeGroupRepository(),
      attachmentRepository: _EmptyAttachments(),
    );
    addTearDown(controller.dispose);
    await _openLimitedTask(tester, controller, canEditTitleDeadline: false);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
      isFalse,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Frist wählen'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('Frist entfernen'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('saved title is not resent when list refresh fails', (
    tester,
  ) async {
    final repository = _PermissionAwareTaskRepository()..failRefresh = true;
    final controller = TaskController(
      taskRepository: repository,
      containerRepository: _TestContainerRepository(),
      groupRepository: _FakeGroupRepository(),
      attachmentRepository: _EmptyAttachments(),
    );
    addTearDown(controller.dispose);
    await _openLimitedTask(tester, controller);
    await tester.enterText(find.byType(TextFormField).first, 'Neuer Titel');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Speichern'));
    await tester.pumpAndSettle();
    expect(repository.titleDeadlineWrites, 1);
    expect(
      find.textContaining(
        'Titel und Frist gespeichert, aber Aktualisierung fehlgeschlagen',
      ),
      findsOneWidget,
    );
    repository.failRefresh = false;
    await tester.tap(find.widgetWithText(ElevatedButton, 'Speichern'));
    await tester.pumpAndSettle();
    expect(repository.titleDeadlineWrites, 1);
    expect(find.text('Aufgabe bearbeiten'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('solo assignee sets a deadline without changing the title', (
    tester,
  ) async {
    final repository = _PermissionAwareTaskRepository();
    final controller = TaskController(
      taskRepository: repository,
      containerRepository: _TestContainerRepository(),
      groupRepository: _FakeGroupRepository(),
      attachmentRepository: _EmptyAttachments(),
    );
    addTearDown(controller.dispose);
    await _openLimitedTask(tester, controller);
    await tester.ensureVisible(find.text('Frist wählen'));
    await tester.tap(find.text('Frist wählen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Speichern'));
    await tester.pumpAndSettle();
    expect(repository.savedTitle, 'Alter Titel');
    expect(
      DateTime.parse(repository.savedDeadline!),
      DateTime(2026, 10, 15, 12),
    );
    expect(repository.titleDeadlineWrites, 1);
    expect(repository.updateCalled, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'status failure stays visible after title save and retry does not resend the title',
    (tester) async {
      final repository = _PermissionAwareTaskRepository()
        ..statusError = const ApiException(
          statusCode: 403,
          message: 'Status abgelehnt',
        );
      final controller = TaskController(
        taskRepository: repository,
        containerRepository: _TestContainerRepository(),
        groupRepository: _FakeGroupRepository(),
        attachmentRepository: _EmptyAttachments(),
      );
      addTearDown(controller.dispose);
      await _openLimitedTask(tester, controller);
      await tester.enterText(find.byType(TextFormField).first, 'Neuer Titel');
      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Erledigt').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Speichern'));
      await tester.pumpAndSettle();
      expect(repository.titleDeadlineWrites, 1);
      expect(find.text('Aufgabe bearbeiten'), findsOneWidget);
      expect(find.text('Status abgelehnt'), findsOneWidget);
      repository.statusError = null;
      await tester.tap(find.widgetWithText(ElevatedButton, 'Speichern'));
      await tester.pumpAndSettle();
      expect(repository.titleDeadlineWrites, 1);
      expect(repository.statusCalled, isTrue);
      expect(find.text('Aufgabe bearbeiten'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test('Task parses backend permission flags', () {
    final task = Task.fromJson({
      'id': 5,
      'container_id': 10,
      'project_id': 4,
      'created_by': 7,
      'title': 'Beispiel',
      'description': 'Text',
      'status': 'done',
      'created_at': '2024-01-01',
      'updated_at': '2024-01-02',
      'container_title': 'Container',
      'creator_name': 'Max',
      'can_edit': 1,
      'can_change_status': '1',
      'can_manage_groups': true,
    });

    expect(task.canEdit, isTrue);
    expect(task.canChangeStatus, isTrue);
    expect(task.canManageGroups, isTrue);
  });
  testWidgets('task dialog fits a 320px phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TaskController(groupRepository: _FakeGroupRepository());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTaskDialog(
                context,
                controller: controller,
                containerId: 1,
                projectId: 4,
              ),
              child: const Text('Dialog öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Dialog öffnen'));
    await tester.pumpAndSettle();
    expect(find.text('Anhänge'), findsOneWidget);
    expect(find.text('Noch keine Dateien hochgeladen'), findsOneWidget);
    expect(find.text('Anhang (URL/Dateiname, optional)'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Frist wählen'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'status-only changes use the status endpoint when edit rights are missing',
    (tester) async {
      final repository = _PermissionAwareTaskRepository();
      final controller = TaskController(
        taskRepository: repository,
        containerRepository: _TestContainerRepository(),
        groupRepository: _FakeGroupRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showTaskDialog(
                  context,
                  controller: controller,
                  containerId: 1,
                  projectId: 4,
                  task: Task(
                    id: 9,
                    containerId: 1,
                    projectId: 4,
                    createdBy: 1,
                    title: 'Nur Status',
                    description: 'Edit verboten',
                    status: 'open',
                    createdAt: '',
                    updatedAt: '',
                    containerTitle: 'Container',
                    creatorName: 'Max',
                    canEdit: false,
                    canChangeStatus: true,
                  ),
                ),
                child: const Text('Dialog öffnen'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Dialog öffnen'));
      await tester.pumpAndSettle();

      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Erledigt').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Speichern'));
      await tester.pumpAndSettle();

      expect(repository.statusCalled, isTrue);
      expect(repository.updateCalled, isFalse);
    },
  );

  testWidgets('selects groups from dropdown and shows only selected groups', (
    tester,
  ) async {
    final controller = TaskController(groupRepository: _FakeGroupRepository());

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showTaskDialog(
                context,
                controller: controller,
                containerId: 1,
                projectId: 4,
              ),
              child: const Text('Dialog öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Dialog öffnen'));
    await tester.pumpAndSettle();

    expect(find.text('Keine Gruppen ausgewählt.'), findsOneWidget);
    expect(find.byType(InputChip), findsNothing);

    final groupDropdown = find.byType(DropdownButtonFormField<Group>);
    await tester.ensureVisible(groupDropdown);
    await tester.pumpAndSettle();
    await tester.tap(groupDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gruppe Eins').last);
    await tester.pumpAndSettle();

    expect(find.byType(InputChip), findsOneWidget);
    expect(find.text('Gruppe Eins'), findsOneWidget);
    expect(find.text('Keine Gruppen ausgewählt.'), findsNothing);

    await tester.ensureVisible(groupDropdown);
    await tester.pumpAndSettle();
    await tester.tap(groupDropdown);
    await tester.pumpAndSettle();
    expect(find.text('Gruppe Zwei'), findsOneWidget);
    expect(find.text('Gruppe Eins'), findsOneWidget);
  });
}
