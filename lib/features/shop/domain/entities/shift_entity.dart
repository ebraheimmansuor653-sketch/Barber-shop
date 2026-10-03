import 'package:equatable/equatable.dart';

/// One continuous working period in a single day, expressed as minutes
/// since midnight (e.g. 10:00 -> 600, 17:00 -> 1020).
///
/// Using minutes-since-midnight instead of DateTime keeps the scheduling
/// math (grid snapping, overlap checks) simple integer arithmetic with no
/// timezone concerns — the date itself is tracked separately by whoever
/// uses this (a specific day's bookings), not inside the shift.
class ShiftEntity extends Equatable {
  final int startMinute;
  final int endMinute;

  const ShiftEntity({required this.startMinute, required this.endMinute});

  bool get isValid => endMinute > startMinute;

  bool contains(int minute) => minute >= startMinute && minute < endMinute;

  @override
  List<Object?> get props => [startMinute, endMinute];
}

/// A day's full set of shifts (a shop or barber can have more than one
/// shift per day, e.g. 10:00-17:00 and 17:00-00:00).
typedef DayShifts = List<ShiftEntity>;

/// Working hours for a full week. Keys are weekday numbers 1 (Monday) to
/// 7 (Sunday), matching [DateTime.weekday]. A missing key means closed
/// that day.
typedef WeeklyWorkingHours = Map<int, DayShifts>;
