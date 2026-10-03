import '../entities/barber_entity.dart';
import '../entities/booking_entity.dart';
import '../entities/shift_entity.dart';
import '../entities/shop_entity.dart';

/// The scheduling grid: every slot starts on a 15-minute boundary
/// (07:00, 07:15, 07:30, ...), regardless of how long the service itself
/// takes. Service duration decides how many grid steps a booking occupies,
/// not the grid size itself.
const int kSlotGridMinutes = 15;

class SchedulingEngine {
  const SchedulingEngine();

  /// Available start times (in minutes-since-midnight) for [barber] to
  /// perform a service of [serviceDurationMinutes] on [date], given the
  /// shop's chair capacity and everyone's existing bookings that day.
  ///
  /// This is the single source of truth for "is this slot free?" — it's
  /// used both to show the customer available times and, inside the
  /// booking transaction, to re-validate the chosen slot before writing it.
  List<int> availableStartMinutes({
    required ShopEntity shop,
    required BarberEntity barber,
    required DateTime date,
    required int serviceDurationMinutes,
    required List<BookingEntity> shopBookingsOnDate,
  }) {
    final shifts = _effectiveShifts(shop: shop, barber: barber, date: date);
    if (shifts.isEmpty) return const [];

    final confirmedShopBookings = shopBookingsOnDate
        .where((b) => b.status == BookingStatus.confirmed)
        .toList();
    final barberBookings =
        confirmedShopBookings.where((b) => b.barberId == barber.id).toList();

    final result = <int>[];
    for (final shift in shifts) {
      for (var start = shift.startMinute;
          start + serviceDurationMinutes <= shift.endMinute;
          start += kSlotGridMinutes) {
        final candidateEnd = start + serviceDurationMinutes;

        // The buffer is a trailing gap *after* an existing booking, so it
        // extends that booking's occupied window — not the candidate's own
        // duration. This keeps the check symmetric for both the barber
        // and the chair-capacity count below.
        final barberFree = barberBookings.every((b) =>
            !_occupiesWindow(b, shop.bufferMinutes, start, candidateEnd));
        if (!barberFree) continue;

        final concurrent = confirmedShopBookings
            .where((b) =>
                _occupiesWindow(b, shop.bufferMinutes, start, candidateEnd))
            .length;
        if (concurrent >= shop.chairsCount) continue;

        result.add(start);
      }
    }
    return result;
  }

  /// For "no barber chosen": picks the earliest minute at which *any*
  /// qualifying barber (one who performs [serviceId]) is free, and on a
  /// tie picks whichever of those barbers has fewer bookings that day.
  BarberEntity? pickBarberForEarliestSlot({
    required ShopEntity shop,
    required List<BarberEntity> barbers,
    required String serviceId,
    required DateTime date,
    required int serviceDurationMinutes,
    required List<BookingEntity> shopBookingsOnDate,
    required int desiredStartMinute,
  }) {
    final candidates = barbers.where((b) => b.performsService(serviceId));

    BarberEntity? best;
    var bestBookingCount = 1 << 30;

    for (final barber in candidates) {
      final slots = availableStartMinutes(
        shop: shop,
        barber: barber,
        date: date,
        serviceDurationMinutes: serviceDurationMinutes,
        shopBookingsOnDate: shopBookingsOnDate,
      );
      if (!slots.contains(desiredStartMinute)) continue;

      final bookingCount = shopBookingsOnDate
          .where((b) =>
              b.barberId == barber.id && b.status == BookingStatus.confirmed)
          .length;

      if (bookingCount < bestBookingCount) {
        best = barber;
        bestBookingCount = bookingCount;
      }
    }
    return best;
  }

  List<ShiftEntity> _effectiveShifts({
    required ShopEntity shop,
    required BarberEntity barber,
    required DateTime date,
  }) {
    final weekday = date.weekday;
    final hours = barber.workingHoursOverride ?? shop.workingHours;
    return hours[weekday] ?? const [];
  }

  /// Whether an existing [booking] — extended by [bufferMinutes] of
  /// trailing gap after it ends — overlaps the candidate window
  /// [candidateStart, candidateEnd).
  bool _occupiesWindow(
    BookingEntity booking,
    int bufferMinutes,
    int candidateStart,
    int candidateEnd,
  ) {
    final occupiedEnd = booking.endMinute + bufferMinutes;
    return booking.startMinute < candidateEnd && candidateStart < occupiedEnd;
  }
}
