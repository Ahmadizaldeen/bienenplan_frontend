import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:bienenplan_frontend/core/api/api_exception.dart';
import 'package:bienenplan_frontend/features/auth/application/auth_controller.dart';
import 'package:bienenplan_frontend/features/auth/application/register_controller.dart';
import 'package:bienenplan_frontend/features/auth/data/auth_repository.dart';
import 'package:bienenplan_frontend/features/projects/application/project_controller.dart';
import 'package:bienenplan_frontend/features/projects/data/project_local_store.dart';
import 'package:bienenplan_frontend/features/projects/data/project_model.dart';
import 'package:bienenplan_frontend/features/projects/data/project_repository.dart';
import 'package:bienenplan_frontend/features/tasks/application/task_controller.dart';
import 'package:bienenplan_frontend/features/tasks/data/container_repository.dart';
import 'package:bienenplan_frontend/features/tasks/data/container_model.dart'
    as container_model;
import 'package:bienenplan_frontend/features/tasks/data/task_model.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_repository.dart';

class FakeAuthRepository implements AuthRepositoryContract {
  bool loginCalled = false;
  bool shouldSucceed = true;

  @override
  Future<bool> login(String email, String password) async {
    loginCalled = true;
    return shouldSucceed;
  }

  @override
  Future<bool> register(String name, String email, String password) async {
    return shouldSucceed;
  }

  @override
  Future<void> logout() async {}
}

class ExceptionAuthRepository implements AuthRepositoryContract {
  final Exception exceptionToThrow;
  ExceptionAuthRepository(this.exceptionToThrow);

  @override
  Future<bool> login(String email, String password) async {
    throw exceptionToThrow;
  }

  @override
  Future<bool> register(String name, String email, String password) async {
    throw exceptionToThrow;
  }

  @override
  Future<void> logout() async {}
}

class FakeTaskRepository implements TaskRepositoryContract {
  bool loadCalled = false;
  bool updateCalled = false;

  @override
  Future<List<Task>> fetchTasks() async {
    loadCalled = true;
    return [
      Task(
        id: 1,
        containerId: 10,
        createdBy: 2,
        title: 'Testtask',
        description: 'Beschreibung',
        status: 'pending',
        createdAt: '2024-01-01',
        updatedAt: '2024-01-01',
        containerTitle: 'Container',
        creatorName: 'Tester',
      ),
    ];
  }

  @override
  Future<void> updateTaskStatus(int taskId, String newStatus) async {
    updateCalled = true;
  }

  @override
  Future<Task> fetchTaskDetail(int taskId) async =>
      await fetchTasks().then((tasks) => tasks.first);

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
  Future<void> createTask({
    required int containerId,
    required String title,
    String description = '',
    String status = 'pending',
    String? deadline,
    String? attachment,
  }) async {}
}

/// Simuliert das Backend: `createTask` speichert die Aufgabe, danach liefert
/// `fetchTasks` sie zusammen mit den übrigen Aufgaben des Containers zurück.
class _CreateAwareTaskRepository implements TaskRepositoryContract {
  bool createTaskCalled = false;
  final List<Task> _tasks = [
    Task(
      id: 1,
      containerId: 10,
      createdBy: 2,
      title: 'Bestehende Aufgabe',
      description: '',
      status: 'pending',
      createdAt: '2024-01-01',
      updatedAt: '2024-01-01',
      containerTitle: 'Container',
      creatorName: 'Tester',
    ),
  ];

  @override
  Future<List<Task>> fetchTasks() async => List.unmodifiable(_tasks);

  @override
  Future<void> updateTaskStatus(int taskId, String newStatus) async {}

  @override
  Future<Task> fetchTaskDetail(int taskId) async => _tasks.first;

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
  Future<void> createTask({
    required int containerId,
    required String title,
    String description = '',
    String status = 'pending',
    String? deadline,
    String? attachment,
  }) async {
    createTaskCalled = true;
    _tasks.add(
      Task(
        id: _tasks.length + 1,
        containerId: containerId,
        createdBy: 2,
        title: title,
        description: description,
        status: status,
        createdAt: '2024-01-01',
        updatedAt: '2024-01-01',
        deadline: deadline,
        attachment: attachment,
        containerTitle: 'Container',
        creatorName: 'Tester',
      ),
    );
  }
}

class FakeContainerRepository implements ContainerRepositoryContract {
  bool createContainerCalled = false;
  String? createdContainerTitle;
  int? createdContainerProjectId;
  final List<container_model.Container> containers = [];

  @override
  Future<List<container_model.Container>> fetchContainers() async {
    return List.unmodifiable(containers);
  }

