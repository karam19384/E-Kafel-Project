part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String userRole;
  final String userName;
  final String? institutionId;
  final Map<String, dynamic> userData;

  const AuthAuthenticated({
    required this.userRole,
    required this.userName,
    this.institutionId,
    required this.userData,
  });

  @override
  List<Object?> get props => [userRole, userName, institutionId, userData];
}


class AuthUnauthenticated extends AuthState {
  final String? message;
  const AuthUnauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}
class AuthErrorState extends AuthState {
  final String message;

  const AuthErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

// ✅ حالة جديدة لإعادة تعيين كلمة المرور
class PasswordResetSent extends AuthState {
  final String email;

  const PasswordResetSent({required this.email});

  @override
  List<Object?> get props => [email];
}

// ✅ حالة جديدة للتسجيل الاجتماعي
class SocialSignInLoading extends AuthState {}
