import '../../domain/entities/barber_entity.dart';
import 'shop_model.dart' show encodeWorkingHours, decodeWorkingHours;

class BarberModel extends BarberEntity {
  const BarberModel({
    required super.id,
    required super.shopId,
    required super.name,
    required super.phone,
    super.photoUrl,
    super.serviceIds,
    super.workingHoursOverride,
  });

  factory BarberModel.fromMap(
    String id,
    String shopId,
    Map<String, dynamic> map,
  ) {
    final rawOverride = map['workingHoursOverride'] as Map<String, dynamic>?;
    return BarberModel(
      id: id,
      shopId: shopId,
      name: map['name'] as String,
      phone: map['phone'] as String,
      photoUrl: map['photoUrl'] as String?,
      serviceIds: map['serviceIds'] == null
          ? null
          : Set<String>.from(map['serviceIds'] as List),
      workingHoursOverride:
          rawOverride == null ? null : decodeWorkingHours(rawOverride),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'serviceIds': serviceIds?.toList(),
      'workingHoursOverride': workingHoursOverride == null
          ? null
          : encodeWorkingHours(workingHoursOverride!),
    };
  }
}
