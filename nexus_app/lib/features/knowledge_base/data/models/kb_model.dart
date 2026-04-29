import '../../domain/entities/knowledge_base.dart';

class KBModel extends KnowledgeBase {
  const KBModel({
    required super.id,
    required super.name,
    required super.description,
    required super.documentCount,
    required super.totalChunks,
    required super.createdAt,
  });

  factory KBModel.fromJson(Map<String, dynamic> json) {
    return KBModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      documentCount: json['document_count'] as int? ?? 0,
      totalChunks: json['total_chunks'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}