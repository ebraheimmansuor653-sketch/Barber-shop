import '../../domain/entities/authentication_entity.dart';

class AuthenticationModel extends AuthenticationEntity {
  const AuthenticationModel();

  factory AuthenticationModel.fromJson(Map<String, dynamic> json) {
    return const AuthenticationModel();
  }

  Map<String, dynamic> toJson() {
    return {};
  }
}
