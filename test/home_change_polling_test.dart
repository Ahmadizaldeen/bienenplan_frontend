import 'package:bienenplan_frontend/core/api/api_exception.dart';
import 'package:bienenplan_frontend/features/home/presentation/home_screen.dart';
import 'package:bienenplan_frontend/features/projects/application/project_controller.dart';
import 'package:bienenplan_frontend/features/projects/data/project_local_store.dart';
import 'package:bienenplan_frontend/features/projects/data/project_model.dart';
import 'package:bienenplan_frontend/features/projects/data/project_repository.dart';
import 'package:bienenplan_frontend/features/sync/data/change_feed.dart';
import 'package:bienenplan_frontend/features/sync/data/change_repository.dart';
import 'package:bienenplan_frontend/features/subtasks/data/subtask_model.dart';
import 'package:bienenplan_frontend/features/subtasks/data/subtask_repository.dart';
import 'package:bienenplan_frontend/features/tasks/application/task_controller.dart';
import 'package:bienenplan_frontend/features/tasks/data/group_model.dart';
import 'package:bienenplan_frontend/features/tasks/data/group_repository.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_attachment.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_attachment_repository.dart';
import 'package:bienenplan_frontend/features/tasks/presentation/task_dialog.dart';
import 'package:bienenplan_frontend/features/tasks/data/container_model.dart'
    as task_container;
import 'package:bienenplan_frontend/features/tasks/data/container_repository.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_model.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_repository.dart';
import 'package:bienenplan_frontend/features/user/application/user_controller.dart';
import 'package:bienenplan_frontend/features/user/data/user_model.dart';
import 'package:bienenplan_frontend/features/user/data/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _poll = Duration(seconds: 5);

class _Changes implements ChangeRepositoryContract {
  _Changes(this.log);

  final List<String> log;
  final afters = <String?>[];
  bool refresh = false;
  Object? error;
  int _seq = 0;

  @override
  Future<ChangeFeed> fetchChanges({String? after}) async {
    afters.add(after);
    log.add('changes:${after ?? 'baseline'}');
    final failure = error;
    if (failure != null) throw failure;
    _seq++;
    return ChangeFeed(
      nextCursor: 'c$_seq',
      refreshRequired: after != null && refresh,
    );
  }
}

class _Tasks extends TaskRepository {
  _Tasks(this.log);

  final List<String> log;
  String title = 'Erste Aufgabe';
  bool fail = false;
  bool canEdit = true;
  int loads = 0;

  @override
  Future<List<Task>> fetchTasks() async {
    loads++;
    log.add('tasks');
    if (fail) {
      throw const ApiException(statusCode: 500, message: 'Serverfehler');
    }
    return [
      Task(
        id: 1,
        containerId: 1,
        projectId: 1,
        createdBy: 1,
        title: title,
        description: '',
        status: 'open',
        createdAt: '',
        updatedAt: '',
        containerTitle: 'Container 1',
        creatorName: 'Test',
        canEdit: canEdit,
        canChangeStatus: true,
      ),
    ];
  }
}

class _Groups implements GroupRepositoryContract {
  @override
  Future<List<Group>> fetchGroupsForProject(int projectId) async => const [];
  @override
  Future<List<Group>> fetchGroupsForTask(int taskId) async => const [];
  @override
  Future<void> assignGroupToTask(int taskId, int groupId) async {}
  @override
  Future<void> removeGroupFromTask(int taskId, int groupId) async {}
}

class _Attachments extends TaskAttachmentRepository {
  @override
  Future<List<TaskAttachment>> list(int taskId) async => const [];
}

class _Subtasks extends SubtaskRepository {
  @override
  Future<SubtaskList> list(int taskId) async =>
      SubtaskList(items: const [], canCreate: false);
}

class _Containers extends ContainerRepository {
  @override
  Future<List<task_container.Container>> fetchContainers() async => const [
    task_container.Container(id: 1, title: 'Container 1', projectId: 1),
  ];
}

class _Projects extends ProjectRepository {
  _Projects(this.log);

