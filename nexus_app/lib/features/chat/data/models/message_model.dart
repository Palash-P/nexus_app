import '../../domain/entities/message.dart';

class CitationModel extends Citation {
  const CitationModel({
    required super.sourceTitle,
    super.pageNumber,
    super.confidence,
  });

  factory CitationModel.fromJson(Map<String, dynamic> json) {
    return CitationModel(
      sourceTitle: json['document_title'] as String? ??
          json['source'] as String? ??
          'Source',
      pageNumber: json['page_number'] as int?,
      confidence: (json['relevance_score'] as num?)?.toDouble(),
    );
  }
}

class MessageModel extends Message {
  final String? realConversationId;

  const MessageModel({
    required super.id,
    required super.role,
    required super.content,
    super.citations,
    required super.createdAt,
    super.isStreaming,
    this.realConversationId,
  });

  factory MessageModel.fromJson(
    Map<String, dynamic> json, {
    String? conversationId,
  }) {
    final rawSources = json['sources'];
    final List<Citation> citations = [];

    if (rawSources is List) {
      for (final s in rawSources) {
        if (s is Map<String, dynamic>) {
          citations.add(CitationModel.fromJson(s));
        }
      }
    }

    final realConvId = json['conversation_id']?.toString();

    return MessageModel(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: json['answer'] as String? ?? '',
      citations: citations,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      realConversationId: realConvId,
    );
  }
}