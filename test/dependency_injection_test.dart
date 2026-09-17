import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bienenplan_frontend/core/api/api_client.dart';
import 'package:bienenplan_frontend/features/auth/data/auth_repository.dart';
import 'package:bienenplan_frontend/features/auth/presentation/login_screen.dart';
import 'package:bienenplan_frontend/features/auth/presentation/start_screen.dart';
import 'package:bienenplan_frontend/features/home/presentation/home_screen.dart';
import 'package:bienenplan_frontend/features/tasks/application/task_controller.dart';
import 'package:bienenplan_frontend/features/tasks/data/container_model.dart'
    as container_model;
import 'package:bienenplan_frontend/features/tasks/data/container_repository.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_model.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_repository.dart';
import 'package:bienenplan_frontend/features/tasks/presentation/task_container_screen.dart';

class _FakeTaskRepo implements TaskRepositoryContract {
  @override
  Future<List<Task>> fetchTasks() async => [
    Task(
      id: 1,
      containerId: 10,
      projectId: 1,
      createdBy: 2,
      title: 'Task 1',
      description: 'Desc',
      status: 'pending',
      createdAt: '2024-01-01',
      updatedAt: '2024-01-01',
      containerTitle: 'Default Container',
      creatorName: 'User',
    ),
  ];

  @override
  Future<void> updateTaskStatus(int taskId, String newStatus) async {}

  @override
  Future<Task> fetchTaskDetail(int taskId) async => (await fetchTasks()).first;

  @override
  Future<void> updateTask(
    int taskId, {
    required String title,
    String description = '',
    String status = 'pending',
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
    String status = 'pending',
    String? deadline,
    String? attachment,
  }) async => 1;
}

class _FakeContainerRepo implements ContainerRepositoryContract {
  @override
  Future<container_model.Container> createContainer(
    String title, {
    int? projectId,
  }) async =>
      container_model.Container(id: 10, title: title, projectId: projectId);

  @override
  Future<List<container_model.Container>> fetchContainers() async => const [
    container_model.Container(id: 10, title: 'Default Container', projectId: 1),
  ];
}

void main() {
  testWidgets('Screens accept injected dependencies', (tester) async {
    final authRepository = AuthRepository();
    final apiClient = ApiClient();

    await tester.pumpWidget(
      MaterialApp(home: StartScreen(apiClient: apiClient)),
    );

    expect(find.text('BienenPlan'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(authRepository: authRepository)),
    );

    expect(find.text('BienenPlan'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(home: HomeScreen(onLogout: () {})));

    expect(find.text('User Profile'), findsOneWidget);
    expect(find.text('Projektübersicht'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('TaskListScreen shows button to create new container', (
    tester,
  ) async {
    final controller = TaskController(
      taskRepository: _FakeTaskRepo(),
      containerRepository: _FakeContainerRepo(),
    );
    await controller.loadTasks();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskListScreen(controller: controller, projectId: 1),
        ),
      ),
    );

    expect(find.text('Neuer Container'), findsOneWidget);
  });
}
