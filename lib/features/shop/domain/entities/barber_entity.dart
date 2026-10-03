import 'package:equatable/equatable.dart';

import 'shift_entity.dart';

class BarberEntity extends Equatable {
  final String id;
  final String shopId;
  final String name;
  final String? photoUrl;
  final String phone;

  /// Null means the barber performs every service the shop offers.
  /// A non-null set restricts him to those service ids — the shop opts
  /// into this per barber, it's never required.
  final Set<String>? serviceIds;

  /// Null means this barber simply follows the shop's own working hours.
  /// Set only when the shop adjusts this specific barber's schedule.
  final WeeklyWorkingHours? workingHoursOverride;

  const BarberEntity({
    required this.id,
    required this.shopId,
    required this.name,
    required this.phone,
    this.photoUrl,
    this.serviceIds,
    this.workingHoursOverride,
  });

  bool performsService(String serviceId) =>
      serviceIds == null || serviceIds!.contains(serviceId);

  @override
  List<Object?> get props =>
      [id, shopId, name, photoUrl, phone, serviceIds, workingHoursOverride];
}
