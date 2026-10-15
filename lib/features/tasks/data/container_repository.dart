import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'container_model.dart';

abstract class ContainerRepositoryContract {
  Future<List<Container>> fetchContainers();
  Future<Container> createContainer(String title, {int? projectId});
  Future<void> updateContainerTitle(int containerId, String title);
  Future<void> deleteContainer(int containerId);
}

class ContainerRepository implements ContainerRepositoryContract {
  ContainerRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<Container>> fetchContainers() async {
    final response = await _apiClient.get(ApiEndpoints.containers);
    final containers = response is Map<String, dynamic>
        ? response['data']
        : response;

    if (containers is List) {
      return containers
          .whereType<Map<String, dynamic>>()
          .map(Container.fromJson)
          .toList();
    }

    throw Exception('Ungültiges Container-Datenformat von API empfangen.');
  }

  @override
  Future<Container> createContainer(String title, {int? projectId}) async {
    final response = await _apiClient.post(ApiEndpoints.containers, {
      'title': title,
      'project_id': ?projectId,
    });

    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        return Container.fromJson(response['data'] as Map<String, dynamic>);
      }
      return Container.fromJson(response);
    }

    return Container(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      projectId: projectId,
    );
  }

  @override
  Future<void> updateContainerTitle(int containerId, String title) async {
    await _apiClient.put(ApiEndpoints.container(containerId), {'title': title});
  }

  @override
  Future<void> deleteContainer(int containerId) async {
    await _apiClient.delete(ApiEndpoints.container(containerId));
  }
}
