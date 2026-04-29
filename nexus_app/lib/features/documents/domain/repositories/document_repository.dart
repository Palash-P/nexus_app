import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/document.dart';

abstract class DocumentRepository {
  Future<Either<Failure, List<Document>>> getDocuments(String knowledgeBaseId);
  Future<Either<Failure, Document>> uploadDocument({
    required String knowledgeBaseId,
    required String filePath,
    required String fileName,
  });
  Future<Either<Failure, Document>> getDocumentDetail(String documentId);
  Future<Either<Failure, bool>> reprocessDocument(String documentId);
}