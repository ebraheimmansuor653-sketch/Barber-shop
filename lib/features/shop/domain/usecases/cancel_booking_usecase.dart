import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/use_cases/use_case.dart';
import '../repositories/shop_repository.dart';

class CancelBookingParams {
  final String shopId;
  final String bookingId;
  final bool cancelledByShop;

  const CancelBookingParams({
    required this.shopId,
    required this.bookingId,
    required this.cancelledByShop,
  });
}

class CancelBookingUseCase implements UseCase<Unit, CancelBookingParams> {
  final ShopRepository repository;

  CancelBookingUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call([CancelBookingParams? param]) {
    final p = param!;
    return repository.cancelBooking(
      shopId: p.shopId,
      bookingId: p.bookingId,
      cancelledByShop: p.cancelledByShop,
    );
  }
}
