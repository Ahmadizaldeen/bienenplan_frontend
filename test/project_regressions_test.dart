import 'dart:async';

import 'package:bienenplan_frontend/core/api/api_exception.dart';
import 'package:bienenplan_frontend/features/home/presentation/home_screen.dart';
import 'package:bienenplan_frontend/features/projects/application/project_controller.dart';
import 'package:bienenplan_frontend/features/projects/data/project_archive_repository.dart';
import 'package:bienenplan_frontend/features/projects/data/project_group_model.dart';
import 'package:bienenplan_frontend/features/projects/data/project_model.dart';
import 'package:bienenplan_frontend/features/projects/presentation/project_archive_screen.dart';
import 'package:bienenplan_frontend/features/projects/presentation/project_editor_dialog.dart';
import 'package:bienenplan_frontend/features/projects/presentation/project_groups_dialog.dart';
import 'package:bienenplan_frontend/features/projects/presentation/project_list_widget.dart';
import 'package:bienenplan_frontend/features/tasks/application/task_controller.dart';
import 'package:bienenplan_frontend/features/tasks/data/container_model.dart'
    as model;
import 'package:bienenplan_frontend/features/tasks/data/task_model.dart';
import 'package:bienenplan_frontend/features/user/application/user_controller.dart';
import 'package:bienenplan_frontend/features/user/data/user_model.dart';
import 'package:bienenplan_frontend/features/user/data/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'controllers_test.dart'
    show
        FakeContainerRepository,
        FakeProjectLocalStore,
        FakeProjectRepository,
        FakeTaskRepository;

const _project = Project(
  id: 1,
  name: 'Projekt',
  canEdit: true,
  canDelete: true,
  canManageGroups: true,
);
const _group = ProjectGroup(id: 1, name: 'Team', projectId: 1);
const _apiError = ApiException(
  statusCode: 503,
  message: 'Server nicht erreichbar',
);

class _Projects extends FakeProjectRepository {
  bool failFetch = false;
  bool failWrite = false;
  bool failGroups = false;
  bool failAvailable = false;
  bool failUsers = false;
  bool removed = false;
  int loads = 0;
  int writes = 0;
  Completer<void>? pendingWrite;
  Completer<List<ProjectGroup>>? pendingGroups;
  Completer<List<ProjectGroup>>? pendingAvailable;

  @override
  Future<List<Project>> fetchProjects() async {
    loads++;
    if (failFetch) throw _apiError;
    return super.fetchProjects();
  }

  Future<void> _write() async {
    writes++;
    await pendingWrite?.future;
    if (failWrite) throw _apiError;
  }

  @override
  Future<void> createProject(String name) async {
    await _write();
    await super.createProject(name);
  }

  @override
  Future<void> updateProject(int id, String name) async {
    await _write();
    await super.updateProject(id, name);
  }

  @override
  Future<void> archiveProject(int id) async {
    await _write();
    await super.archiveProject(id);
  }

  @override
  Future<List<ProjectGroup>> fetchProjectGroups(int projectId) async {
    if (pendingGroups != null) return pendingGroups!.future;
    if (failGroups) throw _apiError;
    return removed ? [] : [_group];
  }

  @override
  Future<List<ProjectGroup>> fetchAvailableGroups() async {
    if (pendingAvailable != null) return pendingAvailable!.future;
    if (failAvailable) throw _apiError;
    return [_group];
  }

  @override
  Future<List<GroupUser>> fetchUsers() async {
    if (failUsers) throw _apiError;
    return const [GroupUser(id: 1, name: 'Max')];
  }

  @override
  Future<void> removeGroup(int projectId, int groupId) async {
    if (failWrite) throw _apiError;
    removed = true;
  }
}

class _QueuedProjects extends FakeProjectRepository {
  final requests = <Completer<List<Project>>>[];

  @override
  Future<List<Project>> fetchProjects() {
    final request = Completer<List<Project>>();
    requests.add(request);
    return request.future;
  }
}

class _QueuedTasks extends FakeTaskRepository {
  final requests = <Completer<List<Task>>>[];

