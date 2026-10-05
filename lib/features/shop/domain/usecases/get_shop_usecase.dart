import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/use_cases/use_case.dart';
import '../entities/shop_entity.dart';
import '../repositories/shop_repository.dart';

class GetShopUseCase implements UseCase<ShopEntity, String> {
  final ShopRepository repository;

  GetShopUseCase(this.repository);

  @override
  Future<Either<Failure, ShopEntity>> call([String? param]) {
    return repository.getShop(param!);
  }
}
