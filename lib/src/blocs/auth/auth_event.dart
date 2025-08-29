// lib/src/blocs/auth/auth_event.dart

part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}
class AppStarted extends AuthEvent {} // أضف هذا السطر


class LoginButtonPressed extends AuthEvent {
  final String email;
  final String password;

  const LoginButtonPressed({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class LogoutButtonPressed extends AuthEvent {}
// lib/src/blocs/auth/auth_event.dart

class SignUpButtonPressed extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String userRole;
  final String? institutionId;
  // إضافة المتغيرات الجديدة هنا
  final String address;
  final String website;
  final String headName;
  final String headEmail;
  final String headMobileNumber;

  const SignUpButtonPressed({
    required this.name,
    required this.email,
    required this.password,
    required this.userRole,
    this.institutionId,
    // يجب أن تكون المتغيرات الجديدة مطلوبة أيضاً
    required this.address,
    required this.website,
    required this.headName,
    required this.headEmail,
    required this.headMobileNumber,
  });

  @override
  List<Object?> get props => [
    name, email, password, userRole, institutionId,
    address, website, headName, headEmail, headMobileNumber,
  ];

}class SignInWithGoogleButtonPressed extends AuthEvent {}