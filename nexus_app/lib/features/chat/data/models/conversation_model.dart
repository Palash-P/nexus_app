import '../../domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.knowledgeBaseId,
    required super.title,
    required super.messages,
    required super.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'].toString(),
      knowledgeBaseId: json['knowledge_base']?.toString() ?? '',
      title: json['title'] as String? ?? 'New conversation',
      messages: const [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}