  @override
  Future<container_model.Container> createContainer(
    String title, {
    int? projectId,
  }) async {
    createContainerCalled = true;
    createdContainerTitle = title;
    createdContainerProjectId = projectId;
    final container = container_model.Container(
      id: 99,
      title: title,
      projectId: projectId,
    );
    containers.add(container);
    return container;
  }
}

class FakeRegisterRepository implements AuthRepositoryContract {
  bool registerCalled = false;
  bool shouldSucceed = true;

  @override
  Future<bool> login(String email, String password) async => true;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> register(String name, String email, String password) async {
    registerCalled = true;
    return shouldSucceed;
  }
}

class FakeProjectRepository implements ProjectRepositoryContract {
  bool fetchCalled = false;
  bool createCalled = false;
  String? createdName;
  final List<Project> _list = [
    const Project(id: 1, name: 'BienenPlan Backend'),
    const Project(id: 2, name: 'BienenPlan App'),
  ];

  @override
  Future<List<Project>> fetchProjects() async {
    fetchCalled = true;
    return List.from(_list);
  }

  @override
  Future<void> createProject(String name) async {
    createCalled = true;
    createdName = name;
    _list.add(Project(id: _list.length + 1, name: name));
  }
}

class ExceptionProjectRepository implements ProjectRepositoryContract {
  final Exception exceptionToThrow;
  ExceptionProjectRepository(this.exceptionToThrow);

  @override
  Future<List<Project>> fetchProjects() async {
    throw exceptionToThrow;
  }

  @override
  Future<void> createProject(String name) async {
    throw exceptionToThrow;
  }
}

class FakeProjectLocalStore implements ProjectLocalStoreContract {
  int? selectedProjectId;

  @override
  Future<int?> getSelectedProjectId() async => selectedProjectId;

  @override
  Future<void> setSelectedProjectId(int id) async {
    selectedProjectId = id;
  }
}

