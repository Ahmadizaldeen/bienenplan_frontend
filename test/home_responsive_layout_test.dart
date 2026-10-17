import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bienenplan_frontend/core/theme/app_theme.dart';
import 'package:bienenplan_frontend/features/home/presentation/home_screen.dart';
import 'package:bienenplan_frontend/features/chat/presentation/chat_screen.dart';
import 'package:bienenplan_frontend/features/home/presentation/widgets/home_top_bar.dart';
import 'package:bienenplan_frontend/features/home/presentation/widgets/user_profile_sidebar.dart';
import 'package:bienenplan_frontend/features/projects/application/project_controller.dart';
import 'package:bienenplan_frontend/features/projects/data/project_local_store.dart';
import 'package:bienenplan_frontend/features/projects/data/project_model.dart';
import 'package:bienenplan_frontend/features/projects/data/project_repository.dart';
import 'package:bienenplan_frontend/features/projects/presentation/project_list_widget.dart';
import 'package:bienenplan_frontend/features/sync/data/change_feed.dart';
import 'package:bienenplan_frontend/features/sync/data/change_repository.dart';
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
  testWidgets(
    'profile chat opens from the toolbar without a selected project',
    (tester) async {
      final projectController = ProjectController(
        projectRepository: _FakeProjectRepository(),
        projectLocalStore: _FakeProjectLocalStore(),
      );
      final userController = UserController(
        userRepository: _FakeUserRepository(),
      );
      addTearDown(projectController.dispose);
      addTearDown(userController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => HomeTopBar(
                userController: userController,
                projectController: projectController,
                onRefresh: () async {},
                onLogout: () {},
                onOpenProfile: () {},
                onOpenProjects: () {},
                onOpenAssistant: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ChatScreen()),
                ),
              ),
            ),
          ),
        ),
      );

      expect(projectController.selectedProject, isNull);
      final button = find.byKey(const ValueKey('user-profile-assistant'));
      expect(tester.widget<IconButton>(button).onPressed, isNotNull);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text('Alle aktiven Projekte'), findsOneWidget);
    },
  );

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    for (final width in [320.0, 390.0, 600.0, 800.0, 1280.0]) {
      testWidgets(
        'home toolbar and drawer fit ${width.toInt()}px in ${theme.brightness.name} mode',
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
                changeRepository: _NoChangesRepository(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Projektübersicht'), findsNothing);
          expect(find.byType(TextField), findsNothing);
          expect(
            find.byKey(const ValueKey('user-profile-refresh')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('user-profile-logout')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('user-profile-search-toggle')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('user-profile-assistant')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('home-current-project')),
            findsOneWidget,
          );
          expect(find.text('Hallo '), findsOneWidget);
          expect(find.text('Aktuelles Projekt'), findsOneWidget);
          final avatarRect = tester.getRect(
            find.byKey(const ValueKey('home-profile-avatar')),
          );
          final profileBarRect = tester.getRect(
            find.byKey(const ValueKey('home-top-bar')),
          );
          final logoutButtonRect = tester.getRect(
            find.byKey(const ValueKey('user-profile-logout')),
          );
          expect(profileBarRect.left, closeTo(AppSpacing.md, 1));
          expect(profileBarRect.contains(avatarRect.topLeft), isTrue);
          expect(profileBarRect.contains(logoutButtonRect.bottomRight), isTrue);
          await tester.tap(
            find.byKey(const ValueKey('user-profile-search-toggle')),
          );
          await tester.pumpAndSettle();
          expect(find.text('Projektübersicht'), findsNothing);
          expect(
            find.byKey(const ValueKey('user-profile-search-field')),
            findsOneWidget,
          );
          final searchFieldRect = tester.getRect(
            find.byKey(const ValueKey('user-profile-search-field')),
          );
          expect(profileBarRect.contains(searchFieldRect.topLeft), isTrue);
          expect(
            find.byKey(const ValueKey('user-profile-refresh')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('user-profile-logout')),
            findsOneWidget,
          );
          await tester.enterText(
            find.byKey(const ValueKey('user-profile-search-field')),
            'lokale Suche',
          );
          expect(find.text('lokale Suche'), findsOneWidget);
          await tester.tap(
            find.byKey(const ValueKey('user-profile-search-toggle')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('user-profile-search-field')),
            findsNothing,
          );
          expect(find.text('Abmelden'), findsNothing);
          await tester.tap(find.byKey(const ValueKey('home-user-name')));
          await tester.pumpAndSettle();
          expect(find.text('Profil & Einstellungen'), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('profile-sidebar-close')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('home-profile-avatar')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Profil & Einstellungen'), findsOneWidget);
          expect(find.text('Abmelden'), findsOneWidget);
          expect(find.text('Zweites Projekt'), findsNothing);
          expect(
            find.byKey(const ValueKey('project-info-button-2')),
            findsNothing,
          );

          await tester.tap(find.byKey(const ValueKey('profile-sidebar-close')));
          await tester.pumpAndSettle();
          expect(find.text('Abmelden'), findsNothing);
          expect(projectController.selectedProject?.id, 1);
          expect(projectRepository.fetchCount, 1);
          expect(userRepository.fetchCount, 1);

          await tester.tap(find.byKey(const ValueKey('home-current-project')));
          await tester.pumpAndSettle();
          expect(find.text('Projekte'), findsOneWidget);
          expect(find.text('Profil & Einstellungen'), findsNothing);
          expect(find.text('Abmelden'), findsNothing);
          await tester.ensureVisible(find.text('Zweites Projekt'));
          await tester.tap(find.text('Zweites Projekt'));
          await tester.pumpAndSettle();
          expect(projectController.selectedProject?.id, 2);
          await tester.tap(
            find.byKey(const ValueKey('projects-sidebar-close')),
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

  testWidgets('profile drawer renders without user and project controllers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UserProfileSidebar(onLogout: () {}),
          ),
        ),
      ),
    );

    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Abmelden'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('each project info button opens its statistics page', (
    tester,
  ) async {
    final controller = ProjectController(
      projectRepository: _FakeProjectRepository(),
      projectLocalStore: _FakeProjectLocalStore(),
    );
    await controller.loadProjects();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProjectListWidget(controller: controller)),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('project-info-button-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('project-info-button-2')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('project-info-button-2')));
    await tester.pumpAndSettle();

    expect(find.text('Zweites Projekt'), findsOneWidget);
    expect(find.text('Projektstatistiken'), findsOneWidget);
    expect(find.text('Aktiv'), findsOneWidget);
    expect(find.text('Erledigt'), findsOneWidget);
    expect(find.text('Heute'), findsOneWidget);
    expect(find.text('Weitere Statistiken folgen.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile drawer preserves container state', (tester) async {
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
          changeRepository: _NoChangesRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final topBar = tester.getRect(find.byKey(const ValueKey('home-top-bar')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('container-toggle-1')),
    );
    final firstContainer = tester.getRect(
      find.byKey(const ValueKey('container-toggle-1')),
    );
    expect(topBar.bottom, lessThan(firstContainer.top));

    await tester.ensureVisible(
      find.byKey(const ValueKey('container-toggle-1')),
    );
    await tester.tap(find.byKey(const ValueKey('container-toggle-1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-profile-avatar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-sidebar-close')));
    await tester.pumpAndSettle();

    expect(find.text('Projektübersicht'), findsNothing);
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

class _NoChangesRepository implements ChangeRepositoryContract {
  @override
  Future<ChangeFeed> fetchChanges({String? after}) async =>
      const ChangeFeed(nextCursor: 'cursor', refreshRequired: false);
}
