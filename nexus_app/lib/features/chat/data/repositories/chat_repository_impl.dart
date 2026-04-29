import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDatasource remoteDatasource;
  final NetworkInfo networkInfo;

  ChatRepositoryImpl({
    required this.remoteDatasource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Conversation>> startConversation(
      String knowledgeBaseId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final conv = await remoteDatasource.startConversation(knowledgeBaseId);
      return Right(conv);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Message>> sendMessage({
    required String conversationId,
    required String message,
    required String knowledgeBaseId,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final msg = await remoteDatasource.sendMessage(
        conversationId: conversationId,
        message: message,
        knowledgeBaseId: knowledgeBaseId,
      );
      return Right(msg);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Conversation>>> getConversations(
      String knowledgeBaseId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final convs =
          await remoteDatasource.getConversations(knowledgeBaseId);
      return Right(convs);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}