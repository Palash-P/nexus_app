import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/document_remote_datasource.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentRemoteDatasource remoteDatasource;
  final NetworkInfo networkInfo;

  DocumentRepositoryImpl({
    required this.remoteDatasource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Document>>> getDocuments(
      String knowledgeBaseId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final docs = await remoteDatasource.getDocuments(knowledgeBaseId);
      return Right(docs);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Document>> uploadDocument({
    required String knowledgeBaseId,
    required String filePath,
    required String fileName,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final doc = await remoteDatasource.uploadDocument(
        knowledgeBaseId: knowledgeBaseId,
        filePath: filePath,
        fileName: fileName,
      );
      return Right(doc);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Document>> getDocumentDetail(
      String documentId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final doc = await remoteDatasource.getDocumentDetail(documentId);
      return Right(doc);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> reprocessDocument(String documentId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDatasource.reprocessDocument(documentId);
      return const Right(true);
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}