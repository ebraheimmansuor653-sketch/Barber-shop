import '../../core/di/injection_container.dart';
import '../../core/network/api_consumer.dart';
import 'data/datasources/authentication_remote_data_source.dart';
import 'data/repositories/authentication_repository_impl.dart';
import 'domain/repositories/authentication_repository.dart';
import 'domain/usecases/get_authentications_usecase.dart';
import 'presentation/manager/authentication/authentication_cubit.dart';

void initAuthentication() {
  // ── State Management ────────────────────────────────────────────────────────
  sl.registerFactory(
    () => AuthenticationCubit(sl<GetAuthenticationsUseCase>()),
  );

  // ── Use Cases ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton(
    () => GetAuthenticationsUseCase(sl<AuthenticationRepository>()),
  );

  // ── Repository ───────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthenticationRepository>(
    () => AuthenticationRepositoryImpl(
      sl<AuthenticationRemoteDataSource>(),
    ),
  );

  // ── Data Sources ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthenticationRemoteDataSource>(
    () => AuthenticationRemoteDataSourceImpl(sl<ApiConsumer>()),
  );
}
