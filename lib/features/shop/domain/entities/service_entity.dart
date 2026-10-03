import 'package:equatable/equatable.dart';

class ServiceEntity extends Equatable {
  final String id;
  final String name;
  final int durationMinutes;
  final double price;

  const ServiceEntity({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
  });

  @override
  List<Object?> get props => [id, name, durationMinutes, price];
}
