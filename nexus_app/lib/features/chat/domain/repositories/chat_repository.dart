import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/conversation.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  Future<Either<Failure, Conversation>> startConversation(
      String knowledgeBaseId);
  Future<Either<Failure, Message>> sendMessage({
    required String conversationId,
    required String message,
    required String knowledgeBaseId,
  });
  Future<Either<Failure, List<Conversation>>> getConversations(
      String knowledgeBaseId);
}