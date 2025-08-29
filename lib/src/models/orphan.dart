import 'package:cloud_firestore/cloud_firestore.dart';

class Orphan {
  final String? id;
  final String name;
  final String deceasedName;
  final String? causeOfDeath;
  final DateTime? dateOfDeath;
  final String? deceasedIdNumber;
  final String? gender;
  final String? orphanIdNumber;
  final DateTime? dateOfBirth;
  final String? motherIdNumber;
  final String? motherName;
  final String? breadwinnerIdNumber;
  final String? breadwinnerName;
  final String? breadwinnerMaritalStatus;
  final String? breadwinnerKinship;
  final String? governorate;
  final String? city;
  final String? neighborhood;
  final int numberOfMales;
  final int numberOfFemales;
  final int totalFamilyMembers;
  final String? mobileNumber;
  final String? phoneNumber;
  final String orphanNo;
  final String? schoolName;
  final String? grade;
  final String? educationLevel;
  final String? idCardUrl;
  final String? deathCertificateUrl;
  final String? orphanPhotoUrl; // إضافة حقل صورة اليتيم
  final DateTime createdAt;
  final DateTime updatedAt;

  Orphan({
    this.id,
    required this.name,
    required this.deceasedName,
    this.causeOfDeath,
    this.dateOfDeath,
    this.deceasedIdNumber,
    this.gender,
    this.orphanIdNumber,
    this.dateOfBirth,
    this.motherIdNumber,
    this.motherName,
    this.breadwinnerIdNumber,
    this.breadwinnerName,
    this.breadwinnerMaritalStatus,
    this.breadwinnerKinship,
    this.governorate,
    this.city,
    this.neighborhood,
    required this.numberOfMales,
    required this.numberOfFemales,
    required this.totalFamilyMembers,
    this.mobileNumber,
    this.phoneNumber,
    required this.orphanNo,
    this.schoolName,
    this.grade,
    this.educationLevel,
    this.idCardUrl,
    this.deathCertificateUrl,
    this.orphanPhotoUrl, // إضافة حقل صورة اليتيم
    required this.createdAt,
    required this.updatedAt,
  });