  @override
  Future<List<Task>> fetchTasks() {
    final request = Completer<List<Task>>();
    requests.add(request);
    return request.future;
  }
}

class _Tasks extends FakeTaskRepository {
  _Tasks(this.projects);
  final _Projects projects;
  int loads = 0;

  @override
  Future<List<Task>> fetchTasks() async {
    loads++;
    return projects.removed
        ? []
        : [
            Task(
              id: 1,
              containerId: 10,
              projectId: 1,
              createdBy: 1,
              title: 'Gruppenaufgabe',
              description: '',
              status: 'open',
              createdAt: '',
              updatedAt: '',
              containerTitle: 'Container',
              creatorName: 'Max',
            ),
          ];
  }
}

class _PendingStore extends FakeProjectLocalStore {
  final pending = Completer<int?>();

  @override
  Future<int?> getSelectedProjectId() => pending.future;
}

class _User extends UserRepository {
  @override
  Future<AppUser> fetchCurrentUser() async =>
      const AppUser(id: 1, name: 'Max', email: 'max@example.test');
}

class _Archive extends ProjectArchiveRepository {
  int restores = 0;

  @override
  Future<List<Project>> fetchArchivedProjects() async => const [
    Project(id: 9, name: 'Archiv', canRestore: true),
  ];

  @override
  Future<void> restore(int projectId) async {
    restores++;
  }
}

ProjectController _controller(FakeProjectRepository repository) =>
    ProjectController(
      projectRepository: repository,
      projectLocalStore: FakeProjectLocalStore(),
    );

