import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/use_cases/use_case.dart';
import '../entities/booking_entity.dart';
import '../repositories/shop_repository.dart';

class GetShopBookingsOnDateParams {
  final String shopId;
  final DateTime date;

  const GetShopBookingsOnDateParams({required this.shopId, required this.date});
}

class GetShopBookingsOnDateUseCase
    implements UseCase<List<BookingEntity>, GetShopBookingsOnDateParams> {
  final ShopRepository repository;

  GetShopBookingsOnDateUseCase(this.repository);

  @override
  Future<Either<Failure, List<BookingEntity>>> call(
      [GetShopBookingsOnDateParams? param]) {
    return repository.getShopBookingsOnDate(
      shopId: param!.shopId,
      date: param.date,
    );
  }
}
