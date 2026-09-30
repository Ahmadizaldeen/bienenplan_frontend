import 'package:bienenplan_frontend/features/tasks/application/task_controller.dart';
import 'package:bienenplan_frontend/features/tasks/data/container_model.dart'
    as container_model;
import 'package:bienenplan_frontend/features/tasks/data/task_model.dart';
import 'package:bienenplan_frontend/features/tasks/presentation/task_container_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PopulatedTaskController extends TaskController {
  @override
  List<Task> get tasks => [
    for (var index = 0; index < 3; index++)
      Task(
        id: index + 1,
        containerId: index + 1,
        createdBy: 1,
        title: 'Aufgabe $index',
        description: '',
        status: 'in_progress',
        createdAt: '',
        updatedAt: '',
        containerTitle: 'Container $index',
        creatorName: 'Test',
      ),
  ];

  @override
  List<container_model.Container> get extraContainers => const [];
}

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('task containers stack and scroll at ${width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _PopulatedTaskController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: TaskListScreen(controller: controller),
            ),
          ),
        ),
      );

      expect(find.text('Container 0'), findsOneWidget);
      expect(find.text('Aufgabe 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(TaskListScreen), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('Container 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
