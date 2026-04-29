import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/knowledge_base.dart';
import '../repositories/kb_repository.dart';

class GetKnowledgeBasesUsecase {
  final KBRepository repository;
  GetKnowledgeBasesUsecase(this.repository);

  Future<Either<Failure, List<KnowledgeBase>>> call() {
    return repository.getKnowledgeBases();
  }
}