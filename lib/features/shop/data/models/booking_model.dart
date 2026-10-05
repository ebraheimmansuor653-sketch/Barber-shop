import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/booking_entity.dart';

/// 'YYYY-MM-DD', used as a plain equality-queryable field — Firestore has
/// no clean way to query "same calendar day" from a Timestamp alone.
String dateKeyFor(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.shopId,
    required super.barberId,
    required super.serviceId,
    required super.customerName,
    required super.customerPhone,
    required super.date,
    required super.startMinute,
    required super.durationMinutes,
    required super.status,
    required super.source,
    required super.createdAt,
    super.customerUserId,
  });

  factory BookingModel.fromMap(String id, Map<String, dynamic> map) {
    return BookingModel(
      id: id,
      shopId: map['shopId'] as String,
      barberId: map['barberId'] as String,
      serviceId: map['serviceId'] as String,
      customerName: map['customerName'] as String,
      customerPhone: map['customerPhone'] as String,
      customerUserId: map['customerUserId'] as String?,
      date: DateTime.parse(map['dateKey'] as String),
      startMinute: map['startMinute'] as int,
      durationMinutes: map['durationMinutes'] as int,
      status: BookingStatus.values.firstWhere((s) => s.name == map['status']),
      source: BookingSource.values.firstWhere((s) => s.name == map['source']),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    final dayStart = DateTime(date.year, date.month, date.day);
    return {
      'shopId': shopId,
      'barberId': barberId,
      'serviceId': serviceId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerUserId': customerUserId,
      'dateKey': dateKeyFor(date),
      'startMinute': startMinute,
      'durationMinutes': durationMinutes,
      'status': status.name,
      'source': source.name,
      'createdAt': createdAt.toIso8601String(),
      // Write-only: the actual appointment instant, purely so the
      // Firestore security rules can check it's past the shop's
      // cancellation window without having to reconstruct it from
      // dateKey + startMinute inside the rules language.
      'startAt':
          Timestamp.fromDate(dayStart.add(Duration(minutes: startMinute))),
    };
  }
}
