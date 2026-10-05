import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/use_cases/use_case.dart';
import '../entities/booking_entity.dart';
import '../repositories/shop_repository.dart';

class SetBookingOutcomeParams {
  final String shopId;
  final String bookingId;
  final BookingStatus outcome;

  const SetBookingOutcomeParams({
    required this.shopId,
    required this.bookingId,
    required this.outcome,
  });
}

class SetBookingOutcomeUseCase
    implements UseCase<Unit, SetBookingOutcomeParams> {
  final ShopRepository repository;

  SetBookingOutcomeUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call([SetBookingOutcomeParams? param]) {
    final p = param!;
    return repository.setBookingOutcome(
      shopId: p.shopId,
      bookingId: p.bookingId,
      outcome: p.outcome,
    );
  }
}
