import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bienenplan_frontend/features/home/presentation/home_screen.dart';
import 'package:bienenplan_frontend/features/projects/application/project_controller.dart';
import 'package:bienenplan_frontend/features/projects/data/project_local_store.dart';
import 'package:bienenplan_frontend/features/projects/data/project_model.dart';
import 'package:bienenplan_frontend/features/projects/data/project_repository.dart';
import 'package:bienenplan_frontend/features/tasks/application/task_controller.dart';
import 'package:bienenplan_frontend/features/tasks/data/container_model.dart'
    as task_container;
import 'package:bienenplan_frontend/features/tasks/data/container_repository.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_model.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_repository.dart';
import 'package:bienenplan_frontend/features/user/application/user_controller.dart';
import 'package:bienenplan_frontend/features/user/data/user_model.dart';
import 'package:bienenplan_frontend/features/user/data/user_repository.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('home layout fits a ${width.toInt()}px smartphone', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final taskController = TaskController(
        taskRepository: _FakeTaskRepository(),
        containerRepository: _FakeContainerRepository(),
      );
      final projectController = ProjectController(
        projectRepository: _FakeProjectRepository(),
        projectLocalStore: _FakeProjectLocalStore(),
      );
      final userController = UserController(
        userRepository: _FakeUserRepository(),
      );
      addTearDown(taskController.dispose);
      addTearDown(projectController.dispose);
      addTearDown(userController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            onLogout: () {},
            taskController: taskController,
            projectController: projectController,
            userController: userController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Projektübersicht'), findsOneWidget);
      expect(find.text('Abmelden'), findsOneWidget);

      await tester.ensureVisible(find.text('Keine Aufgaben vorhanden.'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

class _FakeTaskRepository extends TaskRepository {
  @override
  Future<List<Task>> fetchTasks() async => [];
}

class _FakeContainerRepository extends ContainerRepository {
  @override
  Future<List<task_container.Container>> fetchContainers() async => [];
}

class _FakeProjectRepository extends ProjectRepository {
  @override
  Future<List<Project>> fetchProjects() async => [
    const Project(
      id: 1,
      name: 'Ein besonders langer Projektname zur Prüfung kleiner Smartphone-Displays',
    ),
  ];
}

class _FakeProjectLocalStore implements ProjectLocalStoreContract {
  @override
  Future<int?> getSelectedProjectId() async => null;

  @override
  Future<void> setSelectedProjectId(int id) async {}
}

class _FakeUserRepository extends UserRepository {
  @override
  Future<AppUser> fetchCurrentUser() async => const AppUser(
    id: 1,
    name: 'Ein besonders langer Nutzername',
    email: 'long.user.name.for.small.screen@example.com',
  );
}
