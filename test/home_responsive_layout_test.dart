import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bienenplan_frontend/core/theme/app_theme.dart';
import 'package:bienenplan_frontend/features/home/presentation/home_screen.dart';
import 'package:bienenplan_frontend/features/home/presentation/widgets/user_profile_sidebar.dart';
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
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    for (final width in [320.0, 390.0, 600.0, 800.0, 1280.0]) {
      testWidgets(
        'collapsible home layout fits ${width.toInt()}px in ${theme.brightness.name} mode',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final taskController = TaskController(
            taskRepository: _FakeTaskRepository(),
            containerRepository: _FakeContainerRepository(),
          );
          final projectRepository = _FakeProjectRepository();
          final userRepository = _FakeUserRepository();
          final projectController = ProjectController(
            projectRepository: projectRepository,
            projectLocalStore: _FakeProjectLocalStore(),
          );
          final userController = UserController(userRepository: userRepository);
          addTearDown(taskController.dispose);
          addTearDown(projectController.dispose);
          addTearDown(userController.dispose);

          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
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
          expect(
            find.text('Suche nach Aufgaben oder Projekten'),
            findsOneWidget,
          );
          final searchRect = tester.getRect(find.byType(TextField).first);
          final refreshRect = tester.getRect(
            find.byKey(const ValueKey('project-overview-refresh')),
          );
          final toggleRect = tester.getRect(
            find.byKey(const ValueKey('project-overview-toggle')),
          );
          expect(
            (searchRect.center.dy - refreshRect.center.dy).abs(),
            lessThan(1),
          );
          expect(
            (searchRect.center.dy - toggleRect.center.dy).abs(),
            lessThan(1),
          );
          await tester.tap(
            find.byKey(const ValueKey('project-overview-toggle')),
          );
          await tester.pumpAndSettle();
          expect(find.text('Projektübersicht'), findsNothing);
          expect(
            find.text('Suche nach Aufgaben oder Projekten'),
            findsOneWidget,
          );
          await tester.tap(
            find.byKey(const ValueKey('project-overview-toggle')),
          );
          await tester.pumpAndSettle();
          expect(
            find.text('Suche nach Aufgaben oder Projekten'),
            findsOneWidget,
          );
          expect(find.text('Abmelden'), findsNothing);
          final toggle = tester.widget<TextButton>(
            find.byKey(const ValueKey('profile-project-toggle')),
          );
          expect(
            toggle.style?.backgroundColor?.resolve({}),
            theme.colorScheme.surfaceContainer,
          );
          expect(
            toggle.style?.foregroundColor?.resolve({}),
            theme.colorScheme.onSurface,
          );
          await tester.tap(
            find.byKey(const ValueKey('profile-project-toggle')),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Abmelden'), findsOneWidget);

          await tester.tap(
            find.byKey(const ValueKey('profile-project-toggle')),
          );
          await tester.pumpAndSettle();
          expect(find.text('Abmelden'), findsNothing);
          expect(projectController.selectedProject?.id, 1);
          expect(projectRepository.fetchCount, 1);
          expect(userRepository.fetchCount, 1);

          await tester.tap(
            find.byKey(const ValueKey('profile-project-toggle')),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Zweites Projekt'));
          await tester.tap(find.text('Zweites Projekt'));
          await tester.pumpAndSettle();
          expect(projectController.selectedProject?.id, 2);
          await tester.ensureVisible(
            find.byKey(const ValueKey('profile-project-toggle')),
          );
          await tester.tap(
            find.byKey(const ValueKey('profile-project-toggle')),
          );
          await tester.pumpAndSettle();
          expect(find.text('Zweites Projekt'), findsOneWidget);

          userRepository.name = 'Aktualisierter Benutzer';
          await userController.loadCurrentUser();
          await tester.pumpAndSettle();
          expect(find.text('Aktualisierter Benutzer'), findsOneWidget);
          expect(projectRepository.fetchCount, 1);
          expect(userRepository.fetchCount, 2);

          tester.view.physicalSize = const Size(1000, 600);
          await tester.pumpAndSettle();
          expect(find.text('Abmelden'), findsNothing);
          expect(find.text('Zweites Projekt'), findsOneWidget);

          await tester.ensureVisible(find.text('Keine Aufgaben vorhanden.'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('collapsed menu handles missing user and project', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserProfileSidebar(
            onLogout: () {},
            isExpanded: false,
            onToggle: () {},
          ),
        ),
      ),
    );

    expect(find.text('Benutzer'), findsOneWidget);
    expect(find.text('Kein Projekt'), findsOneWidget);
    expect(find.text('Abmelden'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile toggle preserves search and container states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final taskController = _PopulatedHomeTaskController();
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

    await tester.tap(find.byKey(const ValueKey('project-overview-toggle')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('container-toggle-1')),
    );
    await tester.tap(find.byKey(const ValueKey('container-toggle-1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profile-project-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-project-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('Suche nach Aufgaben oder Projekten'), findsOneWidget);
    expect(find.text('Projektübersicht'), findsNothing);
    expect(find.text('Persistenz-Testaufgabe'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('project-overview-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Projektübersicht'), findsOneWidget);
    expect(find.text('Persistenz-Testaufgabe'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('container-toggle-1')),
    );
    await tester.tap(find.byKey(const ValueKey('container-toggle-1')));
    await tester.pumpAndSettle();
    expect(find.text('Persistenz-Testaufgabe'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _PopulatedHomeTaskController extends TaskController {
  _PopulatedHomeTaskController()
    : super(
        taskRepository: _FakeTaskRepository(),
        containerRepository: _FakeContainerRepository(),
      );

  @override
  List<Task> get tasks => [
    Task(
      id: 1,
      containerId: 1,
      projectId: 1,
      createdBy: 1,
      title: 'Persistenz-Testaufgabe',
      description: '',
      status: 'in_progress',
      createdAt: '',
      updatedAt: '',
      containerTitle: 'Container 1',
      creatorName: 'Test',
    ),
  ];
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
  int fetchCount = 0;

  @override
  Future<List<Project>> fetchProjects() async {
    fetchCount++;
    return [
      const Project(
        id: 1,
        name: 'Ein besonders langer Projektname zur Prüfung kleiner Smartphone-Displays',
      ),
      const Project(id: 2, name: 'Zweites Projekt'),
    ];
  }
}

class _FakeProjectLocalStore implements ProjectLocalStoreContract {
  @override
  Future<int?> getSelectedProjectId() async => null;

  @override
  Future<void> setSelectedProjectId(int id) async {}
}

class _FakeUserRepository extends UserRepository {
  int fetchCount = 0;
  String name = 'Ein besonders langer Nutzername';

  @override
  Future<AppUser> fetchCurrentUser() async {
    fetchCount++;
    return AppUser(
      id: 1,
      name: name,
      email: 'long.user.name.for.small.screen@example.com',
    );
  }
}
