import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/document.dart';
import '../repositories/document_repository.dart';

class GetDocumentsUsecase {
  final DocumentRepository repository;
  GetDocumentsUsecase(this.repository);

  Future<Either<Failure, List<Document>>> call(String knowledgeBaseId) {
    return repository.getDocuments(knowledgeBaseId);
  }
}