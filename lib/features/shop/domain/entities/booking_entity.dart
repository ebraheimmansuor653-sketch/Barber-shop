import 'package:equatable/equatable.dart';

enum BookingStatus { confirmed, cancelled, completed, noShow }

enum BookingSource { customerApp, manual }

class BookingEntity extends Equatable {
  final String id;
  final String shopId;
  final String barberId;
  final String serviceId;

  final String customerName;
  final String customerPhone;

  /// Null for a manual (walk-in / phone) booking with no registered
  /// customer account.
  final String? customerUserId;

  final DateTime date;
  final int startMinute;
  final int durationMinutes;

  final BookingStatus status;
  final BookingSource source;
  final DateTime createdAt;

  const BookingEntity({
    required this.id,
    required this.shopId,
    required this.barberId,
    required this.serviceId,
    required this.customerName,
    required this.customerPhone,
    required this.date,
    required this.startMinute,
    required this.durationMinutes,
    required this.status,
    required this.source,
    required this.createdAt,
    this.customerUserId,
  });

  int get endMinute => startMinute + durationMinutes;

  bool overlaps(int otherStart, int otherEnd) =>
      startMinute < otherEnd && otherStart < endMinute;

  @override
  List<Object?> get props => [
        id,
        shopId,
        barberId,
        serviceId,
        customerName,
        customerPhone,
        customerUserId,
        date,
        startMinute,
        durationMinutes,
        status,
        source,
        createdAt,
      ];
}
