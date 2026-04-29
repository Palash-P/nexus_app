import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class LogoutUsecase {
  final AuthRepository repository;
  LogoutUsecase(this.repository);

  Future<Either<Failure, bool>> call() => repository.logout();
}