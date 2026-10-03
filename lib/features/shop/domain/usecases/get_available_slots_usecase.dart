import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/use_cases/use_case.dart';
import '../repositories/shop_repository.dart';
import '../services/scheduling_engine.dart';

class GetAvailableSlotsParams {
  final String shopId;
  final String barberId;
  final String serviceId;
  final DateTime date;

  const GetAvailableSlotsParams({
    required this.shopId,
    required this.barberId,
    required this.serviceId,
    required this.date,
  });
}

/// Returns the list of available start-times (minutes since midnight) for
/// one barber, one service, one day. The Cubit renders these as the
/// tappable time chips on the booking screen.
class GetAvailableSlotsUseCase
    implements UseCase<List<int>, GetAvailableSlotsParams> {
  final ShopRepository repository;
  final SchedulingEngine engine;

  GetAvailableSlotsUseCase(this.repository, this.engine);

  @override
  Future<Either<Failure, List<int>>> call(
      [GetAvailableSlotsParams? param]) async {
    final p = param!;

    final shopResult = await repository.getShop(p.shopId);
    final barbersResult = await repository.getBarbers(p.shopId);
    final servicesResult = await repository.getServices(p.shopId);
    final bookingsResult = await repository.getShopBookingsOnDate(
      shopId: p.shopId,
      date: p.date,
    );

    return shopResult.fold(Left.new, (shop) {
      return barbersResult.fold(Left.new, (barbers) {
        return servicesResult.fold(Left.new, (services) {
          return bookingsResult.fold(Left.new, (bookings) {
            final barber = barbers.firstWhere((b) => b.id == p.barberId);
            final service = services.firstWhere((s) => s.id == p.serviceId);

            final slots = engine.availableStartMinutes(
              shop: shop,
              barber: barber,
              date: p.date,
              serviceDurationMinutes: service.durationMinutes,
              shopBookingsOnDate: bookings,
            );
            return Right(slots);
          });
        });
      });
    });
  }
}
