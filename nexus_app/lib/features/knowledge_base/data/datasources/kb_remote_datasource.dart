import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/kb_model.dart';

abstract class KBRemoteDatasource {
  Future<List<KBModel>> getKnowledgeBases();
  Future<KBModel> createKnowledgeBase({
    required String name,
    required String description,
  });
  Future<KBModel> getKnowledgeBaseDetail(String id);
}

class KBRemoteDatasourceImpl implements KBRemoteDatasource {
  final ApiClient apiClient;
  KBRemoteDatasourceImpl({required this.apiClient});

  @override
  Future<List<KBModel>> getKnowledgeBases() async {
    try {
      final response = await apiClient.get(ApiEndpoints.knowledgeBases);
      final data = response.data;
      final List<dynamic> results =
          data is List ? data : (data['results'] ?? data);
      return results.map((e) => KBModel.fromJson(e)).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<KBModel> createKnowledgeBase({
    required String name,
    required String description,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.knowledgeBases,
        data: {'name': name, 'description': description},
      );
      return KBModel.fromJson(response.data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<KBModel> getKnowledgeBaseDetail(String id) async {
    try {
      final response =
          await apiClient.get(ApiEndpoints.knowledgeBaseDetail(id));
      return KBModel.fromJson(response.data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}