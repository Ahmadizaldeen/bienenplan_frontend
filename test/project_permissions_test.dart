import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bienenplan_frontend/core/api/api_client.dart';
import 'package:bienenplan_frontend/core/api/api_endpoints.dart';
import 'package:bienenplan_frontend/features/home/presentation/widgets/user_profile_sidebar.dart';
import 'package:bienenplan_frontend/features/projects/application/project_archive_controller.dart';
import 'package:bienenplan_frontend/features/projects/application/project_controller.dart';
import 'package:bienenplan_frontend/features/projects/data/project_archive_repository.dart';
import 'package:bienenplan_frontend/features/projects/data/project_group_model.dart';
import 'package:bienenplan_frontend/features/projects/data/project_model.dart';
import 'package:bienenplan_frontend/features/projects/presentation/project_archive_screen.dart';
import 'package:bienenplan_frontend/features/projects/presentation/project_groups_dialog.dart';
import 'package:bienenplan_frontend/features/projects/presentation/project_list_widget.dart';
import 'package:bienenplan_frontend/features/subtasks/data/subtask_model.dart';
import 'package:bienenplan_frontend/features/subtasks/data/subtask_repository.dart';
import 'package:bienenplan_frontend/features/tasks/data/container_model.dart'
    as model;
import 'package:bienenplan_frontend/features/tasks/data/task_attachment.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_attachment_repository.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_model.dart';
import 'package:bienenplan_frontend/features/user/application/user_controller.dart';
import 'package:bienenplan_frontend/features/user/data/user_model.dart';
import 'package:bienenplan_frontend/features/user/data/user_repository.dart';

import 'controllers_test.dart'
    show FakeProjectRepository, FakeProjectLocalStore;

const adminProject = Project(
  id: 7,
  name: 'Fremdes Projekt',
  canEdit: true,
  canDelete: true,
  canManageGroups: true,
);
const archivedProject = Project(
  id: 9,
  name: 'Altes Projekt',
  archivedAt: '2026-10-08 12:00:00',
  canRestore: true,
);

class _Projects extends FakeProjectRepository {
  bool restored = false;
  @override
  Future<List<Project>> fetchProjects() async => [adminProject];
  @override
  Future<List<ProjectGroup>> fetchAvailableGroups() async => const [
    ProjectGroup(id: 1, name: 'Dieses Projekt', projectId: 7),
    ProjectGroup(id: 2, name: 'Fremde lokale Gruppe', projectId: 8),
    ProjectGroup(id: 3, name: 'Global', isGlobal: true),
    ProjectGroup(id: 4, name: 'Altgruppe'),
    ProjectGroup(id: 5, name: 'Persönlich', personalUserId: 1),
  ];
}

class _Archive extends ProjectArchiveRepository {
  int? restoredId;
  bool fail = false;
  bool empty = false;
  @override
  Future<List<Project>> fetchArchivedProjects() async {
    if (fail) throw Exception('Archiv nicht erreichbar');
    return empty ? [] : [archivedProject];
  }

  @override
  Future<void> restore(int projectId) async {
    if (fail) throw Exception('Wiederherstellung verweigert');
    restoredId = projectId;
  }

  @override
  Future<ArchivedProjectContents> fetchContents(int projectId) async =>
      ArchivedProjectContents(
        containers: const [
          model.Container(id: 2, title: 'Archivcontainer', projectId: 9),
        ],
        tasks: [
          Task(
            id: 3,
            containerId: 2,
            projectId: 9,
            createdBy: 1,
            title: 'Archivaufgabe',
            description: 'Nur lesbare Beschreibung',
            status: 'open',
            createdAt: '',
            updatedAt: '',
            containerTitle: 'Archivcontainer',
            creatorName: 'Max',
          ),
        ],
      );
}

class _Subtasks implements SubtaskRepositoryContract {
  @override
  Future<SubtaskList> list(int taskId) async => SubtaskList(
    canCreate: false,
    items: const [
      Subtask(
        id: 4,
        taskId: 3,
        title: 'Archiv-Unteraufgabe',
        completed: true,
        canEdit: false,
        canDelete: false,
        canComplete: false,
      ),
    ],
  );
  @override
  Future<Subtask> create(int taskId, String title) =>
      throw StateError('Archiv ist schreibgeschützt');
  @override
  Future<Subtask> update(
    int taskId,
    int id, {
    String? title,
    bool? completed,
  }) => throw StateError('Archiv ist schreibgeschützt');
  @override
  Future<void> delete(int taskId, int id) =>
      throw StateError('Archiv ist schreibgeschützt');
}

