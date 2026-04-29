import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/document.dart';
import '../repositories/document_repository.dart';

class UploadDocumentUsecase {
  final DocumentRepository repository;
  UploadDocumentUsecase(this.repository);

  Future<Either<Failure, Document>> call(UploadParams params) {
    return repository.uploadDocument(
      knowledgeBaseId: params.knowledgeBaseId,
      filePath: params.filePath,
      fileName: params.fileName,
    );
  }
}

class UploadParams extends Equatable {
  final String knowledgeBaseId;
  final String filePath;
  final String fileName;
  const UploadParams({
    required this.knowledgeBaseId,
    required this.filePath,
    required this.fileName,
  });

  @override
  List<Object> get props => [knowledgeBaseId, filePath, fileName];
}