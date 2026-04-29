import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class SendMessageUsecase {
  final ChatRepository repository;
  SendMessageUsecase(this.repository);

  Future<Either<Failure, Message>> call(SendMessageParams params) {
    return repository.sendMessage(
      conversationId: params.conversationId,
      message: params.message,
      knowledgeBaseId: params.knowledgeBaseId,
    );
  }
}

class SendMessageParams extends Equatable {
  final String conversationId;
  final String message;
  final String knowledgeBaseId;

  const SendMessageParams({
    required this.conversationId,
    required this.message,
    required this.knowledgeBaseId,
  });

  @override
  List<Object> get props => [conversationId, message, knowledgeBaseId];
}