class _Attachments extends TaskAttachmentRepository {
  @override
  Future<List<TaskAttachment>> list(int taskId) async => const [
    TaskAttachment(
      id: 1,
      originalName: 'Archivdatei.pdf',
      sizeBytes: 10,
      canDelete: false,
    ),
  ];
}

class _User extends UserRepository {
  _User(this.admin);
  final bool admin;
  @override
  Future<AppUser> fetchCurrentUser() async =>
      AppUser(id: 1, name: 'Max', email: 'max@example.test', isAdmin: admin);
}

class _Api extends ApiClient {
  final urls = <String>[];
  @override
  Future<dynamic> get(String url) async {
    urls.add(url);
    if (url == ApiEndpoints.archivedProjects) {
      return [
        {
          'id': 9,
          'name': 'Archiv',
          'can_restore': true,
          'archived_at': '2026-10-08',
        },
      ];
    }
    if (url == '${ApiEndpoints.containers}?project_id=9') {
      return [
        {'id': 2, 'title': 'Container', 'project_id': 9},
      ];
    }
    if (url == '${ApiEndpoints.tasks}?project_id=9') return <dynamic>[];
    throw StateError('Unerwarteter GET: $url');
  }

  @override
  Future<dynamic> post(String url, Map<String, dynamic> body) async {
    urls.add(url);
    expect(body, isEmpty);
    return {'message': 'Wiederhergestellt'};
  }
}

