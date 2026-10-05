import '../../domain/entities/shift_entity.dart';
import '../../domain/entities/shop_entity.dart';

class ShopModel extends ShopEntity {
  const ShopModel({
    required super.id,
    required super.ownerId,
    required super.name,
    required super.area,
    required super.chairsCount,
    required super.workingHours,
    required super.subscriptionStatus,
    required super.subscriptionExpiresAt,
    super.logoUrl,
    super.photoUrls,
    super.latitude,
    super.longitude,
    super.bufferMinutes,
    super.cancellationWindowMinutes,
    super.approved,
  });

  factory ShopModel.fromMap(String id, Map<String, dynamic> map) {
    return ShopModel(
      id: id,
      ownerId: map['ownerId'] as String,
      name: map['name'] as String,
      area: map['area'] as String,
      chairsCount: map['chairsCount'] as int,
      bufferMinutes: (map['bufferMinutes'] as int?) ?? 0,
      cancellationWindowMinutes:
          (map['cancellationWindowMinutes'] as int?) ?? 120,
      logoUrl: map['logoUrl'] as String?,
      photoUrls: List<String>.from(map['photoUrls'] as List? ?? const []),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      approved: map['approved'] as bool? ?? false,
      workingHours: decodeWorkingHours(
        map['workingHours'] as Map<String, dynamic>? ?? const {},
      ),
      subscriptionStatus: SubscriptionStatus.values.firstWhere(
        (s) => s.name == map['subscriptionStatus'],
        orElse: () => SubscriptionStatus.trial,
      ),
      subscriptionExpiresAt:
          DateTime.parse(map['subscriptionExpiresAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'area': area,
      'chairsCount': chairsCount,
      'bufferMinutes': bufferMinutes,
      'cancellationWindowMinutes': cancellationWindowMinutes,
      'logoUrl': logoUrl,
      'photoUrls': photoUrls,
      'latitude': latitude,
      'longitude': longitude,
      'approved': approved,
      'workingHours': encodeWorkingHours(workingHours),
      'subscriptionStatus': subscriptionStatus.name,
      'subscriptionExpiresAt': subscriptionExpiresAt.toIso8601String(),
    };
  }
}

/// Shared by [ShopModel] and [BarberModel] (a barber's optional override
/// uses the exact same shape). Weekday keys are stored as strings ('1'
/// through '7', matching [DateTime.weekday]) because Firestore map keys
/// are always strings.
Map<String, dynamic> encodeWorkingHours(WeeklyWorkingHours hours) {
  return hours.map((weekday, shifts) => MapEntry(
        weekday.toString(),
        shifts
            .map((s) => {'start': s.startMinute, 'end': s.endMinute})
            .toList(),
      ));
}

WeeklyWorkingHours decodeWorkingHours(Map<String, dynamic> map) {
  return map.map((weekday, shifts) => MapEntry(
        int.parse(weekday),
        (shifts as List)
            .map((s) => ShiftEntity(
                  startMinute: (s as Map)['start'] as int,
                  endMinute: s['end'] as int,
                ))
            .toList(),
      ));
}
