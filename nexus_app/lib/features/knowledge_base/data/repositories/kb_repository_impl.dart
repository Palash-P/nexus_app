import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/knowledge_base.dart';
import '../../domain/repositories/kb_repository.dart';
import '../datasources/kb_remote_datasource.dart';

class KBRepositoryImpl implements KBRepository {
  final KBRemoteDatasource remoteDatasource;
  final NetworkInfo networkInfo;

  KBRepositoryImpl({
    required this.remoteDatasource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<KnowledgeBase>>> getKnowledgeBases() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final kbs = await remoteDatasource.getKnowledgeBases();
      return Right(kbs);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, KnowledgeBase>> createKnowledgeBase({
    required String name,
    required String description,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final kb = await remoteDatasource.createKnowledgeBase(
        name: name,
        description: description,
      );
      return Right(kb);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, KnowledgeBase>> getKnowledgeBaseDetail(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final kb = await remoteDatasource.getKnowledgeBaseDetail(id);
      return Right(kb);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}