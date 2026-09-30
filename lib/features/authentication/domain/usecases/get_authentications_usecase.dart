import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/use_cases/use_case.dart';
import '../entities/authentication_entity.dart';
import '../repositories/authentication_repository.dart';

class GetAuthenticationsUseCase
    implements UseCase<List<AuthenticationEntity>, NoParam> {
  final AuthenticationRepository repository;

  GetAuthenticationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AuthenticationEntity>>> call(
      [NoParam? param]) async {
    return repository.getAuthentications();
  }
}
