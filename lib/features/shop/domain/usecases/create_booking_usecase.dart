import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/use_cases/use_case.dart';
import '../entities/booking_entity.dart';
import '../repositories/shop_repository.dart';

class CreateBookingParams {
  final String shopId;
  final String barberId;
  final String serviceId;
  final String customerName;
  final String customerPhone;
  final String? customerUserId;
  final DateTime date;
  final int startMinute;
  final int durationMinutes;
  final BookingSource source;

  const CreateBookingParams({
    required this.shopId,
    required this.barberId,
    required this.serviceId,
    required this.customerName,
    required this.customerPhone,
    required this.date,
    required this.startMinute,
    required this.durationMinutes,
    required this.source,
    this.customerUserId,
  });
}

/// Does not itself re-run the scheduling engine — the slot was already
/// shown as available by [GetAvailableSlotsUseCase]. The repository's
/// Firestore transaction is the actual, final authority on whether the
/// slot is still free; this use case just forwards the chosen slot to it
/// and surfaces a [Failure] if someone else took it first.
class CreateBookingUseCase
    implements UseCase<BookingEntity, CreateBookingParams> {
  final ShopRepository repository;

  CreateBookingUseCase(this.repository);

  @override
  Future<Either<Failure, BookingEntity>> call([CreateBookingParams? param]) {
    final p = param!;
    return repository.createBooking(
      shopId: p.shopId,
      barberId: p.barberId,
      serviceId: p.serviceId,
      customerName: p.customerName,
      customerPhone: p.customerPhone,
      customerUserId: p.customerUserId,
      date: p.date,
      startMinute: p.startMinute,
      durationMinutes: p.durationMinutes,
      source: p.source,
    );
  }
}