void main() {
  test('Admin and project capabilities accept backend boolean, integer and string flags', () {
    for (final flag in [true, 1, '1']) {
      expect(
        AppUser.fromJson({
          'id': 1,
          'name': 'Max',
          'email': 'm',
          'is_admin': flag,
        }).isAdmin,
        isTrue,
      );
      final project = Project.fromJson({
        'id': 7,
        'name': 'Fremd',
        'is_owner': false,
        'can_edit': flag,
        'can_delete': flag,
        'can_manage_groups': flag,
      });
      expect(project.isOwner, isFalse);
      expect(
        project.canEdit && project.canDelete && project.canManageGroups,
        isTrue,
      );
    }
    final project = Project.fromJson({
      'id': 1,
      'name': 'Ohne Rechte',
      'is_owner': true,
    });
    expect(project.canEdit, isFalse);
    expect(
      AppUser.fromJson({'id': 1, 'name': 'Max', 'email': 'm'}).isAdmin,
      isFalse,
    );
  });

  test(
    'Group scope parsing excludes personal, foreign and unclassified groups',
    () {
      final local = ProjectGroup.fromJson({
        'id': 1,
        'name': 'Lokal',
        'project_id': '7',
        'is_global': '0',
      });
      expect(local.isAvailableFor(7), isTrue);
      expect(local.isAvailableFor(8), isFalse);
      expect(
        ProjectGroup.fromJson({'id': 2, 'name': 'Global', 'is_global': '1'})
            .isAvailableFor(7),
        isTrue,
      );
      expect(
        ProjectGroup.fromJson({
          'id': 3,
          'name': 'Personal',
          'project_id': 7,
          'personal_user_id': '4',
        }).isAvailableFor(7),
        isFalse,
      );
      expect(const ProjectGroup(id: 4, name: 'Alt').isAvailableFor(7), isFalse);
    },
  );

  test('Archive API uses explicit project filters and restore route', () async {
    final api = _Api();
    final repository = ProjectArchiveRepository(apiClient: api);
    final projects = await repository.fetchArchivedProjects();
    expect(projects.single.canRestore, isTrue);
    final contents = await repository.fetchContents(9);
    expect(contents.containers.single.projectId, 9);
    expect(contents.tasks, isEmpty);
    await repository.restore(9);
    expect(api.urls, [
      ApiEndpoints.archivedProjects,
      '${ApiEndpoints.containers}?project_id=9',
      '${ApiEndpoints.tasks}?project_id=9',
      ApiEndpoints.restoreProject(9),
    ]);
  });

  test('Archive controller surfaces load/restore errors and retains failed project', () async {
    final repository = _Archive();
    final controller = ProjectArchiveController(repository: repository);
    await controller.load();
    repository.fail = true;
    expect(await controller.restore(archivedProject), isFalse);
    expect(controller.projects.single.id, 9);
    expect(controller.errorMessage, contains('verweigert'));
    await controller.load();
    expect(controller.errorMessage, contains('nicht erreichbar'));
    repository.fail = false;
    expect(await controller.restore(archivedProject), isTrue);
    expect(controller.projects, isEmpty);
    controller.dispose();
  });

  testWidgets('Admin can edit and archive a project without owning it', (
    tester,
  ) async {
    final repository = _Projects();
    final controller = ProjectController(
      projectRepository: repository,
      projectLocalStore: FakeProjectLocalStore(),
    );
    await controller.loadProjects();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProjectListWidget(controller: controller)),
      ),
    );
    final editButton = find.byTooltip('Projekt bearbeiten');
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pumpAndSettle();
    expect(find.text('Projektgruppen verwalten'), findsOneWidget);
    await tester.tap(find.text('Projekt archivieren'));
    await tester.pumpAndSettle();
    expect(find.text('Projekt archivieren?'), findsOneWidget);
    await tester.tap(find.text('Archivieren'));
    await tester.pumpAndSettle();
    expect(repository.archivedId, 7);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('Project assignment dialog only lists available group scope', (
    tester,
  ) async {
    final controller = ProjectController(
      projectRepository: _Projects(),
      projectLocalStore: FakeProjectLocalStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProjectGroupsDialog(
          project: adminProject,
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dieses Projekt'), findsOneWidget);
    expect(find.text('Global'), findsWidgets);
    expect(find.text('Fremde lokale Gruppe'), findsNothing);
    expect(find.text('Altgruppe'), findsNothing);
    expect(find.text('Persönlich'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('Sidebar archive entry is Admin-only', (tester) async {
    final projects = ProjectController(
      projectRepository: _Projects(),
      projectLocalStore: FakeProjectLocalStore(),
    );
    for (final admin in [false, true]) {
      final users = UserController(userRepository: _User(admin));
      await users.loadCurrentUser();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: UserProfileSidebar(
                isExpanded: true,
                onToggle: () {},
                onLogout: () {},
                projectController: projects,
                userController: users,
              ),
            ),
          ),
        ),
      );
      expect(
        find.text('Admin-Bereich · Projektarchiv'),
        admin ? findsOneWidget : findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
      users.dispose();
    }
    projects.dispose();
  });

  testWidgets(
    'Archive viewing has no mutations; restore requires confirmation',
    (tester) async {
      final repository = _Archive();
      final projects = ProjectController(
        projectRepository: _Projects(),
        projectLocalStore: FakeProjectLocalStore(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectArchiveScreen(
            projectController: projects,
            repository: repository,
            subtaskRepository: _Subtasks(),
            attachmentRepository: _Attachments(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Archiviert'), findsOneWidget);
      await tester.tap(find.text('Ansehen'));
      await tester.pumpAndSettle();
      expect(find.text('Archiviert – nur lesen'), findsOneWidget);
      expect(find.text('Archivcontainer'), findsOneWidget);
      await tester.tap(find.text('Archivaufgabe'));
      await tester.pumpAndSettle();
      expect(find.text('Archiv-Unteraufgabe'), findsOneWidget);
      expect(find.text('Archivdatei.pdf'), findsOneWidget);
      expect(find.byTooltip('Anhang herunterladen'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wiederherstellen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(repository.restoredId, isNull);
      await tester.tap(find.text('Wiederherstellen'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Wiederherstellen').last,
      );
      await tester.pumpAndSettle();
      expect(repository.restoredId, 9);
      expect(find.text('Altes Projekt'), findsNothing);
      expect(projects.projects.single.id, 7);
      await tester.pumpWidget(const SizedBox());
      projects.dispose();
    },
  );

  testWidgets(
    'Archive displays API errors and empty state without a success fallback',
    (tester) async {
      final repository = _Archive()..fail = true;
      final projects = ProjectController(
        projectRepository: _Projects(),
        projectLocalStore: FakeProjectLocalStore(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectArchiveScreen(
            projectController: projects,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Archiv nicht erreichbar'), findsOneWidget);
      expect(find.text('Keine archivierten Projekte.'), findsNothing);
      repository
        ..fail = false
        ..empty = true;
      await tester.tap(find.byTooltip('Archiv aktualisieren'));
      await tester.pumpAndSettle();
      expect(find.text('Keine archivierten Projekte.'), findsOneWidget);
      expect(find.textContaining('Archiv nicht erreichbar'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      projects.dispose();
    },
  );

  testWidgets('Archive page and restore confirmation fit a 320px screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final projects = ProjectController(
      projectRepository: _Projects(),
      projectLocalStore: FakeProjectLocalStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProjectArchiveScreen(
          projectController: projects,
          repository: _Archive(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Wiederherstellen'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    projects.dispose();
  });
}
