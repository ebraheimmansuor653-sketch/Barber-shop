import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../manager/authentication/authentication_cubit.dart';
import '../manager/authentication/authentication_state.dart';
import '../widgets/authentication_widgets.dart';

class AuthenticationPage extends StatelessWidget {
  const AuthenticationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthenticationCubit>()..loadData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Authentication'),
        ),
        body: BlocBuilder<AuthenticationCubit, AuthenticationState>(
          builder: (context, state) {
            if (state is AuthenticationLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AuthenticationError) {
              return Center(child: Text(state.message));
            }
            if (state is AuthenticationLoaded) {
              return AuthenticationList(items: state.items);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
