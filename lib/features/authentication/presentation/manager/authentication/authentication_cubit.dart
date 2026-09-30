import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../shared/mixin/cancelable_safe_cubit_mixin.dart';
import '../../../domain/usecases/get_authentications_usecase.dart';
import 'authentication_state.dart';

class AuthenticationCubit extends Cubit<AuthenticationState>
    with CancelableSafeCubitMixin<AuthenticationState> {
  final GetAuthenticationsUseCase _getAuthenticationsUseCase;

  AuthenticationCubit(this._getAuthenticationsUseCase)
      : super(AuthenticationInitial());

  Future<void> loadData() async {
    safeEmit(AuthenticationLoading());

    final result = await runCancelable(
      _getAuthenticationsUseCase.call(),
    );

    if (result == null) return;

    result.fold(
      (failure) => safeEmit(AuthenticationError(failure.message)),
      (items) => safeEmit(AuthenticationLoaded(items)),
    );
  }
}
