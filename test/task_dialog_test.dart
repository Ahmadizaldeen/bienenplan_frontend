import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bienenplan_frontend/features/tasks/application/task_controller.dart';
import 'package:bienenplan_frontend/features/tasks/data/group_model.dart';
import 'package:bienenplan_frontend/features/tasks/data/group_repository.dart';
import 'package:bienenplan_frontend/features/tasks/presentation/task_dialog.dart';
import 'package:bienenplan_frontend/features/user/data/user_model.dart';

class _FakeGroupRepository implements GroupRepositoryContract {
  String? createdGroupName;
  List<int>? createdGroupUserIds;

  @override
  Future<List<Group>> fetchAllGroups() async => const [
    Group(id: 1, name: 'Gruppe Eins'),
    Group(id: 2, name: 'Gruppe Zwei'),
  ];

  @override
  Future<List<Group>> fetchGroupsForTask(int taskId) async => const [];

  @override
  Future<List<GroupUser>> fetchAllUsers() async => const [
    GroupUser(id: 10, name: 'Max Mustermann'),
    GroupUser(id: 11, name: 'Erika Musterfrau'),
  ];

  @override
  Future<Group> createGroup(String name, {List<int> userIds = const []}) async {
    createdGroupName = name;
    createdGroupUserIds = userIds;
    return Group(id: 3, name: name);
  }

  @override
  Future<void> assignGroupToTask(int taskId, int groupId) async {}

  @override
  Future<void> removeGroupFromTask(int taskId, int groupId) async {}
}

void main() {
  testWidgets('task and group dialogs fit a 320px phone', (tester) async {
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
    await tester.ensureVisible(find.text('Neue Gruppe'));
    await tester.tap(find.text('Neue Gruppe'));
    await tester.pumpAndSettle();
    expect(find.text('Neue Gruppe erstellen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('creates a new group and selects it', (tester) async {
    final groupRepository = _FakeGroupRepository();
    final controller = TaskController(groupRepository: groupRepository);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showTaskDialog(
                context,
                controller: controller,
                containerId: 1,
              ),
              child: const Text('Dialog öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Dialog öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neue Gruppe'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'Neue Gruppe X');
    await tester.tap(find.text('Gruppe erstellen').last);
    await tester.pumpAndSettle();

    expect(groupRepository.createdGroupName, isNull);
    expect(
      find.text('Bitte mindestens einen Benutzer auswählen.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Max Mustermann'));
    await tester.tap(find.text('Gruppe erstellen').last);
    await tester.pumpAndSettle();

    expect(groupRepository.createdGroupName, 'Neue Gruppe X');
    expect(groupRepository.createdGroupUserIds, [10]);
    expect(find.byType(InputChip), findsOneWidget);
    expect(find.text('Neue Gruppe X'), findsOneWidget);
  });

  testWidgets('selects an existing group instead of creating a duplicate', (
    tester,
  ) async {
    final groupRepository = _FakeGroupRepository();
    final controller = TaskController(groupRepository: groupRepository);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showTaskDialog(
                context,
                controller: controller,
                containerId: 1,
              ),
              child: const Text('Dialog öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Dialog öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neue Gruppe'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'Gruppe Eins');
    await tester.tap(find.text('Max Mustermann'));
    await tester.tap(find.text('Gruppe erstellen').last);
    await tester.pumpAndSettle();

    expect(groupRepository.createdGroupName, isNull);
    expect(find.byType(InputChip), findsOneWidget);
    expect(
      find.text(
        'Die Gruppe existiert bereits und wurde ausgewählt; ihre Mitglieder wurden nicht geändert.',
      ),
      findsOneWidget,
    );
  });
}
