import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String username,
    required String password,
  });
  Future<Either<Failure, bool>> logout();
  Future<Either<Failure, bool>> isLoggedIn();
}