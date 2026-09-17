import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class ProjectLocalStoreContract {
  Future<int?> getSelectedProjectId();
  Future<void> setSelectedProjectId(int id);
}

/// Persistiert die zuletzt ausgewählte Projekt-ID lokal auf dem Gerät.
/// Das Backend kennt kein "aktives Projekt" – die Auswahl ist reiner
/// Client-Zustand und muss daher nicht mit der API synchronisiert werden.
class ProjectLocalStore implements ProjectLocalStoreContract {
  ProjectLocalStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'selected_project_id';
  final FlutterSecureStorage _storage;

  @override
  Future<int?> getSelectedProjectId() async {
    final value = await _storage.read(key: _key);
    return value != null ? int.tryParse(value) : null;
  }

  @override
  Future<void> setSelectedProjectId(int id) async {
    await _storage.write(key: _key, value: id.toString());
  }
}