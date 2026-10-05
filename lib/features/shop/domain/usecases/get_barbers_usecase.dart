import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/use_cases/use_case.dart';
import '../entities/barber_entity.dart';
import '../repositories/shop_repository.dart';

class GetBarbersUseCase implements UseCase<List<BarberEntity>, String> {
  final ShopRepository repository;

  GetBarbersUseCase(this.repository);

  @override
  Future<Either<Failure, List<BarberEntity>>> call([String? param]) {
    return repository.getBarbers(param!);
  }
}
