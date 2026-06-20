import 'auth_user.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthChecking extends AuthState {}

class AuthLoading extends AuthState {}

class OtpSentState extends AuthState {
  final String phoneNumber;

  OtpSentState(this.phoneNumber);
}

class AuthAuthenticated extends AuthState {
  final AuthUser user;

  AuthAuthenticated(this.user);
}

class AuthError extends AuthState {
  final String errorMessage;

  AuthError(this.errorMessage);
}
