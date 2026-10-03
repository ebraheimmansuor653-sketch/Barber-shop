import 'package:equatable/equatable.dart';

import 'shift_entity.dart';

enum SubscriptionStatus { trial, active, expired }

class ShopEntity extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String? logoUrl;
  final List<String> photoUrls;
  final String area;
  final double? latitude;
  final double? longitude;

  final int chairsCount;
  final int bufferMinutes;

  /// Default cancellation window is 2 hours when the shop hasn't set one.
  final int cancellationWindowMinutes;

  final WeeklyWorkingHours workingHours;

  /// A new shop is hidden from customers until the platform approves it.
  final bool approved;

  final SubscriptionStatus subscriptionStatus;
  final DateTime subscriptionExpiresAt;

  const ShopEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.area,
    required this.chairsCount,
    required this.workingHours,
    required this.subscriptionStatus,
    required this.subscriptionExpiresAt,
    this.logoUrl,
    this.photoUrls = const [],
    this.latitude,
    this.longitude,
    this.bufferMinutes = 0,
    this.cancellationWindowMinutes = 120,
    this.approved = false,
  });

  /// A shop only accepts new bookings while it is visible to customers
  /// (approved) and its subscription hasn't lapsed. Historical data stays
  /// visible to the owner regardless — this flag only gates *new* activity.
  bool get acceptsNewBookings =>
      approved && subscriptionStatus != SubscriptionStatus.expired;

  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        logoUrl,
        photoUrls,
        area,
        latitude,
        longitude,
        chairsCount,
        bufferMinutes,
        cancellationWindowMinutes,
        workingHours,
        approved,
        subscriptionStatus,
        subscriptionExpiresAt,
      ];
}
