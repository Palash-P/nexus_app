import '../../domain/entities/document.dart';

class DocumentModel extends Document {
  const DocumentModel({
    required super.id,
    required super.name,
    required super.fileType,
    required super.status,
    required super.chunkCount,
    required super.knowledgeBaseId,
    required super.uploadedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'].toString(),
      name: json['title'] as String? ?? 'Untitled',
      fileType: json['file_type'] as String? ?? 'file',
      status: _parseStatus(json['status'] as String? ?? 'pending'),
      chunkCount: json['total_chunks'] as int? ?? 0,
      knowledgeBaseId: json['knowledge_base'].toString(),
      uploadedAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static DocumentStatus _parseStatus(String raw) {
    return switch (raw.toLowerCase()) {
      'ready' || 'completed' => DocumentStatus.ready,
      'processing' => DocumentStatus.processing,
      'failed' || 'error' => DocumentStatus.failed,
      _ => DocumentStatus.pending,
    };
  }
}