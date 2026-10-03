import 'dart:async';

import 'package:bienenplan_frontend/core/api/api_client.dart';
import 'package:bienenplan_frontend/core/api/api_exception.dart';
import 'package:bienenplan_frontend/features/subtasks/application/subtask_controller.dart';
import 'package:bienenplan_frontend/features/subtasks/data/subtask_model.dart';
import 'package:bienenplan_frontend/features/subtasks/data/subtask_repository.dart';
import 'package:bienenplan_frontend/features/subtasks/presentation/widgets/subtask_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Subtask _item({
  int id = 1,
  String title = 'Erster Schritt',
  bool completed = false,
  bool manage = true,
}) => Subtask(
  id: id,
  taskId: 7,
  title: title,
  completed: completed,
  createdBy: 1,
  canEdit: manage,
  canDelete: manage,
  canComplete: true,
);

class _Repository implements SubtaskRepositoryContract {
  List<Subtask> items = [_item()];
  bool canCreate = true;
  bool fail = false;
  int loads = 0;
  Completer<SubtaskList>? pendingLoad;
  Completer<Subtask>? pendingUpdate;

  void _check() {
    if (fail) {
      throw const ApiException(statusCode: 403, message: 'Keine Berechtigung.');
    }
  }

  @override
  Future<SubtaskList> list(int taskId) async {
    loads++;
    _check();
    if (pendingLoad != null) return pendingLoad!.future;
    return SubtaskList(items: items, canCreate: canCreate);
  }

  @override
  Future<Subtask> create(int taskId, String title) async {
    _check();
    final item = _item(id: 10, title: title.trim());
    items = [...items, item];
    return item;
  }

  @override
  Future<Subtask> update(
    int taskId,
    int id, {
    String? title,
    bool? completed,
  }) async {
    _check();
    if (pendingUpdate != null) return pendingUpdate!.future;
    final old = items.firstWhere((item) => item.id == id);
    final updated = _item(
      id: id,
      title: title ?? old.title,
      completed: completed ?? old.completed,
      manage: old.canEdit,
    );
    items = items.map((item) => item.id == id ? updated : item).toList();
    return updated;
  }

  @override
  Future<void> delete(int taskId, int id) async {
    _check();
    items = items.where((item) => item.id != id).toList();
  }
}

class _Client extends ApiClient {
  Map<String, dynamic>? body;
  String? url;
  dynamic response = _item().toJson();

  @override
  Future<dynamic> put(String url, Map<String, dynamic> body) async {
    this.url = url;
    this.body = body;
    return response;
  }

  @override
  Future<dynamic> get(String url) async => response;
}