  // تحويل الكائن إلى Map لإرساله إلى Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'deceasedName': deceasedName,
      'causeOfDeath': causeOfDeath,
      'dateOfDeath': dateOfDeath != null ? Timestamp.fromDate(dateOfDeath!) : null,
      'deceasedIdNumber': deceasedIdNumber,
      'gender': gender,
      'orphanIdNumber': orphanIdNumber,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'motherIdNumber': motherIdNumber,
      'motherName': motherName,
      'breadwinnerIdNumber': breadwinnerIdNumber,
      'breadwinnerName': breadwinnerName,
      'breadwinnerMaritalStatus': breadwinnerMaritalStatus,
      'breadwinnerKinship': breadwinnerKinship,
      'governorate': governorate,
      'city': city,
      'neighborhood': neighborhood,
      'numberOfMales': numberOfMales,
      'numberOfFemales': numberOfFemales,
      'totalFamilyMembers': totalFamilyMembers,
      'mobileNumber': mobileNumber,
      'phoneNumber': phoneNumber,
      'orphanNo': orphanNo,
      'schoolName': schoolName,
      'grade': grade,
      'educationLevel': educationLevel,
      'idCardUrl': idCardUrl,
      'deathCertificateUrl': deathCertificateUrl,
      'orphanPhotoUrl': orphanPhotoUrl, // إضافة حقل صورة اليتيم
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // إنشاء كائن Orphan من Map قادم من Firestore
  factory Orphan.fromMap(Map<String, dynamic> map, String id) {
    return Orphan(
      id: id,
      name: map['name'] ?? '',
      deceasedName: map['deceasedName'] ?? '',
      causeOfDeath: map['causeOfDeath'],
      dateOfDeath: (map['dateOfDeath'] as Timestamp?)?.toDate(),
      deceasedIdNumber: map['deceasedIdNumber'],
      gender: map['gender'],
      orphanIdNumber: map['orphanIdNumber'],
      dateOfBirth: (map['dateOfBirth'] as Timestamp?)?.toDate(),
      motherIdNumber: map['motherIdNumber'],
      motherName: map['motherName'],
      breadwinnerIdNumber: map['breadwinnerIdNumber'],
      breadwinnerName: map['breadwinnerName'],
      breadwinnerMaritalStatus: map['breadwinnerMaritalStatus'],
      breadwinnerKinship: map['breadwinnerKinship'],
      governorate: map['governorate'],
      city: map['city'],
      neighborhood: map['neighborhood'],
      numberOfMales: map['numberOfMales'] ?? 0,
      numberOfFemales: map['numberOfFemales'] ?? 0,
      totalFamilyMembers: map['totalFamilyMembers'] ?? 0,
      mobileNumber: map['mobileNumber'],
      phoneNumber: map['phoneNumber'],
      orphanNo: map['orphanNo'] ?? '',
      schoolName: map['schoolName'],
      grade: map['grade'],
      educationLevel: map['educationLevel'],
      idCardUrl: map['idCardUrl'],
      deathCertificateUrl: map['deathCertificateUrl'],
      orphanPhotoUrl: map['orphanPhotoUrl'], // إضافة حقل صورة اليتيم
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // نسخ الكائن مع إمكانية تحديث بعض الخصائص
  Orphan copyWith({
    String? id,
    String? name,
    String? deceasedName,
    String? causeOfDeath,
    DateTime? dateOfDeath,
    String? deceasedIdNumber,
    String? gender,
    String? orphanIdNumber,
    DateTime? dateOfBirth,
    String? motherIdNumber,
    String? motherName,
    String? breadwinnerIdNumber,
    String? breadwinnerName,
    String? breadwinnerMaritalStatus,
    String? breadwinnerKinship,
    String? governorate,
    String? city,
    String? neighborhood,
    int? numberOfMales,
    int? numberOfFemales,
    int? totalFamilyMembers,
    String? mobileNumber,
    String? phoneNumber,
    String? orphanNo,
    String? schoolName,
    String? grade,
    String? educationLevel,
    String? idCardUrl,
    String? deathCertificateUrl,
    String? orphanPhotoUrl, // إضافة حقل صورة اليتيم
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Orphan(
      id: id ?? this.id,
      name: name ?? this.name,
      deceasedName: deceasedName ?? this.deceasedName,
      causeOfDeath: causeOfDeath ?? this.causeOfDeath,
      dateOfDeath: dateOfDeath ?? this.dateOfDeath,
      deceasedIdNumber: deceasedIdNumber ?? this.deceasedIdNumber,
      gender: gender ?? this.gender,
      orphanIdNumber: orphanIdNumber ?? this.orphanIdNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      motherIdNumber: motherIdNumber ?? this.motherIdNumber,
      motherName: motherName ?? this.motherName,
      breadwinnerIdNumber: breadwinnerIdNumber ?? this.breadwinnerIdNumber,
      breadwinnerName: breadwinnerName ?? this.breadwinnerName,
      breadwinnerMaritalStatus: breadwinnerMaritalStatus ?? this.breadwinnerMaritalStatus,
      breadwinnerKinship: breadwinnerKinship ?? this.breadwinnerKinship,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      numberOfMales: numberOfMales ?? this.numberOfMales,
      numberOfFemales: numberOfFemales ?? this.numberOfFemales,
      totalFamilyMembers: totalFamilyMembers ?? this.totalFamilyMembers,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      orphanNo: orphanNo ?? this.orphanNo,
      schoolName: schoolName ?? this.schoolName,
      grade: grade ?? this.grade,
      educationLevel: educationLevel ?? this.educationLevel,
      idCardUrl: idCardUrl ?? this.idCardUrl,
      deathCertificateUrl: deathCertificateUrl ?? this.deathCertificateUrl,
      orphanPhotoUrl: orphanPhotoUrl ?? this.orphanPhotoUrl, // إضافة حقل صورة اليتيم
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
