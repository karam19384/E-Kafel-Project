// lib/src/blocs/auth/auth_event.dart

part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class AppStarted extends AuthEvent {}

class LoginButtonPressed extends AuthEvent {
  final String email;
  final String password;
  final String loginIdentifier;

  const LoginButtonPressed({
    required this.email,
    required this.password,
    required this.loginIdentifier,
  });

  @override
  List<Object> get props => [email, password];
}

class LogoutButtonPressed extends AuthEvent {}

class SignUpButtonPressed extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String address;
  final String website;
  final String headName;
  final String headEmail;
  final String headMobileNumber;
  final String userRole;

  const SignUpButtonPressed({
    required this.name,
    required this.email,
    required this.password,
    required this.address,
    required this.website,
    required this.headName,
    required this.headEmail,
    required this.headMobileNumber,
    required this.userRole,
  });

  @override
  List<Object?> get props => [
    name,
    email,
    password,
    address,
    website,
    headName,
    headEmail,
    headMobileNumber,
    userRole,
  ];
}

class SignInWithGoogleButtonPressed extends AuthEvent {}
