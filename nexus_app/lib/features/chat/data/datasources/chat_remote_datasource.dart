import 'package:flutter/foundation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

abstract class ChatRemoteDatasource {
  Future<ConversationModel> startConversation(String knowledgeBaseId);
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String message,
    required String knowledgeBaseId,
  });
  Future<List<ConversationModel>> getConversations(String knowledgeBaseId);
}

class ChatRemoteDatasourceImpl implements ChatRemoteDatasource {
  final ApiClient apiClient;
  ChatRemoteDatasourceImpl({required this.apiClient});

  @override
  Future<ConversationModel> startConversation(String knowledgeBaseId) async {
    // No API call — create a local session, real conv_id comes from first message
    return ConversationModel(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      knowledgeBaseId: knowledgeBaseId,
      title: 'New conversation',
      messages: const [],
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String message,
    required String knowledgeBaseId,
  }) async {
    try {
      final isNewConversation = conversationId.startsWith('new_');

      final body = <String, dynamic>{
        'knowledge_base_id': knowledgeBaseId,
        'message': message,
      };

      if (!isNewConversation) {
        body['conversation_id'] = conversationId;
      }

      // debugPrint('CHAT REQUEST BODY: $body');

      final response = await apiClient.post(ApiEndpoints.chat, data: body);
      // debugPrint('CHAT RESPONSE: ${response.data}');
      return MessageModel.fromJson(
        response.data as Map<String, dynamic>,
        conversationId: conversationId,
      );
    } on ServerException catch (e) {
      debugPrint('CHAT SERVER ERROR: ${e.message} | status: ${e.statusCode}');
      rethrow;
    } catch (e) {
      debugPrint('CHAT UNKNOWN ERROR: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ConversationModel>> getConversations(
      String knowledgeBaseId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.chat,
        queryParams: {'knowledge_base': knowledgeBaseId},
      );
      final data = response.data;
      final List<dynamic> results =
          data is List ? data : (data['results'] ?? []);
      return results
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}