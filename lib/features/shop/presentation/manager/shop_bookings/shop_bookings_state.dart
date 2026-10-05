import 'package:equatable/equatable.dart';

import '../../../domain/entities/booking_entity.dart';

enum ShopBookingsStep { loading, ready, error }

class ShopBookingsState extends Equatable {
  final ShopBookingsStep step;
  final DateTime date;
  final List<BookingEntity> bookings;

  /// Null means the "All" chip — every barber's bookings for the date.
  final String? selectedBarberId;

  final bool actionInProgress;
  final String? errorMessage;

  const ShopBookingsState({
    this.step = ShopBookingsStep.loading,
    required this.date,
    this.bookings = const [],
    this.selectedBarberId,
    this.actionInProgress = false,
    this.errorMessage,
  });

  List<BookingEntity> get visibleBookings {
    final filtered = selectedBarberId == null
        ? bookings
        : bookings.where((b) => b.barberId == selectedBarberId).toList();
    return filtered..sort((a, b) => a.startMinute.compareTo(b.startMinute));
  }

  ShopBookingsState copyWith({
    ShopBookingsStep? step,
    DateTime? date,
    List<BookingEntity>? bookings,
    bool clearSelectedBarberId = false,
    String? selectedBarberId,
    bool? actionInProgress,
    String? errorMessage,
  }) {
    return ShopBookingsState(
      step: step ?? this.step,
      date: date ?? this.date,
      bookings: bookings ?? this.bookings,
      selectedBarberId: clearSelectedBarberId
          ? null
          : (selectedBarberId ?? this.selectedBarberId),
      actionInProgress: actionInProgress ?? this.actionInProgress,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        step,
        date,
        bookings,
        selectedBarberId,
        actionInProgress,
        errorMessage,
      ];
}
