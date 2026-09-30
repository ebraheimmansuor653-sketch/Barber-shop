import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/authentication_entity.dart';

abstract class AuthenticationRepository {
  Future<Either<Failure, List<AuthenticationEntity>>> getAuthentications();
}