  final List<String> log;
  int loads = 0;

  @override
  Future<List<Project>> fetchProjects() async {
    loads++;
    log.add('projects');
    return const [Project(id: 1, name: 'Projekt A')];
  }
}

class _Store implements ProjectLocalStoreContract {
  @override
  Future<int?> getSelectedProjectId() async => null;

  @override
  Future<void> setSelectedProjectId(int id) async {}
}

class _Users extends UserRepository {
  _Users(this.log);

  final List<String> log;
  int loads = 0;

  @override
  Future<AppUser> fetchCurrentUser() async {
    loads++;
    log.add('me');
    return const AppUser(id: 1, name: 'Biene', email: 'b@example.com');
  }
}

class _Harness {
  final log = <String>[];
  late final changes = _Changes(log);
  late final tasksRepo = _Tasks(log);
  late final projectsRepo = _Projects(log);
  late final usersRepo = _Users(log);
  late final tasks = TaskController(
    taskRepository: tasksRepo,
    containerRepository: _Containers(),
  );
  late final projects = ProjectController(
    projectRepository: projectsRepo,
    projectLocalStore: _Store(),
  );
  late final users = UserController(userRepository: usersRepo);
  int logouts = 0;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tasks.dispose);
    addTearDown(projects.dispose);
    addTearDown(users.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          onLogout: () => logouts++,
          taskController: tasks,
          projectController: projects,
          userController: users,
          changeRepository: changes,
          pollInterval: _poll,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('baseline is fetched before the initial full load', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    expect(h.log.first, 'changes:baseline');
    expect(h.log.skip(1).toSet(), {'tasks', 'projects', 'me'});
    expect(h.tasks.tasks.single.title, 'Erste Aufgabe');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('refresh_required=false polls every 5s without full loads', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.pump(_poll);
    await tester.pump(_poll);
    expect(h.changes.afters, [null, 'c1', 'c2']);
    expect(h.tasksRepo.loads, 1);
    expect(h.projectsRepo.loads, 1);
    expect(h.usersRepo.loads, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('refresh_required=true refreshes silently and keeps data', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    var sawLoading = false;
    void spy() => sawLoading |= h.tasks.isLoading || h.projects.isLoading;
    h.tasks.addListener(spy);
    h.projects.addListener(spy);
    addTearDown(() {
      h.tasks.removeListener(spy);
      h.projects.removeListener(spy);
    });

    h.changes.refresh = true;
    h.tasksRepo.title = 'Geänderte Aufgabe';
    await tester.pump(_poll);
    await tester.pump();
    expect(sawLoading, isFalse);
    expect(h.tasksRepo.loads, 2);
    expect(h.projectsRepo.loads, 2);
    expect(h.usersRepo.loads, 2);
    expect(find.text('Geänderte Aufgabe', skipOffstage: false), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    h.changes.refresh = false;
    await tester.pump(_poll);
    expect(h.changes.afters.last, 'c2');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('failed silent refresh keeps data, shows banner, keeps cursor', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    h.changes.refresh = true;
    h.tasksRepo.fail = true;
    await tester.pump(_poll);
    await tester.pump();
    expect(h.tasks.tasks.single.title, 'Erste Aufgabe');
    expect(h.tasks.errorMessage, isNull);
    expect(find.byKey(const ValueKey('change-poll-error')), findsOneWidget);

    // Backoff: nach 5s noch kein neuer Versuch, nach 10s mit altem Cursor.
    h.changes.refresh = false;
    await tester.pump(_poll);
    expect(h.changes.afters, [null, 'c1']);
    h.tasksRepo.fail = false;
    await tester.pump(_poll);
    await tester.pump();
    expect(h.changes.afters, [null, 'c1', 'c1']);
    expect(h.tasksRepo.loads, 3);
    expect(find.byKey(const ValueKey('change-poll-error')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('401 stops polling and shows session message', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    h.changes.error = const ApiException(
      statusCode: 401,
      message: 'Nicht autorisiert.',
    );
    await tester.pump(_poll);
    await tester.pump();
    expect(find.textContaining('Sitzung abgelaufen'), findsOneWidget);
    expect(find.byKey(const ValueKey('change-poll-retry')), findsNothing);
    await tester.pump(const Duration(minutes: 5));
    expect(h.changes.afters, hasLength(2));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('pauses in background and polls immediately on resume', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    void go(List<AppLifecycleState> states) {
      for (final state in states) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
    }

    go(const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]);
    await tester.pump(const Duration(minutes: 1));
    expect(h.changes.afters, [null]);

    go(const [AppLifecycleState.hidden, AppLifecycleState.inactive]);
    await tester.pump(const Duration(minutes: 1));
    expect(h.changes.afters, [null]);

    go(const [AppLifecycleState.resumed]);
    await tester.pump();
    expect(h.changes.afters, [null, 'c1']);
    await tester.pump(_poll);
    expect(h.changes.afters, [null, 'c1', 'c2']);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('manual refresh stays immediate with loading state', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    var sawLoading = false;
    void spy() => sawLoading |= h.tasks.isLoading;
    h.tasks.addListener(spy);
    addTearDown(() => h.tasks.removeListener(spy));
    await tester.tap(find.byKey(const ValueKey('user-profile-refresh')));
    await tester.pump();
    expect(sawLoading, isTrue);
    expect(h.tasksRepo.loads, 2);
    expect(h.projectsRepo.loads, 2);
    expect(h.usersRepo.loads, 2);
    expect(h.changes.afters, [null]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('logout and dispose stop polling', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.tap(find.byKey(const ValueKey('user-profile-logout')));
    await tester.pump();
    expect(h.logouts, 1);
    await tester.pump(const Duration(minutes: 1));
    expect(h.changes.afters, [null]);

    final other = _Harness();
    await tester.pumpWidget(const SizedBox());
    await other.pump(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
    expect(other.changes.afters, [null]);
  });

  test('silent loads keep state on failure and report success', () async {
    final h = _Harness();
    expect(await h.tasks.loadTasks(), isTrue);
    h.tasksRepo.fail = true;
    expect(await h.tasks.loadTasks(silent: true), isFalse);
    expect(h.tasks.tasks, hasLength(1));
    expect(h.tasks.errorMessage, isNull);
    expect(await h.tasks.loadTasks(), isFalse);
    expect(h.tasks.tasks, isEmpty);
    expect(h.tasks.errorMessage, isNotNull);
    h.tasksRepo.fail = false;
    expect(await h.tasks.loadTasks(silent: true), isTrue);
    expect(h.tasks.errorMessage, isNull);
    expect(await h.projects.loadProjects(silent: true), isTrue);
    expect(await h.users.loadCurrentUser(silent: true), isTrue);
    h.tasks.dispose();
    h.projects.dispose();
    h.users.dispose();
  });

  testWidgets('silent refresh keeps open dialog draft and flags new rights', (
    tester,
  ) async {
    final log = <String>[];
    final repo = _Tasks(log);
    final controller = TaskController(
      taskRepository: repo,
      containerRepository: _Containers(),
      groupRepository: _Groups(),
      attachmentRepository: _Attachments(),
    );
    addTearDown(controller.dispose);
    await controller.loadTasks();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showTaskDialog(
                context,
                controller: controller,
                containerId: 1,
                task: controller.tasks.single,
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
    await tester.enterText(find.byType(TextFormField).first, 'Mein Entwurf');

    // Unveränderte Rechte: kein Hinweis, Entwurf bleibt.
    repo.title = 'Fremde Änderung';
    expect(await controller.loadTasks(silent: true), isTrue);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('task-dialog-remote-changed')),
      findsNothing,
    );
    expect(find.text('Mein Entwurf'), findsOneWidget);

    repo.canEdit = false;
    expect(await controller.loadTasks(silent: true), isTrue);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('task-dialog-remote-changed')),
      findsOneWidget,
    );
    expect(find.text('Mein Entwurf'), findsOneWidget);
  });
}
