import 'package:equatable/equatable.dart';

abstract class DocumentEvent extends Equatable {
  const DocumentEvent();
  @override
  List<Object> get props => [];
}

class DocumentsLoadRequested extends DocumentEvent {
  final String knowledgeBaseId;
  const DocumentsLoadRequested({required this.knowledgeBaseId});
  @override
  List<Object> get props => [knowledgeBaseId];
}

class DocumentUploadRequested extends DocumentEvent {
  final String knowledgeBaseId;
  final String filePath;
  final String fileName;
  const DocumentUploadRequested({
    required this.knowledgeBaseId,
    required this.filePath,
    required this.fileName,
  });
  @override
  List<Object> get props => [knowledgeBaseId, filePath, fileName];
}

class DocumentPollingTick extends DocumentEvent {
  final String knowledgeBaseId;
  const DocumentPollingTick({required this.knowledgeBaseId});
  @override
  List<Object> get props => [knowledgeBaseId];
}

class DocumentReprocessRequested extends DocumentEvent {
  final String documentId;
  final String knowledgeBaseId;
  const DocumentReprocessRequested({
    required this.documentId,
    required this.knowledgeBaseId,
  });
  @override
  List<Object> get props => [documentId, knowledgeBaseId];
}