import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/knowledge_base.dart';
import '../repositories/kb_repository.dart';

class CreateKBUsecase {
  final KBRepository repository;
  CreateKBUsecase(this.repository);

  Future<Either<Failure, KnowledgeBase>> call(CreateKBParams params) {
    return repository.createKnowledgeBase(
      name: params.name,
      description: params.description,
    );
  }
}

class CreateKBParams extends Equatable {
  final String name;
  final String description;
  const CreateKBParams({required this.name, required this.description});

  @override
  List<Object> get props => [name, description];
}