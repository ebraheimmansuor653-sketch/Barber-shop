import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/use_cases/use_case.dart';
import '../entities/service_entity.dart';
import '../repositories/shop_repository.dart';

class GetServicesUseCase implements UseCase<List<ServiceEntity>, String> {
  final ShopRepository repository;

  GetServicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<ServiceEntity>>> call([String? param]) {
    return repository.getServices(param!);
  }
}
