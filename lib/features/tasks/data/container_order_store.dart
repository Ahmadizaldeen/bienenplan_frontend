import 'package:shared_preferences/shared_preferences.dart';

abstract class ContainerOrderStoreContract {
  Future<List<int>> loadOrder({required int userId, int? projectId});

  Future<void> saveOrder({
    required int userId,
    int? projectId,
    required List<int> containerIds,
  });
}

class SharedPreferencesContainerOrderStore
    implements ContainerOrderStoreContract {
  const SharedPreferencesContainerOrderStore();

  // Keep each account's order separate, including its all-project overview.
  String _key(int userId, int? projectId) =>
      'container_order_v1_user_${userId}_${projectId ?? 'all'}';

  @override
  Future<List<int>> loadOrder({required int userId, int? projectId}) async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(_key(userId, projectId));
    if (values == null) return const [];

    return values.map((value) {
      final id = int.tryParse(value);
      if (id == null) {
        throw FormatException(
          'Ungültige Container-ID in gespeicherter Sortierung.',
        );
      }
      return id;
    }).toList();
  }

  @override
  Future<void> saveOrder({
    required int userId,
    int? projectId,
    required List<int> containerIds,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _key(userId, projectId),
      containerIds.map((id) => id.toString()).toList(),
    );
  }
}
