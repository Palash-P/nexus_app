import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/knowledge_base.dart';

abstract class KBRepository {
  Future<Either<Failure, List<KnowledgeBase>>> getKnowledgeBases();
  Future<Either<Failure, KnowledgeBase>> createKnowledgeBase({
    required String name,
    required String description,
  });
  Future<Either<Failure, KnowledgeBase>> getKnowledgeBaseDetail(String id);
}