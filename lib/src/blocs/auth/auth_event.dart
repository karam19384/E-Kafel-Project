part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class AppStarted extends AuthEvent {}

class LoginButtonPressed extends AuthEvent {
  final String password;
  final String loginIdentifier;

  const LoginButtonPressed({
    required this.password,
    required this.loginIdentifier,
  });

  @override
  List<Object> get props => [loginIdentifier, password];
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
  final String institutionId;
  final String areaResponsibleFor;
  final String functionalLodgment;

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
    required this.institutionId,
    required this.areaResponsibleFor,
    required this.functionalLodgment,
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
    institutionId,
    areaResponsibleFor,
    functionalLodgment,
  ];
}

// ✅ حدث جديد للتسجيل عبر Google
class GoogleSignInButtonPressed extends AuthEvent {}

// ✅ حدث جديد للتسجيل عبر Facebook
class FacebookSignInButtonPressed extends AuthEvent {}

// ✅ حدث جديد لإعادة تعيين كلمة المرور
class ResetPasswordRequested extends AuthEvent {
  final String email;

  const ResetPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class SignOutButtonPressed extends AuthEvent {}
