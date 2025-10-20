part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  final String uid;
  const LoadProfile(this.uid);
  @override
  List<Object?> get props => [uid];
}

class UpdateProfileRequested extends ProfileEvent {
  final Map<String, dynamic> fields; // الحقول المسموح تعديلها حسب الدور
  const UpdateProfileRequested(this.fields);
  @override
  List<Object?> get props => [fields];
}

// اختياري: لتغيير كلمة المرور عبر FirebaseAuth
class UpdatePasswordRequested extends ProfileEvent {
  final String newPassword;
  const UpdatePasswordRequested(this.newPassword);
  @override
  List<Object?> get props => [newPassword];
}

// اختياري: لتغيير الإيميل على FirebaseAuth + تخزينه بـ Firestore
class UpdateEmailRequested extends ProfileEvent {
  final String newEmail;
  const UpdateEmailRequested(this.newEmail);
  @override
  List<Object?> get props => [newEmail];
}
