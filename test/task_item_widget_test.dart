import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bienenplan_frontend/features/tasks/data/task_model.dart';
import 'package:bienenplan_frontend/features/tasks/presentation/task_item_widget.dart';

void main() {
  Task createTask(String status) => Task(
    id: 1,
    containerId: 1,
    createdBy: 1,
    title: 'Testaufgabe',
    description: '',
    status: status,
    createdAt: '',
    updatedAt: '',
    containerTitle: 'Test',
    creatorName: 'Test',
  );

  testWidgets('displays open status as Offen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskItemWidget(
            task: createTask('open'),
            showContainerBadge: false,
          ),
        ),
      ),
    );

    expect(find.text('Offen'), findsOneWidget);
  });

  testWidgets('displays blank status as Offen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskItemWidget(task: createTask(''), showContainerBadge: false),
        ),
      ),
    );

    expect(find.text('Offen'), findsOneWidget);
  });

  testWidgets('shows task title and status without overflow on a narrow card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: TaskItemWidget(task: createTask('in_progress')),
          ),
        ),
      ),
    );

    expect(find.text('Testaufgabe'), findsOneWidget);
    expect(find.text('In Bearbeitung'), findsOneWidget);
    final titleRect = tester.getRect(find.text('Testaufgabe'));
    final statusRect = tester.getRect(find.text('In Bearbeitung'));
    expect((titleRect.center.dy - statusRect.center.dy).abs(), lessThan(1));
    expect(tester.takeException(), isNull);
  });

  test('defaults a blank API status to open', () {
    final task = Task.fromJson({
      'id': 1,
      'container_id': 1,
      'created_by': 1,
      'title': 'Testaufgabe',
      'description': '',
      'status': '',
      'created_at': '',
      'updated_at': '',
    });

    expect(task.status, 'open');
  });
}
