import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/mixin/cancelable_safe_cubit_mixin.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/usecases/cancel_booking_usecase.dart';
import '../../../domain/usecases/create_booking_usecase.dart';
import '../../../domain/usecases/get_shop_bookings_on_date_usecase.dart';
import '../../../domain/usecases/set_booking_outcome_usecase.dart';
import 'shop_bookings_state.dart';

/// Powers the "إدارة الحجوزات" screen for both roles:
/// - Shop owner: constructed with no barber lock, shows the "All" +
///   per-barber chips, sees everyone's bookings.
/// - Barber: the screen simply never calls [selectBarber] with a
///   different id and never shows the chips — load the day already
///   filtered to that barber by calling [loadDate] and then
///   [selectBarber] once with his own id right after.
class ShopBookingsCubit extends Cubit<ShopBookingsState>
    with CancelableSafeCubitMixin<ShopBookingsState> {
  final GetShopBookingsOnDateUseCase _getShopBookingsOnDate;
  final CreateBookingUseCase _createBooking;
  final CancelBookingUseCase _cancelBooking;
  final SetBookingOutcomeUseCase _setBookingOutcome;

  final String shopId;

  ShopBookingsCubit(
    this.shopId,
    this._getShopBookingsOnDate,
    this._createBooking,
    this._cancelBooking,
    this._setBookingOutcome,
  ) : super(ShopBookingsState(date: DateTime.now()));

  Future<void> loadDate(DateTime date) async {
    safeEmit(state.copyWith(step: ShopBookingsStep.loading, date: date));

    final result = await runCancelable(_getShopBookingsOnDate.call(
      GetShopBookingsOnDateParams(shopId: shopId, date: date),
    ));
    if (result == null) return;

    result.fold(
      (failure) => safeEmit(state.copyWith(
          step: ShopBookingsStep.error, errorMessage: failure.message)),
      (bookings) => safeEmit(
          state.copyWith(step: ShopBookingsStep.ready, bookings: bookings)),
    );
  }

  void selectBarber(String? barberId) {
    safeEmit(state.copyWith(
      selectedBarberId: barberId,
      clearSelectedBarberId: barberId == null,
    ));
  }

  Future<void> addManualBooking({
    required String barberId,
    required String serviceId,
    required String customerName,
    required String customerPhone,
    required int startMinute,
    required int durationMinutes,
  }) async {
    safeEmit(state.copyWith(actionInProgress: true));

    final result = await runCancelable(_createBooking.call(
      CreateBookingParams(
        shopId: shopId,
        barberId: barberId,
        serviceId: serviceId,
        customerName: customerName,
        customerPhone: customerPhone,
        date: state.date,
        startMinute: startMinute,
        durationMinutes: durationMinutes,
        source: BookingSource.manual,
      ),
    ));
    if (result == null) return;

    result.fold(
      (failure) => safeEmit(state.copyWith(
          actionInProgress: false, errorMessage: failure.message)),
      (_) {
        safeEmit(state.copyWith(actionInProgress: false));
        loadDate(state.date);
      },
    );
  }

  Future<void> cancelBooking(String bookingId) async {
    safeEmit(state.copyWith(actionInProgress: true));

    final result = await runCancelable(_cancelBooking.call(
      CancelBookingParams(
        shopId: shopId,
        bookingId: bookingId,
        cancelledByShop: true,
      ),
    ));
    if (result == null) return;

    result.fold(
      (failure) => safeEmit(state.copyWith(
          actionInProgress: false, errorMessage: failure.message)),
      (_) {
        safeEmit(state.copyWith(actionInProgress: false));
        loadDate(state.date);
      },
    );
  }

  Future<void> setOutcome(String bookingId, BookingStatus outcome) async {
    safeEmit(state.copyWith(actionInProgress: true));

    final result = await runCancelable(_setBookingOutcome.call(
      SetBookingOutcomeParams(
        shopId: shopId,
        bookingId: bookingId,
        outcome: outcome,
      ),
    ));
    if (result == null) return;

    result.fold(
      (failure) => safeEmit(state.copyWith(
          actionInProgress: false, errorMessage: failure.message)),
      (_) {
        safeEmit(state.copyWith(actionInProgress: false));
        loadDate(state.date);
      },
    );
  }
}
