// lib/src/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String institutionId;
  final String institutionName; // ثابت لا يعدله المستخدم
  final String customId; // ثابت لا يعدله المستخدم
  final String fullName;
  final String email;
  final String mobileNumber;
  final String userRole; // supervisor | kafalaHead | admin ...
  final String? functionalLodgment; // Dropdown
  final String? areaResponsibleFor; // Dropdown
  final String? address;
  final String? profileImageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? kafalaHeadId;

  UserModel({
    required this.uid,
    required this.institutionId,
    required this.institutionName,
    required this.customId,
    required this.fullName,
    required this.email,
    required this.mobileNumber,
    required this.userRole,
    this.functionalLodgment,
    this.areaResponsibleFor,
    this.address,
    this.profileImageUrl,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    required this.kafalaHeadId,
  });

// في user_model.dart - تحديث دالة fromMap
factory UserModel.fromMap(Map<String, dynamic> map) {
  // تحقق من الحقول الأساسية
  final String uid = _parseString(map['uid']);
  final String institutionId = _parseString(map['institutionId']);
  final String institutionName = _parseString(map['institutionName']);
  
  if (uid.isEmpty) {
    throw ArgumentError('UID cannot be empty');
  }
  
  if (institutionId.isEmpty) {
    throw ArgumentError('Institution ID cannot be empty');
  }

  return UserModel(
    uid: uid,
    institutionId: institutionId,
    institutionName: institutionName,
    customId: _parseString(map['customId']),
    fullName: _parseString(map['fullName']),
    email: _parseString(map['email']),
    mobileNumber: _parseString(map['mobileNumber']),
    userRole: _parseString(map['userRole'], defaultValue: 'supervisor'),
    functionalLodgment: _parseOptionalString(map['functionalLodgment']),
    areaResponsibleFor: _parseOptionalString(map['areaResponsibleFor']),
    address: _parseOptionalString(map['address']),
    profileImageUrl: _parseOptionalString(map['profileImageUrl']),
    isActive: map['isActive'] as bool? ?? true,
    createdAt: _parseDateTime(map['createdAt']),
    updatedAt: _parseOptionalDateTime(map['updatedAt']),
    kafalaHeadId: _parseOptionalString(map['kafalaHeadId']),
  );
}
// دوال مساعدة للتحقق من الأنواع
static String _parseString(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  if (value is String) return value;
  return value.toString();
}

static String? _parseOptionalString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  final str = value.toString();
  return str.isEmpty ? null : str;
}

static DateTime _parseDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

static DateTime? _parseOptionalDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'institutionId': institutionId,
      'institutionName': institutionName,
      'customId': customId,
      'fullName': fullName,
      'email': email,
      'mobileNumber': mobileNumber,
      'userRole': userRole,
      'functionalLodgment': functionalLodgment,
      'areaResponsibleFor': areaResponsibleFor,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'kafalaHeadId': kafalaHeadId,
    };
  }

  UserModel copyWith({
    String? uid,
    String? institutionId,
    String? institutionName,
    String? customId,
    String? fullName,
    String? email,
    String? mobileNumber,
    String? userRole,
    String? functionalLodgment,
    String? areaResponsibleFor,
    String? address,
    String? profileImageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? kafalaHeadId,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      institutionId: institutionId ?? this.institutionId,
      institutionName: institutionName ?? this.institutionName,
      customId: customId ?? this.customId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      userRole: userRole ?? this.userRole,
      functionalLodgment: functionalLodgment ?? this.functionalLodgment,
      areaResponsibleFor: areaResponsibleFor ?? this.areaResponsibleFor,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      kafalaHeadId: kafalaHeadId ?? this.kafalaHeadId,
    );
  }
}
