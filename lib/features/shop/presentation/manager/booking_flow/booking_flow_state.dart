import 'package:equatable/equatable.dart';

import '../../../domain/entities/barber_entity.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/service_entity.dart';
import '../../../domain/entities/shop_entity.dart';

enum BookingFlowStep { loading, ready, bookingInProgress, booked, error }

class BookingFlowState extends Equatable {
  final BookingFlowStep step;
  final ShopEntity? shop;
  final List<BarberEntity> barbers;
  final List<ServiceEntity> services;

  final String? selectedServiceId;

  /// Null means "no preference" — the engine picks the barber once a
  /// time is chosen.
  final String? selectedBarberId;

  final DateTime? selectedDate;
  final bool slotsLoading;
  final List<int> availableStartMinutes;
  final int? selectedStartMinute;

  final BookingEntity? confirmedBooking;
  final String? errorMessage;

  const BookingFlowState({
    this.step = BookingFlowStep.loading,
    this.shop,
    this.barbers = const [],
    this.services = const [],
    this.selectedServiceId,
    this.selectedBarberId,
    this.selectedDate,
    this.slotsLoading = false,
    this.availableStartMinutes = const [],
    this.selectedStartMinute,
    this.confirmedBooking,
    this.errorMessage,
  });

  ServiceEntity? get selectedService => selectedServiceId == null
      ? null
      : services.where((s) => s.id == selectedServiceId).firstOrNull;

  BookingFlowState copyWith({
    BookingFlowStep? step,
    ShopEntity? shop,
    List<BarberEntity>? barbers,
    List<ServiceEntity>? services,
    String? selectedServiceId,
    bool clearSelectedBarberId = false,
    String? selectedBarberId,
    DateTime? selectedDate,
    bool? slotsLoading,
    List<int>? availableStartMinutes,
    bool clearSelectedStartMinute = false,
    int? selectedStartMinute,
    BookingEntity? confirmedBooking,
    String? errorMessage,
  }) {
    return BookingFlowState(
      step: step ?? this.step,
      shop: shop ?? this.shop,
      barbers: barbers ?? this.barbers,
      services: services ?? this.services,
      selectedServiceId: selectedServiceId ?? this.selectedServiceId,
      selectedBarberId: clearSelectedBarberId
          ? null
          : (selectedBarberId ?? this.selectedBarberId),
      selectedDate: selectedDate ?? this.selectedDate,
      slotsLoading: slotsLoading ?? this.slotsLoading,
      availableStartMinutes:
          availableStartMinutes ?? this.availableStartMinutes,
      selectedStartMinute: clearSelectedStartMinute
          ? null
          : (selectedStartMinute ?? this.selectedStartMinute),
      confirmedBooking: confirmedBooking ?? this.confirmedBooking,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        step,
        shop,
        barbers,
        services,
        selectedServiceId,
        selectedBarberId,
        selectedDate,
        slotsLoading,
        availableStartMinutes,
        selectedStartMinute,
        confirmedBooking,
        errorMessage,
      ];
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
