import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/mixin/cancelable_safe_cubit_mixin.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/services/scheduling_engine.dart';
import '../../../domain/usecases/create_booking_usecase.dart';
import '../../../domain/usecases/get_barbers_usecase.dart';
import '../../../domain/usecases/get_services_usecase.dart';
import '../../../domain/usecases/get_shop_bookings_on_date_usecase.dart';
import '../../../domain/usecases/get_shop_usecase.dart';
import 'booking_flow_state.dart';

class BookingFlowCubit extends Cubit<BookingFlowState>
    with CancelableSafeCubitMixin<BookingFlowState> {
  final GetShopUseCase _getShop;
  final GetBarbersUseCase _getBarbers;
  final GetServicesUseCase _getServices;
  final GetShopBookingsOnDateUseCase _getShopBookingsOnDate;
  final CreateBookingUseCase _createBooking;
  final SchedulingEngine _engine;

  // Cached so selecting different barbers/services for the SAME date
  // doesn't re-fetch the same day's bookings from Firestore every time —
  // only a real date change re-queries it. The engine itself is pure, so
  // every slot computation after that first fetch is free.
  DateTime? _cachedBookingsDate;
  List<BookingEntity> _cachedBookings = const [];

  BookingFlowCubit(
    this._getShop,
    this._getBarbers,
    this._getServices,
    this._getShopBookingsOnDate,
    this._createBooking,
    this._engine,
  ) : super(const BookingFlowState());

  String get _shopId => state.shop!.id;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> loadShop(String shopId) async {
    safeEmit(state.copyWith(step: BookingFlowStep.loading));

    final shopResult = await runCancelable(_getShop.call(shopId));
    if (shopResult == null) return;

    await shopResult.fold(
      (failure) async =>
          safeEmit(state.copyWith(
              step: BookingFlowStep.error, errorMessage: failure.message)),
      (shop) async {
        final barbersResult = await runCancelable(_getBarbers.call(shopId));
        final servicesResult = await runCancelable(_getServices.call(shopId));
        if (barbersResult == null || servicesResult == null) return;

        barbersResult.fold(
          (failure) => safeEmit(state.copyWith(
              step: BookingFlowStep.error, errorMessage: failure.message)),
          (barbers) {
            servicesResult.fold(
              (failure) => safeEmit(state.copyWith(
                  step: BookingFlowStep.error,
                  errorMessage: failure.message)),
              (services) => safeEmit(state.copyWith(
                step: BookingFlowStep.ready,
                shop: shop,
                barbers: barbers,
                services: services,
              )),
            );
          },
        );
      },
    );
  }

  void selectService(String serviceId) {
    safeEmit(state.copyWith(
      selectedServiceId: serviceId,
      clearSelectedStartMinute: true,
      availableStartMinutes: const [],
    ));
    _reloadSlotsIfReady();
  }

  /// Pass null for "no preference" — any qualifying barber.
  void selectBarber(String? barberId) {
    safeEmit(state.copyWith(
      selectedBarberId: barberId,
      clearSelectedBarberId: barberId == null,
      clearSelectedStartMinute: true,
    ));
    _reloadSlotsIfReady();
  }

  void selectDate(DateTime date) {
    safeEmit(state.copyWith(
      selectedDate: date,
      clearSelectedStartMinute: true,
    ));
    _reloadSlotsIfReady();
  }

  void selectStartMinute(int minute) {
    safeEmit(state.copyWith(selectedStartMinute: minute));
  }

  Future<List<BookingEntity>?> _bookingsFor(DateTime date) async {
    if (_cachedBookingsDate != null && _sameDay(_cachedBookingsDate!, date)) {
      return _cachedBookings;
    }
    final result = await runCancelable(_getShopBookingsOnDate.call(
      GetShopBookingsOnDateParams(shopId: _shopId, date: date),
    ));
    if (result == null) return null;

    return result.fold(
      (failure) {
        safeEmit(state.copyWith(
            slotsLoading: false,
            step: BookingFlowStep.error,
            errorMessage: failure.message));
        return null;
      },
      (bookings) {
        _cachedBookingsDate = date;
        _cachedBookings = bookings;
        return bookings;
      },
    );
  }

  Future<void> _reloadSlotsIfReady() async {
    final service = state.selectedService;
    final date = state.selectedDate;
    if (service == null || date == null) return;

    safeEmit(state.copyWith(slotsLoading: true));

    final bookings = await _bookingsFor(date);
    if (bookings == null) return; // error already emitted, or cancelled

    if (state.selectedBarberId != null) {
      final barber =
          state.barbers.where((b) => b.id == state.selectedBarberId).firstOrNull;
      if (barber == null) return;

      final slots = _engine.availableStartMinutes(
        shop: state.shop!,
        barber: barber,
        date: date,
        serviceDurationMinutes: service.durationMinutes,
        shopBookingsOnDate: bookings,
      );
      safeEmit(state.copyWith(slotsLoading: false, availableStartMinutes: slots));
      return;
    }

    // No barber chosen: union the available times across every barber who
    // performs this service, so the customer sees the earliest time the
    // shop can offer regardless of who ends up assigned. All pure
    // computation now — the bookings fetch above already covers everyone.
    final union = <int>{};
    for (final barber
        in state.barbers.where((b) => b.performsService(service.id))) {
      union.addAll(_engine.availableStartMinutes(
        shop: state.shop!,
        barber: barber,
        date: date,
        serviceDurationMinutes: service.durationMinutes,
        shopBookingsOnDate: bookings,
      ));
    }
    final sorted = union.toList()..sort();
    safeEmit(state.copyWith(slotsLoading: false, availableStartMinutes: sorted));
  }

  Future<void> confirmBooking({
    required String customerName,
    required String customerPhone,
    String? customerUserId,
  }) async {
    final service = state.selectedService;
    final date = state.selectedDate;
    final startMinute = state.selectedStartMinute;
    if (service == null || date == null || startMinute == null) return;

    safeEmit(state.copyWith(step: BookingFlowStep.bookingInProgress));

    String? barberId = state.selectedBarberId;
    if (barberId == null) {
      // Resolve "no preference" to a concrete barber the same way the
      // slots were computed: earliest available, ties broken by fewest
      // bookings that day. Deliberately re-fetches (bypasses the cache)
      // right before writing, since a stale list here could assign a
      // barber who was actually just double-booked by someone else in
      // the few seconds since the slots were shown.
      _cachedBookingsDate = null;
      final bookings = await _bookingsFor(date);
      if (bookings == null) return;

      barberId = _engine
          .pickBarberForEarliestSlot(
            shop: state.shop!,
            barbers: state.barbers,
            serviceId: service.id,
            date: date,
            serviceDurationMinutes: service.durationMinutes,
            shopBookingsOnDate: bookings,
            desiredStartMinute: startMinute,
          )
          ?.id;

      if (barberId == null) {
        safeEmit(state.copyWith(
          step: BookingFlowStep.error,
          errorMessage:
              'This time was just taken — pick another available time.',
        ));
        return;
      }
    }

    final result = await runCancelable(_createBooking.call(
      CreateBookingParams(
        shopId: _shopId,
        barberId: barberId,
        serviceId: service.id,
        customerName: customerName,
        customerPhone: customerPhone,
        customerUserId: customerUserId,
        date: date,
        startMinute: startMinute,
        durationMinutes: service.durationMinutes,
        source: BookingSource.customerApp,
      ),
    ));
    if (result == null) return;

    result.fold(
      (failure) => safeEmit(state.copyWith(
          step: BookingFlowStep.error, errorMessage: failure.message)),
      (booking) => safeEmit(
          state.copyWith(step: BookingFlowStep.booked, confirmedBooking: booking)),
    );
  }
}
