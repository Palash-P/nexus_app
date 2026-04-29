import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/document_model.dart';

abstract class DocumentRemoteDatasource {
  Future<List<DocumentModel>> getDocuments(String knowledgeBaseId);
  Future<DocumentModel> uploadDocument({
    required String knowledgeBaseId,
    required String filePath,
    required String fileName,
  });
  Future<DocumentModel> getDocumentDetail(String documentId);
  Future<bool> reprocessDocument(String documentId);
}

class DocumentRemoteDatasourceImpl implements DocumentRemoteDatasource {
  final ApiClient apiClient;
  DocumentRemoteDatasourceImpl({required this.apiClient});

  @override
  Future<List<DocumentModel>> getDocuments(String knowledgeBaseId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.documents,
        queryParams: {'knowledge_base': knowledgeBaseId},
      );
      final data = response.data;
      final List<dynamic> results =
          data is List ? data : (data['results'] ?? []);
      return results.map((e) => DocumentModel.fromJson(e)).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<DocumentModel> uploadDocument({
    required String knowledgeBaseId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'knowledge_base': knowledgeBaseId,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response =
          await apiClient.postFormData(ApiEndpoints.documents, formData: formData);
      return DocumentModel.fromJson(response.data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<DocumentModel> getDocumentDetail(String documentId) async {
    try {
      final response =
          await apiClient.get('${ApiEndpoints.documents}$documentId/');
      return DocumentModel.fromJson(response.data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> reprocessDocument(String documentId) async {
    try {
      await apiClient.post(ApiEndpoints.reprocessDocument(documentId));
      return true;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}