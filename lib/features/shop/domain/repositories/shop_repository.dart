import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/barber_entity.dart';
import '../entities/booking_entity.dart';
import '../entities/service_entity.dart';
import '../entities/shop_entity.dart';

abstract class ShopRepository {
  Future<Either<Failure, List<ShopEntity>>> getNearbyShops({
    required double latitude,
    required double longitude,
  });

  Future<Either<Failure, ShopEntity>> getShop(String shopId);

  Future<Either<Failure, List<BarberEntity>>> getBarbers(String shopId);

  Future<Either<Failure, List<ServiceEntity>>> getServices(String shopId);

  Future<Either<Failure, List<BookingEntity>>> getShopBookingsOnDate({
    required String shopId,
    required DateTime date,
  });

  /// Creates the booking atomically: fails with [Failure] if the slot was
  /// taken by someone else in the meantime (barber conflict or the shop's
  /// chairs are all occupied at that time), rather than overwriting it.
  Future<Either<Failure, BookingEntity>> createBooking({
    required String shopId,
    required String barberId,
    required String serviceId,
    required String customerName,
    required String customerPhone,
    String? customerUserId,
    required DateTime date,
    required int startMinute,
    required int durationMinutes,
    required BookingSource source,
  });

  Future<Either<Failure, Unit>> cancelBooking({
    required String shopId,
    required String bookingId,
    required bool cancelledByShop,
  });

  Future<Either<Failure, Unit>> setBookingOutcome({
    required String shopId,
    required String bookingId,
    required BookingStatus outcome,
  });
}
