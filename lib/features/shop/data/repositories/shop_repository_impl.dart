import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/safe_call.dart';
import '../../domain/entities/barber_entity.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/repositories/shop_repository.dart';
import '../datasources/shop_remote_data_source.dart';

class ShopRepositoryImpl implements ShopRepository {
  final ShopRemoteDataSource remoteDataSource;

  ShopRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<ShopEntity>>> getNearbyShops({
    required double latitude,
    required double longitude,
  }) {
    return safeCall(() => remoteDataSource.getNearbyShops(
          latitude: latitude,
          longitude: longitude,
        ));
  }

  @override
  Future<Either<Failure, ShopEntity>> getShop(String shopId) {
    return safeCall(() => remoteDataSource.getShop(shopId));
  }

  @override
  Future<Either<Failure, List<BarberEntity>>> getBarbers(String shopId) {
    return safeCall(() => remoteDataSource.getBarbers(shopId));
  }

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServices(String shopId) {
    return safeCall(() => remoteDataSource.getServices(shopId));
  }

  @override
  Future<Either<Failure, List<BookingEntity>>> getShopBookingsOnDate({
    required String shopId,
    required DateTime date,
  }) {
    return safeCall(() => remoteDataSource.getShopBookingsOnDate(
          shopId: shopId,
          date: date,
        ));
  }

  @override
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
  }) {
    return safeCall(() => remoteDataSource.createBooking(
          shopId: shopId,
          barberId: barberId,
          serviceId: serviceId,
          customerName: customerName,
          customerPhone: customerPhone,
          customerUserId: customerUserId,
          date: date,
          startMinute: startMinute,
          durationMinutes: durationMinutes,
          source: source,
        ));
  }

  @override
  Future<Either<Failure, Unit>> cancelBooking({
    required String shopId,
    required String bookingId,
    required bool cancelledByShop,
  }) {
    return safeCall(() async {
      await remoteDataSource.cancelBooking(
        shopId: shopId,
        bookingId: bookingId,
        cancelledByShop: cancelledByShop,
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> setBookingOutcome({
    required String shopId,
    required String bookingId,
    required BookingStatus outcome,
  }) {
    return safeCall(() async {
      await remoteDataSource.setBookingOutcome(
        shopId: shopId,
        bookingId: bookingId,
        outcome: outcome,
      );
      return unit;
    });
  }
}
