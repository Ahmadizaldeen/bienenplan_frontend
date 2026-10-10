import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bienenplan_frontend/features/tasks/application/task_controller.dart';
import 'package:bienenplan_frontend/features/tasks/data/group_model.dart';
import 'package:bienenplan_frontend/features/tasks/data/group_repository.dart';
import 'package:bienenplan_frontend/features/tasks/presentation/task_dialog.dart';

class _FakeGroupRepository implements GroupRepositoryContract {
  @override
  Future<List<Group>> fetchGroupsForProject(int projectId) async {
    expect(projectId, 4);
    return const [
      Group(id: 1, name: 'Gruppe Eins'),
      Group(id: 2, name: 'Gruppe Zwei'),
    ];
  }

  @override
  Future<List<Group>> fetchGroupsForTask(int taskId) async => const [];

  @override
  @override
  Future<void> assignGroupToTask(int taskId, int groupId) async {}

  @override
  Future<void> removeGroupFromTask(int taskId, int groupId) async {}
}

void main() {
  testWidgets('task dialog fits a 320px phone', (tester) async {
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
                projectId: 4,
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
                projectId: 4,
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
}
