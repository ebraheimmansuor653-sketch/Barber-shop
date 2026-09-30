import 'package:equatable/equatable.dart';

import '../../../domain/entities/authentication_entity.dart';

abstract class AuthenticationState extends Equatable {
  const AuthenticationState();

  @override
  List<Object?> get props => [];
}

class AuthenticationInitial extends AuthenticationState {}

class AuthenticationLoading extends AuthenticationState {}

class AuthenticationLoaded extends AuthenticationState {
  final List<AuthenticationEntity> items;

  const AuthenticationLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class AuthenticationError extends AuthenticationState {
  final String message;

  const AuthenticationError(this.message);

  @override
  List<Object?> get props => [message];
}