void main() {
  final mutations =
      <String, Future<ProjectMutationResult> Function(ProjectController)>{
        'create': (controller) => controller.createProject('Neu'),
        'update': (controller) => controller.updateProject(1, 'Neu'),
        'archive': (controller) => controller.archiveProject(1),
      };

  for (final entry in mutations.entries) {
    test(
      '${entry.key} distinguishes write failure from refresh failure',
      () async {
        final repository = _Projects();
        final controller = _controller(repository);
        addTearDown(controller.dispose);
        await controller.loadProjects();
        repository.failFetch = true;
        expect(
          await entry.value(controller),
          ProjectMutationResult.refreshFailed,
        );
        expect(repository.writes, 1);
        expect(controller.projects, hasLength(2));
        expect(controller.errorMessage, _apiError.message);
        expect(controller.isLoading, isFalse);
        repository.failFetch = false;
        await controller.loadProjects();
        expect(repository.writes, 1);
        expect(controller.errorMessage, isNull);
        repository.failWrite = true;
        expect(await entry.value(controller), ProjectMutationResult.failed);
        expect(controller.errorMessage, _apiError.message);
      },
    );

    test('${entry.key} completes safely after controller disposal', () async {
      final repository = _Projects()..pendingWrite = Completer<void>();
      final controller = _controller(repository);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final operation = entry.value(controller);
      controller.dispose();
      final before = notifications;
      repository.pendingWrite!.complete();
      expect(await operation, ProjectMutationResult.succeeded);
      expect(repository.loads, 0);
      expect(notifications, before);
    });
  }

  test(
    'project load ignores old responses and completion after disposal',
    () async {
      final repository = _QueuedProjects();
      final controller = _controller(repository);
      final first = controller.loadProjects();
      final second = controller.loadProjects();
      repository.requests[1].complete([_project]);
      await second;
      repository.requests[0].complete([]);
      await first;
      expect(controller.projects.single.id, 1);
      final pending = controller.loadProjects();
      controller.dispose();
      repository.requests[2].completeError(_apiError);
      await pending;
      expect(controller.projects.single.id, 1);
    },
  );

  test(
    'task refresh ignores old responses and completion after disposal',
    () async {
      final repository = _QueuedTasks();
      final controller = TaskController(
        taskRepository: repository,
        containerRepository: FakeContainerRepository(),
      );
      final first = controller.loadTasks();
      final second = controller.loadTasks();
      repository.requests[1].complete([]);
      await second;
      repository.requests[0].complete(await FakeTaskRepository().fetchTasks());
      await first;
      expect(controller.tasks, isEmpty);
      final pending = controller.loadTasks();
      controller.dispose();
      repository.requests[2].completeError(_apiError);
      await pending;
      expect(controller.tasks, isEmpty);
    },
  );

  test(
    'project load does not change selection after disposal during storage read',
    () async {
      final store = _PendingStore();
      final controller = ProjectController(
        projectRepository: FakeProjectRepository(),
        projectLocalStore: store,
      );
      final operation = controller.loadProjects();
      await Future<void>.delayed(Duration.zero);
      controller.dispose();
      store.pending.complete(1);
      await operation;
      expect(controller.projects, isEmpty);
      expect(controller.selectedProject, isNull);
    },
  );

  test('task refresh failure clears stale tasks and containers', () async {
    final repository = _QueuedTasks();
    final containers = FakeContainerRepository()
      ..containers.add(
        const model.Container(id: 10, title: 'Container', projectId: 1),
      );
    final controller = TaskController(
      taskRepository: repository,
      containerRepository: containers,
    );
    addTearDown(controller.dispose);
    final first = controller.loadTasks();
    repository.requests[0].complete(await FakeTaskRepository().fetchTasks());
    await first;
    expect(controller.tasks, hasLength(1));
    expect(controller.extraContainers, hasLength(1));
    final refresh = controller.loadTasks();
    repository.requests[1].completeError(_apiError);
    await refresh;
    expect(controller.errorMessage, _apiError.message);
    expect(controller.tasks, isEmpty);
    expect(controller.extraContainers, isEmpty);
    expect(controller.isLoading, isFalse);
  });

  test(
    'group read errors do not poison later reads or project state',
    () async {
      final repository = _Projects()..failGroups = true;
      final controller = _controller(repository);
      addTearDown(controller.dispose);
      await expectLater(controller.fetchProjectGroups(1), throwsA(_apiError));
      repository.failGroups = false;
      expect(await controller.fetchProjectGroups(1), [_group]);
      expect(controller.errorMessage, isNull);
      repository.failUsers = true;
      await expectLater(controller.fetchUsers(), throwsA(_apiError));
      repository.failUsers = false;
      expect(await controller.fetchUsers(), hasLength(1));
      expect(controller.errorMessage, isNull);
    },
  );

  testWidgets('saving locks the field and rejects repeated submit callbacks', (
    tester,
  ) async {
    final repository = _Projects()..pendingWrite = Completer<void>();
    final controller = _controller(repository);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ProjectEditorDialog(controller: controller, project: _project),
      ),
    );
    final submit = tester
        .widget<TextField>(find.byType(TextField))
        .onSubmitted!;
    submit('Neu');
    submit('Neu');
    await tester.pump();
    expect(repository.writes, 1);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).enabled,
      isFalse,
    );
    submit('Neu');
    expect(repository.writes, 1);
    await tester.pumpWidget(const SizedBox());
    repository.pendingWrite!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed save warns on refresh failure and retries only GET', (
    tester,
  ) async {
    final repository = _Projects();
    final controller = _controller(repository);
    addTearDown(controller.dispose);
    await controller.loadProjects();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProjectListWidget(controller: controller)),
      ),
    );
    await tester.tap(find.byTooltip('Projekt bearbeiten').first);
    await tester.pumpAndSettle();
    repository.failFetch = true;
    await tester.enterText(find.byType(TextFormField), 'Neu');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectEditorDialog), findsNothing);
    expect(find.textContaining('Projekt gespeichert, aber'), findsOneWidget);
    expect(repository.writes, 1);
    repository.failFetch = false;
    await tester.tap(find.text('Neu laden'));
    await tester.pumpAndSettle();
    expect(repository.writes, 1);
    expect(controller.projects.first.name, 'Neu');
    expect(controller.errorMessage, isNull);
  });

  for (final assignedFailsFirst in [true, false]) {
    testWidgets(
      'parallel group failure stays visible (assigned first: $assignedFailsFirst)',
      (tester) async {
        final repository = _Projects()
          ..pendingGroups = Completer<List<ProjectGroup>>()
          ..pendingAvailable = Completer<List<ProjectGroup>>();
        final controller = _controller(repository);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: ProjectGroupsDialog(
              project: _project,
              controller: controller,
            ),
          ),
        );
        if (assignedFailsFirst) {
          repository.pendingGroups!.completeError(_apiError);
          await tester.pump();
          repository.pendingAvailable!.complete([_group]);
        } else {
          repository.pendingAvailable!.complete([_group]);
          await tester.pump();
          repository.pendingGroups!.completeError(_apiError);
        }
        await tester.pumpAndSettle();
        expect(find.text(_apiError.message), findsOneWidget);
        expect(find.text('Es sind keine Gruppen vorhanden.'), findsNothing);
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Neue lokale Gruppe'),
              )
              .onPressed,
          isNull,
        );
        repository.pendingGroups = null;
        repository.pendingAvailable = null;
        await tester.tap(find.text('Erneut versuchen'));
        await tester.pumpAndSettle();
        expect(find.text(_apiError.message), findsNothing);
        expect(find.text('Team'), findsOneWidget);
        expect(
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
          isTrue,
        );
      },
    );
  }

  testWidgets(
    'user fetch errors are shown and recover on next creation attempt',
    (tester) async {
      final repository = _Projects()..failUsers = true;
      final controller = _controller(repository);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectGroupsDialog(project: _project, controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Neue lokale Gruppe'));
      await tester.pumpAndSettle();
      expect(find.text(_apiError.message), findsOneWidget);
      repository.failUsers = false;
      await tester.tap(find.text('Neue lokale Gruppe'));
      await tester.pumpAndSettle();
      expect(find.text(_apiError.message), findsNothing);
      expect(find.text('Max'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Home reloads affected data once after group changes and detaches listener',
    (tester) async {
      final repository = _Projects();
      final projects = _controller(repository);
      final tasksRepository = _Tasks(repository);
      final tasks = TaskController(
        taskRepository: tasksRepository,
        containerRepository: FakeContainerRepository(),
      );
      final users = UserController(userRepository: _User());
      addTearDown(projects.dispose);
      addTearDown(tasks.dispose);
      addTearDown(users.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            onLogout: () {},
            projectController: projects,
            taskController: tasks,
            userController: users,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tasks.tasks, hasLength(1));
      expect(find.text('Gruppenaufgabe'), findsOneWidget);
      expect(repository.loads, 1);
      repository.failWrite = true;
      expect(await projects.setProjectGroup(1, 1, false), isFalse);
      await tester.pumpAndSettle();
      expect(repository.loads, 1);
      expect(tasksRepository.loads, 1);
      repository.failWrite = false;
      expect(await projects.setProjectGroup(1, 1, false), isTrue);
      await tester.pumpAndSettle();
      expect(tasks.tasks, isEmpty);
      expect(find.text('Gruppenaufgabe'), findsNothing);
      expect(repository.loads, 2);
      expect(tasksRepository.loads, 2);
      expect(await projects.createProjectGroup(1, 'Neu', [1]), isTrue);
      await tester.pumpAndSettle();
      expect(repository.loads, 3);
      expect(tasksRepository.loads, 3);
      await tester.pumpWidget(const SizedBox());
      expect(await projects.setProjectGroup(1, 1, true), isTrue);
      expect(repository.loads, 3);
      expect(tasksRepository.loads, 3);
    },
  );

  testWidgets(
    'restore warns when active list refresh fails without repeating restore',
    (tester) async {
      final repository = _Projects()..failFetch = true;
      final projects = _controller(repository);
      final archive = _Archive();
      addTearDown(projects.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectArchiveScreen(
            projectController: projects,
            repository: archive,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wiederherstellen'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Wiederherstellen').last,
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Projekt wiederhergestellt, aber'),
        findsOneWidget,
      );
      expect(find.text('Projekt wiederhergestellt.'), findsNothing);
      expect(archive.restores, 1);
    },
  );
}
