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

class GoogleLinkSuccess extends AuthState {
  final User user;
  const GoogleLinkSuccess(this.user);

  @override
  List<Object> get props => [user];
}

class GoogleLinkFailure extends AuthState {
  final String error;
  const GoogleLinkFailure(this.error);

  @override
  List<Object> get props => [error];
}

class GoogleUnlinkSuccess extends AuthState {
  const GoogleUnlinkSuccess();
}

class GoogleLinkChecked extends AuthState {
  final bool isLinked;
  const GoogleLinkChecked(this.isLinked);

  @override
  List<Object> get props => [isLinked];
}
// في auth_state.dart - أضف هذه الحالات
class EmailVerificationSent extends AuthState {
  final String email;
  const EmailVerificationSent(this.email);
  
  @override
  List<Object> get props => [email];
}

class EmailVerified extends AuthState {
  final String email;
  const EmailVerified(this.email);
  
  @override
  List<Object> get props => [email];
}

class EmailUnlinked extends AuthState {
  const EmailUnlinked();
  
  @override
  List<Object> get props => [];
}

class EmailLinkStatusChecked extends AuthState {
  final bool isLinked;
  final String? email;
  final bool isVerified;
  
  const EmailLinkStatusChecked({
    required this.isLinked,
    this.email,
    this.isVerified = false,
  });
  
  @override
  List<Object> get props => [isLinked, isVerified];
}