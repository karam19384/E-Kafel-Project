import 'package:cloud_firestore/cloud_firestore.dart';

class Profile {
  final String uid; // معرّف المستخدم (ثابت)
  final String customId; // رقم وظيفي/مخصص (ثابت)
  final String institutionId; // معرف المؤسسة (ثابت)
  final String institutionName; // اسم المؤسسة (ثابت)

  // أساسية
  final String fullName;
  final String email;
  final String mobileNumber;
  final String? address;
  final String userRole; // supervisor | kafalaHead | admin ...
  final String? profileImageUrl;

  // وظيفية

  final String? functionalLodgment; // Dropdown
  final String? areaResponsibleFor; // Dropdown

  // بيانات إضافية
  final String? currentLocation; // عنوان حالي نصي
  final String? notes;

  // أزمنة
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.uid,
    required this.customId,
    required this.institutionId,
    required this.institutionName,

    required this.fullName,
    required this.email,
    required this.mobileNumber,
    this.address,
    required this.userRole,
    this.profileImageUrl,

    this.functionalLodgment,
    this.areaResponsibleFor,

    this.currentLocation,
    this.notes,

    required this.createdAt,
    required this.updatedAt,
  });

  bool get canEditAll => userRole == 'kafala_head' || userRole == 'admin';

  Profile copyWith({
    String? fullName,
    String? email,
    String? mobileNumber,
    String? address,
    String? profileImageUrl,

    String? functionalLodgment,
    String? areaResponsibleFor,
    String? currentLocation,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Profile(
      uid: uid,
      customId: customId,
      institutionId: institutionId,
      institutionName: institutionName,

      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      address: address ?? this.address,
      userRole: userRole,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,

      functionalLodgment: functionalLodgment ?? this.functionalLodgment,
      areaResponsibleFor: areaResponsibleFor ?? this.areaResponsibleFor,

      currentLocation: currentLocation ?? this.currentLocation,
      notes: notes ?? this.notes,

      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'customId': customId,
      'institutionId': institutionId,
      'institutionName': institutionName,

      'fullName': fullName,
      'email': email,
      'mobileNumber': mobileNumber,
      'address': address,
      'userRole': userRole,
      'profileImageUrl': profileImageUrl,

      'functionalLodgment': functionalLodgment,
      'areaResponsibleFor': areaResponsibleFor,

      'currentLocation': currentLocation,
      'notes': notes,

      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    final created = map['createdAt'];
    final updated = map['updatedAt'];
    return Profile(
      uid: map['uid'] as String,
      customId: map['customId'] as String,
      institutionId: map['institutionId'] as String,
      institutionName: map['institutionName'] as String,

      fullName: (map['fullName'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      mobileNumber: (map['mobileNumber'] ?? '') as String,
      address: map['address'] as String?,
      userRole: (map['userRole'] ?? 'supervisor') as String,
      profileImageUrl: map['profileImageUrl'] as String?,

      functionalLodgment: map['functionalLodgment'] as String?,
      areaResponsibleFor: map['areaResponsibleFor'] as String?,

      currentLocation: map['currentLocation'] as String?,
      notes: map['notes'] as String?,

      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      updatedAt: updated is Timestamp ? updated.toDate() : DateTime.now(),
    );
  }
}
