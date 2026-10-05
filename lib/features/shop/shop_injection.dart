import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/di/injection_container.dart';
import 'data/datasources/shop_remote_data_source.dart';
import 'data/repositories/shop_repository_impl.dart';
import 'domain/repositories/shop_repository.dart';
import 'domain/services/scheduling_engine.dart';
import 'domain/usecases/cancel_booking_usecase.dart';
import 'domain/usecases/create_booking_usecase.dart';
import 'domain/usecases/get_available_slots_usecase.dart';
import 'domain/usecases/get_barbers_usecase.dart';
import 'domain/usecases/get_services_usecase.dart';
import 'domain/usecases/get_shop_bookings_on_date_usecase.dart';
import 'domain/usecases/get_shop_usecase.dart';
import 'domain/usecases/set_booking_outcome_usecase.dart';
import 'presentation/manager/booking_flow/booking_flow_cubit.dart';

void initShop() {
  // State Management
  //
  // BookingFlowCubit takes no constructor args beyond its use cases, so it
  // follows the same sl.registerFactory() pattern as every other Cubit here.
  //
  // ShopBookingsCubit is NOT registered here: it needs a specific shopId
  // at construction time (a runtime value, not known at DI-setup time), so
  // the bookings-management screen builds it directly —
  // `ShopBookingsCubit(shopId, sl(), sl(), sl(), sl())` — pulling its four
  // use cases from sl() the same way, just without going through a
  // zero-arg factory registration for the Cubit itself.
  sl.registerFactory(() => BookingFlowCubit(
        sl(), sl(), sl(), sl(), sl(), sl(),
      ));

  // Use Cases
  sl.registerLazySingleton(() => GetShopUseCase(sl()));
  sl.registerLazySingleton(() => GetBarbersUseCase(sl()));
  sl.registerLazySingleton(() => GetServicesUseCase(sl()));
  sl.registerLazySingleton(() => GetAvailableSlotsUseCase(sl(), sl()));
  sl.registerLazySingleton(() => GetShopBookingsOnDateUseCase(sl()));
  sl.registerLazySingleton(() => CreateBookingUseCase(sl()));
  sl.registerLazySingleton(() => CancelBookingUseCase(sl()));
  sl.registerLazySingleton(() => SetBookingOutcomeUseCase(sl()));

  // Domain Services
  sl.registerLazySingleton(() => const SchedulingEngine());

  // Repository
  sl.registerLazySingleton<ShopRepository>(
    () => ShopRepositoryImpl(sl<ShopRemoteDataSource>()),
  );

  // Data Sources
  //
  // FirebaseFirestore itself is registered here too, not in initCore(),
  // because the shop feature is currently its only consumer. Move this
  // one line up into initCore() if another feature needs Firestore later.
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<ShopRemoteDataSource>(
    () => ShopRemoteDataSourceImpl(sl<FirebaseFirestore>()),
  );
}
