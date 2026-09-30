import 'package:flutter_test/flutter_test.dart';
import 'package:bienenplan_frontend/core/api/api_client.dart';
import 'package:bienenplan_frontend/core/api/api_endpoints.dart';
import 'package:bienenplan_frontend/features/tasks/data/group_model.dart';
import 'package:bienenplan_frontend/features/tasks/data/group_repository.dart';

class _FakeApiClient extends ApiClient {
  final requestedUrls = <String>[];

  @override
  Future<dynamic> get(String url) async {
    requestedUrls.add(url);
    if (url == ApiEndpoints.groups) {
      return {
        'groups': [
          {'id': 1, 'name': 'Team Alpha', 'personal_user_id': null},
          {
            'id': 2,
            'name': 'Personal user 10',
            'personal_user_id': 10,
            'personal_user_name': 'Max Mustermann',
          },
          // Gelöschter Benutzer: Backend liefert keinen Namen.
          {
            'id': 3,
            'name': 'Personal user 11',
            'personal_user_id': 11,
            'personal_user_name': null,
          },
        ],
      };
    }
    throw UnimplementedError(url);
  }
}

void main() {
  test('parses personal user id from group name', () {
    expect(Group.parsePersonalUserId('Personal user 12'), 12);
    expect(Group.parsePersonalUserId('Personal User 7'), 7);
    expect(Group.parsePersonalUserId('Personal user 05'), isNull);
    expect(Group.parsePersonalUserId('Team A'), isNull);
  });

  test('uses personal_user_name as label, keeps team groups', () async {
    final apiClient = _FakeApiClient();
    final groups = await GroupRepository(apiClient: apiClient).fetchAllGroups();

    expect(groups.map((group) => group.label), [
      'Max Mustermann',
      'Personal user 11',
      'Team Alpha',
    ]);
    expect(groups.where((group) => group.isPersonal).length, 2);
    // Ein Request für alle Gruppen, keine Zusatz-Requests pro Gruppe.
    expect(apiClient.requestedUrls, [ApiEndpoints.groups]);
  });
}
