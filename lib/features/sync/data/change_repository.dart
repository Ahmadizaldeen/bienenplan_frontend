import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import 'change_feed.dart';

abstract class ChangeRepositoryContract {
  /// Ohne [after] wird eine neue Baseline angelegt (refresh_required=false).
  Future<ChangeFeed> fetchChanges({String? after});
}

class ChangeRepository implements ChangeRepositoryContract {
  ChangeRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<ChangeFeed> fetchChanges({String? after}) async {
    final response = await _apiClient.get(
      after == null ? ApiEndpoints.changes : ApiEndpoints.changesAfter(after),
    );
    try {
      if (response is Map<String, dynamic>) {
        return ChangeFeed.fromJson(response);
      }
      throw const FormatException('Ungültiges Änderungs-Datenformat.');
    } on FormatException catch (error) {
      // Ein unbrauchbarer 2xx-Body ist ein Vertragsfehler und wird wie andere
      // API-Fehler typisiert weitergegeben.
      throw ApiException(
        statusCode: 200,
        message: error.message,
        responseBody: response?.toString(),
      );
    }
  }
}
