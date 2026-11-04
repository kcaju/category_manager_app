import 'package:equatable/equatable.dart';
import '../../domain/models/user_profile.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthUsersLoaded extends AuthState {
  final List<UserProfile> users;
  final UserProfile? activeUser;

  const AuthUsersLoaded({required this.users, this.activeUser});

  @override
  List<Object?> get props => [users, activeUser];
}

class Authenticated extends AuthState {
  final UserProfile user;
  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  final List<UserProfile> availableUsers;
  const Unauthenticated({this.availableUsers = const []});

  @override
  List<Object?> get props => [availableUsers];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

