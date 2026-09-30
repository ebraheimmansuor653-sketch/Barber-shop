import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_consumer.dart';
import '../models/authentication_model.dart';

abstract class AuthenticationRemoteDataSource {
  Future<List<AuthenticationModel>> fetchAuthentications();
}

class AuthenticationRemoteDataSourceImpl
    implements AuthenticationRemoteDataSource {
  final ApiConsumer _dio;

  AuthenticationRemoteDataSourceImpl(this._dio);

  @override
  Future<List<AuthenticationModel>> fetchAuthentications() async {
    // TODO: replace ApiEndpoints.products with the correct endpoint
    final response = await _dio.get(ApiEndpoints.products);
    return (response as List)
        .map((e) => AuthenticationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
