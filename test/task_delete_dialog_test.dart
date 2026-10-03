import 'dart:typed_data';

import 'package:bienenplan_frontend/features/tasks/application/task_controller.dart';
import 'package:bienenplan_frontend/features/tasks/data/container_model.dart'
    as container_model;
import 'package:bienenplan_frontend/features/tasks/data/container_repository.dart';
import 'package:bienenplan_frontend/features/tasks/data/group_model.dart';
import 'package:bienenplan_frontend/features/tasks/data/group_repository.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_model.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_repository.dart';
import 'package:bienenplan_frontend/features/tasks/presentation/task_dialog.dart';
import 'package:bienenplan_frontend/features/user/data/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bienenplan_frontend/features/subtasks/data/subtask_model.dart';
import 'package:bienenplan_frontend/features/subtasks/data/subtask_repository.dart';

class _UnexpectedSubtaskRepository extends SubtaskRepository {
  int loads = 0;

  @override
  Future<SubtaskList> list(int taskId) async {
    loads++;
    throw StateError('Unsaved tasks must not load subtasks');
  }
}

class _DeletingTaskRepository implements TaskRepositoryContract {
  final List<Task> tasks = [
    Task(
      id: 7,
      containerId: 1,
      createdBy: 1,
      title: 'Alte Aufgabe',
      description: '',
      status: 'open',
      createdAt: '2026-01-01',
      updatedAt: '2026-01-01',
      containerTitle: 'Container',
      creatorName: 'Tester',
    ),
  ];

  @override
  Future<List<Task>> fetchTasks() async => List.unmodifiable(tasks);

  @override
  Future<Task> fetchTaskDetail(int taskId) async =>
      tasks.firstWhere((task) => task.id == taskId);

  @override
  Future<void> deleteTask(int taskId) async {
    tasks.removeWhere((task) => task.id == taskId);
  }

  @override
  Future<void> updateTaskStatus(int taskId, String newStatus) async {}

  @override
  Future<void> updateTask(
    int taskId, {
    required String title,
    String description = '',
    String status = 'open',
    String? deadline,
    String? attachment,
  }) async {}

  @override
  Future<String> uploadAttachment(
    int taskId,
    Uint8List bytes,
    String filename,
  ) async => filename;

  @override
  Future<int> createTask({
    required int containerId,
    required String title,
    String description = '',
    String status = 'open',
    String? deadline,
    String? attachment,
  }) async => 8;
}

class _FakeContainerRepository implements ContainerRepositoryContract {
  @override
  Future<List<container_model.Container>> fetchContainers() async => const [
    container_model.Container(id: 1, title: 'Container'),
  ];

  @override
  Future<container_model.Container> createContainer(
    String title, {
    int? projectId,
  }) async =>
      container_model.Container(id: 1, title: title, projectId: projectId);
}

class _FakeGroupRepository implements GroupRepositoryContract {
  @override
  Future<List<Group>> fetchAllGroups() async => const [];

  @override
  Future<List<Group>> fetchGroupsForTask(int taskId) async => const [];

  @override
  Future<List<GroupUser>> fetchAllUsers() async => const [];

  @override
  Future<Group> createGroup(
    String name, {
    List<int> userIds = const [],
  }) async => Group(id: 1, name: name);

  @override
  Future<void> assignGroupToTask(int taskId, int groupId) async {}

  @override
  Future<void> removeGroupFromTask(int taskId, int groupId) async {}
}

void main() {
  testWidgets('deletes an existing task after confirmation', (tester) async {
    final taskRepository = _DeletingTaskRepository();
    final controller = TaskController(
      taskRepository: taskRepository,
      containerRepository: _FakeContainerRepository(),
      groupRepository: _FakeGroupRepository(),
    );
    final task = taskRepository.tasks.single;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showTaskDialog(
                context,
                controller: controller,
                containerId: task.containerId,
                task: task,
              ),
              child: const Text('Dialog öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Dialog öffnen'));
    await tester.pumpAndSettle();
    expect(find.text('Teilaufgaben'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Teilaufgaben')).dy,
      greaterThan(tester.getBottomLeft(find.text('Frist wählen')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Teilaufgaben')).dy,
      lessThan(tester.getTopLeft(find.text('Anhänge')).dy),
    );
    await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
    await tester.pumpAndSettle();

    expect(find.text('Aufgabe löschen?'), findsOneWidget);
    expect(taskRepository.tasks, hasLength(1));

    await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
    await tester.pumpAndSettle();

    expect(taskRepository.tasks, isEmpty);
    expect(find.text('Aufgabe bearbeiten'), findsNothing);
  });

  testWidgets('new task shows subtasks without loading before saving', (
    tester,
  ) async {
    final subtaskRepository = _UnexpectedSubtaskRepository();
    final controller = TaskController(
      taskRepository: _DeletingTaskRepository(),
      containerRepository: _FakeContainerRepository(),
      groupRepository: _FakeGroupRepository(),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showTaskDialog(
                context,
                controller: controller,
                containerId: 1,
                subtaskRepository: subtaskRepository,
              ),
              child: const Text('Neu'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Neu'));
    await tester.pumpAndSettle();
    expect(find.text('Neue Aufgabe'), findsOneWidget);
    expect(find.text('Teilaufgaben'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Teilaufgaben')).dy,
      greaterThan(tester.getBottomLeft(find.text('Frist wählen')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Teilaufgaben')).dy,
      lessThan(tester.getTopLeft(find.text('Anhänge')).dy),
    );
    expect(
      find.text(
        'Teilaufgaben können nach dem Erstellen der Aufgabe hinzugefügt und bearbeitet werden.',
      ),
      findsOneWidget,
    );
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.text('Teilaufgabe hinzufuegen'), findsNothing);
    expect(
      tester
          .widget<ListTile>(find.byKey(const ValueKey('subtask-section')))
          .onTap,
      isNull,
    );
    expect(subtaskRepository.loads, 0);
  });
}