void main() {
  test('AuthController login updates loading and success state', () async {
    final controller = AuthController(authRepository: FakeAuthRepository());

    final success = await controller.login('mail@example.com', 'secret');

    expect(success, isTrue);
    expect(controller.isLoading, isFalse);
    expect(controller.errorMessage, isNull);
  });

  test('TaskController loads tasks and exposes data state', () async {
    final repository = FakeTaskRepository();
    final controller = TaskController(
      taskRepository: repository,
      containerRepository: FakeContainerRepository(),
    );

    await controller.loadTasks();

    expect(repository.loadCalled, isTrue);
    expect(controller.tasks.length, 1);
    expect(controller.isLoading, isFalse);
    expect(controller.errorMessage, isNull);
  });

  test('TaskController creates container and tracks in state', () async {
    final repository = FakeContainerRepository();
    final controller = TaskController(
      taskRepository: FakeTaskRepository(),
      containerRepository: repository,
    );

    final success = await controller.createContainer(
      'In Progress',
      projectId: 5,
    );

    expect(success, isTrue);
    expect(repository.createContainerCalled, isTrue);
    expect(repository.createdContainerTitle, 'In Progress');
    expect(repository.createdContainerProjectId, 5);
    expect(controller.extraContainers.length, 1);
    expect(controller.extraContainers.first.title, 'In Progress');
    expect(controller.extraContainers.first.projectId, 5);
  });

  test('TaskController reloads the task list (incl. the new task) after createTask', () async {
    final repository = _CreateAwareTaskRepository();
    final controller = TaskController(
      taskRepository: repository,
      containerRepository: FakeContainerRepository(),
    );

    final success = await controller.createTask(
      containerId: 10,
      title: 'Neue Aufgabe',
    );

    expect(success, isTrue);
    expect(repository.createTaskCalled, isTrue);
    // Nach erfolgreichem Erstellen wird der komplette Container inkl.
    // aller Aufgaben (auch der neuen) neu geladen und in der UI angezeigt.
    expect(controller.tasks.length, 2);
    expect(controller.tasks.any((t) => t.title == 'Neue Aufgabe'), isTrue);
    expect(controller.isLoading, isFalse);
    expect(controller.errorMessage, isNull);
  });

  test('Task parses the project id returned by the API', () {
    final task = Task.fromJson({
      'id': 1,
      'container_id': 10,
      'project_id': '7',
      'created_by': 2,
      'title': 'Testtask',
      'description': '',
      'status': 'pending',
      'created_at': '2024-01-01',
      'updated_at': '2024-01-01',
      'container_title': 'Container',
      'creator_name': 'Tester',
    });

    expect(task.projectId, 7);
  });

  test(
    'RegisterController registers successfully and exposes loading state',
    () async {
      final repository = FakeRegisterRepository();
      final controller = RegisterController(authRepository: repository);

      final success = await controller.register(
        'Max Mustermann',
        'mail@example.com',
        'secret123',
      );

      expect(success, isTrue);
      expect(repository.registerCalled, isTrue);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    },
  );

  test('AuthController handles ApiException and sets error message', () async {
    final controller = AuthController(
      authRepository: ExceptionAuthRepository(
        const ApiException(statusCode: 401, message: 'Falsche Zugangsdaten'),
      ),
    );

    final success = await controller.login('mail@example.com', 'wrong');

    expect(success, isFalse);
    expect(controller.isLoading, isFalse);
    expect(controller.errorMessage, 'Falsche Zugangsdaten');
  });

  test(
    'RegisterController handles ApiException and sets error message',
    () async {
      final controller = RegisterController(
        authRepository: ExceptionAuthRepository(
          const ApiException(
            statusCode: 409,
            message: 'E-Mail existiert bereits',
          ),
        ),
      );

      final success = await controller.register(
        'Max',
        'mail@example.com',
        'secret123',
      );

      expect(success, isFalse);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, 'E-Mail existiert bereits');
    },
  );

  test('ProjectController loads projects and exposes state', () async {
    final repository = FakeProjectRepository();
    final controller = ProjectController(
      projectRepository: repository,
      projectLocalStore: FakeProjectLocalStore(),
    );

    await controller.loadProjects();

    expect(repository.fetchCalled, isTrue);
    expect(controller.projects.length, 2);
    expect(controller.projects.first.name, 'BienenPlan Backend');
    expect(
      controller.projects.first.id == controller.selectedProject?.id,
      isTrue,
    );
    expect(controller.isLoading, isFalse);
    expect(controller.errorMessage, isNull);
  });

  test('ProjectController handles errors gracefully', () async {
    final controller = ProjectController(
      projectRepository: ExceptionProjectRepository(
        Exception('Server nicht erreichbar'),
      ),
      projectLocalStore: FakeProjectLocalStore(),
    );

    await controller.loadProjects();

    expect(controller.isLoading, isFalse);
    expect(controller.projects, isEmpty);
    expect(controller.errorMessage, 'Server nicht erreichbar');
  });

  test('ProjectController creates a project and reloads', () async {
    final repository = FakeProjectRepository();
    final controller = ProjectController(
      projectRepository: repository,
      projectLocalStore: FakeProjectLocalStore(),
    );

    final success = await controller.createProject('Neues Bienen-Projekt');

    expect(success, isTrue);
    expect(repository.createCalled, isTrue);
    expect(repository.createdName, 'Neues Bienen-Projekt');
    expect(controller.projects.length, 3);
    expect(controller.projects.last.name, 'Neues Bienen-Projekt');
    expect(controller.isLoading, isFalse);
    expect(controller.errorMessage, isNull);
  });

  test('ProjectController rejects empty project name', () async {
    final repository = FakeProjectRepository();
    final controller = ProjectController(
      projectRepository: repository,
      projectLocalStore: FakeProjectLocalStore(),
    );

    final success = await controller.createProject('   ');

    expect(success, isFalse);
    expect(repository.createCalled, isFalse);
    expect(controller.errorMessage, 'Projektname darf nicht leer sein.');
  });

  test('ProjectController selectProject toggles active project', () async {
    final repository = FakeProjectRepository();
    final store = FakeProjectLocalStore();
    final controller = ProjectController(
      projectRepository: repository,
      projectLocalStore: store,
    );

    await controller.loadProjects();
    expect(controller.projects[0].id == controller.selectedProject?.id, isTrue);
    expect(
      controller.projects[1].id == controller.selectedProject?.id,
      isFalse,
    );
    expect(controller.selectedProject?.id, 1);

    controller.selectProject(2);
    expect(
      controller.projects[0].id == controller.selectedProject?.id,
      isFalse,
    );
    expect(controller.projects[1].id == controller.selectedProject?.id, isTrue);
    expect(controller.selectedProject?.id, 2);
    expect(store.selectedProjectId, 2);
  });

  test('Project.fromJson parses varied formats', () {
    final p1 = Project.fromJson({'id': 1, 'name': 'P1'});
    expect(p1.id, 1);
    expect(p1.name, 'P1');

    final p2 = Project.fromJson({'id': '2', 'title': 'P2'});
    expect(p2.id, 2);
    expect(p2.name, 'P2');
  });
}