void main() {
  test(
    'repository sends only submitted fields and rejects malformed data',
    () async {
      final client = _Client();
      final repository = SubtaskRepository(apiClient: client);
      await repository.update(7, 1, completed: true);
      expect(client.body, {'completed': true});
      expect(client.url, endsWith('/api/tasks/7/subtasks/1'));
      await repository.update(7, 1, title: '  Neu  ');
      expect(client.body, {'title': 'Neu'});
      client.response = {'subtasks': [], 'can_create': true};
      expect((await repository.list(7)).canCreate, isTrue);
      client.response = {'subtasks': 'invalid'};
      await expectLater(repository.list(7), throwsA(isA<ApiException>()));
      client.response = {
        'subtasks': [{}],
        'can_create': true,
      };
      await expectLater(repository.list(7), throwsA(isA<ApiException>()));
    },
  );

  test('controller loads once, sorts, writes immediately and preserves data on failure', () async {
    final repository = _Repository()..items = [_item(id: 2), _item(id: 1)];
    final controller = SubtaskController(taskId: 7, repository: repository);
    addTearDown(controller.dispose);
    await controller.load();
    await controller.load();
    expect(repository.loads, 1);
    expect(controller.items.map((item) => item.id), [1, 2]);
    expect(await controller.create('Neu'), isTrue);
    expect(controller.items.last.title, 'Neu');
    expect(
      await controller.update(controller.items.first, completed: true),
      isTrue,
    );
    expect(controller.items.first.completed, isTrue);
    repository.fail = true;
    expect(await controller.delete(controller.items.first), isFalse);
    expect(controller.items, hasLength(3));
    expect(controller.error, 'Keine Berechtigung.');
    repository.fail = false;
    expect(
      await controller.update(controller.items.last, title: 'Umbenannt'),
      isTrue,
    );
    expect(controller.items.last.title, 'Umbenannt');
    expect(await controller.delete(controller.items.last), isTrue);
    expect(controller.items, hasLength(2));
  });

  test('failed load can retry and late load is safe after dispose', () async {
    final repository = _Repository()..fail = true;
    final controller = SubtaskController(taskId: 7, repository: repository);
    await controller.load();
    expect(controller.loaded, isFalse);
    repository.fail = false;
    repository.pendingLoad = Completer<SubtaskList>();
    final pending = controller.load();
    controller.dispose();
    repository.pendingLoad!.complete(SubtaskList(items: [], canCreate: true));
    await pending;
  });

  test('in-flight writes are serialized and safe after dispose', () async {
    final repository = _Repository();
    final controller = SubtaskController(taskId: 7, repository: repository);
    await controller.load();
    repository.pendingUpdate = Completer<Subtask>();
    final pending = controller.update(controller.items.first, completed: true);
    expect(controller.mutating, isTrue);
    expect(await controller.delete(controller.items.first), isFalse);
    controller.dispose();
    repository.pendingUpdate!.complete(_item(completed: true));
    expect(await pending, isFalse);
  });

  test(
    'member permissions block management but allow checkbox changes',
    () async {
      final repository = _Repository()
        ..canCreate = false
        ..items = [_item(manage: false)];
      final controller = SubtaskController(taskId: 7, repository: repository);
      addTearDown(controller.dispose);
      await controller.load();
      expect(await controller.create('No'), isFalse);
      expect(
        await controller.update(controller.items.first, title: 'No'),
        isFalse,
      );
      expect(await controller.delete(controller.items.first), isFalse);
      expect(
        await controller.update(controller.items.first, completed: true),
        isTrue,
      );
    },
  );

  for (final width in [320.0, 900.0]) {
    testWidgets('lazy checklist supports CRUD without overflow at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _Repository()
        ..items = [
          _item(
            title:
                'Ein langer Titel fuer die mobile Ansicht mit mehreren Zeilen',
          ),
        ];
      var changes = 0;
      final busy = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SubtaskSection(
                taskId: 7,
                repository: repository,
                onChanged: () => changes++,
                onBusyChanged: busy.add,
              ),
            ),
          ),
        ),
      );
      expect(repository.loads, 0);
      await tester.tap(find.text('Teilaufgaben'));
      await tester.pumpAndSettle();
      expect(repository.loads, 1);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(repository.items.first.completed, isTrue);
      expect(changes, 1);
      expect(busy, [true, false]);
      await tester.tap(find.text('Teilaufgabe hinzufuegen'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Zweiter Schritt');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(find.text('Zweiter Schritt'), findsOneWidget);
      await tester.tap(find.byTooltip('Teilaufgabe bearbeiten').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Umbenannt');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(find.text('Umbenannt'), findsOneWidget);
      await tester.tap(find.byTooltip('Teilaufgabe loeschen').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(find.text('Umbenannt'), findsOneWidget);
      await tester.tap(find.byTooltip('Teilaufgabe loeschen').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Loeschen'));
      await tester.pumpAndSettle();
      expect(find.text('Umbenannt'), findsNothing);
      await tester.tap(find.text('Teilaufgaben'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Teilaufgaben'));
      await tester.pumpAndSettle();
      expect(repository.loads, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'members see checkboxes only and failed writes retain the value',
    (tester) async {
      final repository = _Repository()
        ..canCreate = false
        ..items = [_item(manage: false)];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtaskSection(
              taskId: 7,
              repository: repository,
              onChanged: () {},
              onBusyChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('Teilaufgaben'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Teilaufgabe bearbeiten'), findsNothing);
      expect(find.byTooltip('Teilaufgabe loeschen'), findsNothing);
      expect(find.text('Teilaufgabe hinzufuegen'), findsNothing);
      repository.fail = true;
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      expect(find.text('Keine Berechtigung.'), findsOneWidget);
      repository.fail = false;
      await tester.tap(find.text('Erneut laden'));
      await tester.pumpAndSettle();
      expect(find.text('Keine Berechtigung.'), findsNothing);
    },
  );
}
