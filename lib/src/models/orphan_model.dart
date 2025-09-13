import 'package:cloud_firestore/cloud_firestore.dart';

class Orphan {
  final String institutionId;
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
  final String? orphanPhotoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isArchived; 

  Orphan({
    required this.institutionId,
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
    this.numberOfMales = 0,
    this.numberOfFemales = 0,
    this.totalFamilyMembers = 0,
    this.mobileNumber,
    this.phoneNumber,
    required this.orphanNo,
    this.schoolName,
    this.grade,
    this.educationLevel,
    this.idCardUrl,
    this.deathCertificateUrl,
    this.orphanPhotoUrl,
    this.createdAt,
    this.updatedAt,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'institutionId': institutionId,
      'name': name,
      'deceasedName': deceasedName,
      'causeOfDeath': causeOfDeath,
      'dateOfDeath': dateOfDeath,
      'deceasedIdNumber': deceasedIdNumber,
      'gender': gender,
      'orphanIdNumber': orphanIdNumber,
      'dateOfBirth': dateOfBirth,
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
      'orphanPhotoUrl': orphanPhotoUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isArchived': isArchived,
    };
  }

  static Orphan fromMap(Map<String, dynamic> map, {String? id}) {
    return Orphan(
      institutionId: map['institutionId'] as String,
      id: id,
      name: map['name'] as String,
      deceasedName: map['deceasedName'] as String,
      causeOfDeath: map['causeOfDeath'] as String?,
      dateOfDeath: (map['dateOfDeath'] as Timestamp?)?.toDate(),
      deceasedIdNumber: map['deceasedIdNumber'] as String?,
      gender: map['gender'] as String?,
      orphanIdNumber: map['orphanIdNumber'] as String?,
      dateOfBirth: (map['dateOfBirth'] as Timestamp?)?.toDate(),
      motherIdNumber: map['motherIdNumber'] as String?,
      motherName: map['motherName'] as String?,
      breadwinnerIdNumber: map['breadwinnerIdNumber'] as String?,
      breadwinnerName: map['breadwinnerName'] as String?,
      breadwinnerMaritalStatus: map['breadwinnerMaritalStatus'] as String?,
      breadwinnerKinship: map['breadwinnerKinship'] as String?,
      governorate: map['governorate'] as String?,
      city: map['city'] as String?,
      neighborhood: map['neighborhood'] as String?,
      numberOfMales: map['numberOfMales'] as int? ?? 0,
      numberOfFemales: map['numberOfFemales'] as int? ?? 0,
      totalFamilyMembers: map['totalFamilyMembers'] as int? ?? 0,
      mobileNumber: map['mobileNumber'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      orphanNo: map['orphanNo'] as String,
      schoolName: map['schoolName'] as String?,
      grade: map['grade'] as String?,
      educationLevel: map['educationLevel'] as String?,
      idCardUrl: map['idCardUrl'] as String?,
      deathCertificateUrl: map['deathCertificateUrl'] as String?,
      orphanPhotoUrl: map['orphanPhotoUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      isArchived: map['isArchived'] as bool? ?? false,
    );
  }

  Orphan copyWith({
    String? id,
    String? institutionId,
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
    String? orphanPhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
  }) {
    return Orphan(
      id: id ?? this.id,
      institutionId: institutionId ?? this.institutionId,
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
      orphanPhotoUrl: orphanPhotoUrl ?? this.orphanPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}