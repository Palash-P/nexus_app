import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class StartConversationUsecase {
  final ChatRepository repository;
  StartConversationUsecase(this.repository);

  Future<Either<Failure, Conversation>> call(String knowledgeBaseId) {
    return repository.startConversation(knowledgeBaseId);
  }
}