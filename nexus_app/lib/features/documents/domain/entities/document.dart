import 'package:equatable/equatable.dart';

enum DocumentStatus { pending, processing, ready, failed }

class Document extends Equatable {
  final String id;
  final String name;
  final String fileType;
  final DocumentStatus status;
  final int chunkCount;
  final String knowledgeBaseId;
  final DateTime uploadedAt;

  const Document({
    required this.id,
    required this.name,
    required this.fileType,
    required this.status,
    required this.chunkCount,
    required this.knowledgeBaseId,
    required this.uploadedAt,
  });

  bool get isReady => status == DocumentStatus.ready;
  bool get isProcessing =>
      status == DocumentStatus.processing || status == DocumentStatus.pending;
  bool get isFailed => status == DocumentStatus.failed;

  @override
  List<Object> get props =>
      [id, name, fileType, status, chunkCount, knowledgeBaseId, uploadedAt];
}