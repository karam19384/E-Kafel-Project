// lib/src/models/orphan_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Orphan {
  // الحقول الأساسية
  final String? id;
  final String institutionId;
  final String kafalaHeadId;
  final int? orphanNo; // الرقم الفريد لليتيم (5 أرقام)

  // === الإسم الخماسي ===
  final String orphanName; // اسم اليتيم
  final String fatherName; // اسم الأب
  final String grandfatherName; // اسم الجد
  final String greatGrandfatherName; // اسم جد الأب
  final String familyName; // اسم العائلة

  // المعلومات الشخصية
  final int orphanIdNumber; // رقم الهوية
  final DateTime dateOfBirth;
  final String gender; // ذكر، أنثى
  final String orphanType; // يتيم الأب، يتيم الأم، يتيم كلا الوالدين
  final String? healthStatus;
  final String? orphanPhotoUrl;

  // === بيانات الأب ===
  final String? fatherFullName; // رباعي
  final int? fatherIdNumber;
  final String? fatherIdPhotoUrl;
  final int? fatherAge;

  // === بيانات الأم ===
  final String? motherFullName; // رباعي
  final int? motherIdNumber;
  final String? motherIdPhotoUrl;
  final int? motherAge;

  // === بيانات المتوفي ===
  final String? deceasedFullName; // رباعي
  final int? deceasedIdNumber;
  final String? deceasedPhotoUrl;
  final String? causeOfDeath; // استشهاد، مرض، حادث، أخرى
  final DateTime? dateOfDeath;
  final String? deathCertificateUrl;

  // === بيانات المعيل ===
  final String? breadwinnerFullName; // رباعي
  final int? breadwinnerIdNumber;
  final String? breadwinnerIdPhotoUrl;
  final String? breadwinnerKinship; // العلاقة مع اليتيم
  final String? breadwinnerMaritalStatus; // الحالة الاجتماعية
  final int? breadwinnerAge;

  // === بيانات العائلة ===
  final int numberOfMales;
  final int numberOfFemales;
  final int totalFamilyMembers;
  final int? mobileNumber;
  final int? alternativeMobileNumber;
  final int? whatsappNumber;

  // === التعليم والصحة ===
  final String? schoolName;
  final String? grade; // الصف الدراسي
  final String? educationLevel; // المستوى التعليمي
  final String? educationStatus; // الحالة الدراسية
  final String? healthCondition;

  // === السكن والوضع المادي ===
  final String? governorate;
  final String? city;
  final String? neighborhood;
  final String? landmark;
  final String? housingCondition; // حالة السكن
  final String? housingOwnership; // ملكية السكن
  final String? monthlyIncome; // الدخل الشهري
  final String? incomeSources; // مصادر الدخل

  // === المستندات ===
  final String? birthCertificateUrl;
  final String? otherDocumentsUrl;

  // === الكفالة (يتم إدخالها لاحقاً) ===
  final String? sponsorshipStatus; // مكفول، غير مكفول
  final double? sponsorshipAmount;
  final String? sponsorshipType; // مالية، طرود غذائية، صحية، دراسية
  final DateTime? sponsorshipDate;

  // === ملاحظات ===
  final String? notes;

  // الحقول التلقائية
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final DateTime? archivedAt;

  Orphan({
    this.id,
    required this.institutionId,
    required this.kafalaHeadId,
    required this.orphanNo,

    // الإسم الخماسي
    required this.orphanName,
    required this.fatherName,
    required this.grandfatherName,
    required this.greatGrandfatherName,
    required this.familyName,

    // المعلومات الشخصية
    required this.orphanIdNumber,
    required this.dateOfBirth,
    required this.gender,
    required this.orphanType,
    this.healthStatus,
    this.orphanPhotoUrl,

    // بيانات الأب
    this.fatherFullName,
    this.fatherIdNumber,
    this.fatherIdPhotoUrl,
    this.fatherAge,

    // بيانات الأم
    this.motherFullName,
    this.motherIdNumber,
    this.motherIdPhotoUrl,
    this.motherAge,

    // بيانات المتوفي
    this.deceasedFullName,
    this.deceasedIdNumber,
    this.deceasedPhotoUrl,
    this.causeOfDeath,
    this.dateOfDeath,
    this.deathCertificateUrl,

    // بيانات المعيل
    this.breadwinnerFullName,
    this.breadwinnerIdNumber,
    this.breadwinnerIdPhotoUrl,
    this.breadwinnerKinship,
    this.breadwinnerMaritalStatus,
    this.breadwinnerAge,

    // بيانات العائلة
    this.numberOfMales = 0,
    this.numberOfFemales = 0,
    this.totalFamilyMembers = 0,
    this.mobileNumber,
    this.alternativeMobileNumber,
    this.whatsappNumber,

    // التعليم والصحة
    this.schoolName,
    this.grade,
    this.educationLevel,
    this.educationStatus,
    this.healthCondition,

    // السكن والوضع المادي
    this.governorate,
    this.city,
    this.neighborhood,
    this.landmark,
    this.housingCondition,
    this.housingOwnership,
    this.monthlyIncome,
    this.incomeSources,

    // المستندات
    this.birthCertificateUrl,
    this.otherDocumentsUrl,

    // الكفالة
    this.sponsorshipStatus,
    this.sponsorshipAmount,
    this.sponsorshipType,
    this.sponsorshipDate,

    // ملاحظات
    this.notes,

    // الحقول التلقائية
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.archivedAt,
  });

  // الإسم الكامل
  String get orphanFullName =>
      '$orphanName $fatherName $grandfatherName  $familyName'.trim();

  String get orphanFatherFullName =>
      ' $fatherName $grandfatherName $greatGrandfatherName $familyName'.trim();
  // ===== Helpers آمنة للتحويل =====
  static String? _asString(dynamic v) {
    if (v == null) return null;
    return v.toString();
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  static bool _asBool(dynamic v, {bool defaultValue = false}) {
    if (v == null) return defaultValue;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    return defaultValue;
  }

  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is int) {
      // seconds or millis
      if (v > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.fromMillisecondsSinceEpoch(v * 1000);
    }
    if (v is String) {
      // جرّب ISO أولاً
      try {
        return DateTime.parse(v);
      } catch (_) {
        // جرّب dd/MM/yyyy
        try {
          final parts = v.split('/');
          if (parts.length == 3) {
            final d = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            final y = int.tryParse(parts[2]);
            if (d != null && m != null && y != null) {
              return DateTime(y, m, d);
            }
          }
        } catch (_) {}
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'institutionId': institutionId,
      'kafalaHeadId': kafalaHeadId,
      'orphanNo': orphanNo,

      // الإسم الخماسي
      'orphanName': orphanName,
      'fatherName': fatherName,
      'grandfatherName': grandfatherName,
      'greatGrandfatherName': greatGrandfatherName,
      'familyName': familyName,
      'fullName': orphanFullName,

      // المعلومات الشخصية
      'orphanIdNumber': orphanIdNumber,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender,
      'orphanType': orphanType,
      'healthStatus': healthStatus,
      'orphanPhotoUrl': orphanPhotoUrl,

      // بيانات الأب
      'fatherFullName': fatherFullName,
      'fatherIdNumber': fatherIdNumber,
      'fatherIdPhotoUrl': fatherIdPhotoUrl,
      'fatherAge': fatherAge,

      // بيانات الأم
      'motherFullName': motherFullName,
      'motherIdNumber': motherIdNumber,
      'motherIdPhotoUrl': motherIdPhotoUrl,
      'motherAge': motherAge,

      // بيانات المتوفي
      'deceasedFullName': deceasedFullName,
      'deceasedIdNumber': deceasedIdNumber,
      'deceasedPhotoUrl': deceasedPhotoUrl,
      'causeOfDeath': causeOfDeath,
      'dateOfDeath': dateOfDeath != null
          ? Timestamp.fromDate(dateOfDeath!)
          : null,
      'deathCertificateUrl': deathCertificateUrl,

      // بيانات المعيل
      'breadwinnerFullName': breadwinnerFullName,
      'breadwinnerIdNumber': breadwinnerIdNumber,
      'breadwinnerIdPhotoUrl': breadwinnerIdPhotoUrl,
      'breadwinnerKinship': breadwinnerKinship,
      'breadwinnerMaritalStatus': breadwinnerMaritalStatus,
      'breadwinnerAge': breadwinnerAge,

      // بيانات العائلة
      'numberOfMales': numberOfMales,
      'numberOfFemales': numberOfFemales,
      'totalFamilyMembers': totalFamilyMembers,
      'mobileNumber': mobileNumber,
      'alternativeMobileNumber': alternativeMobileNumber,
      'whatsappNumber': whatsappNumber,

      // التعليم والصحة
      'schoolName': schoolName,
      'grade': grade,
      'educationLevel': educationLevel,
      'educationStatus': educationStatus,
      'healthCondition': healthCondition,

      // السكن والوضع المادي
      'governorate': governorate,
      'city': city,
      'neighborhood': neighborhood,
      'landmark': landmark,
      'housingCondition': housingCondition,
      'housingOwnership': housingOwnership,
      'monthlyIncome': monthlyIncome,
      'incomeSources': incomeSources,

      // المستندات
      'birthCertificateUrl': birthCertificateUrl,
      'otherDocumentsUrl': otherDocumentsUrl,

      // الكفالة
      'sponsorshipStatus': sponsorshipStatus,
      'sponsorshipAmount': sponsorshipAmount,
      'sponsorshipType': sponsorshipType,
      'sponsorshipDate': sponsorshipDate != null
          ? Timestamp.fromDate(sponsorshipDate!)
          : null,

      // ملاحظات
      'notes': notes,

      // الحقول التلقائية
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isArchived': isArchived,
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
    };
  }

  factory Orphan.fromMap(Map<String, dynamic> map, {String? id}) {
    return Orphan(
      id: id ?? _asString(map['id']),
      institutionId: _asString(map['institutionId']) ?? '',
      kafalaHeadId: _asString(map['kafalaHeadId']) ?? '',
      orphanNo: _asInt(map['orphanNo']) ?? 0,

      // الإسم الخماسي
      orphanName: _asString(map['orphanName']) ?? _asString(map['name']) ?? '',
      fatherName: _asString(map['fatherName']) ?? '',
      grandfatherName: _asString(map['grandfatherName']) ?? '',
      greatGrandfatherName: _asString(map['greatGrandfatherName']) ?? '',
      familyName: _asString(map['familyName']) ?? '',

      // المعلومات الشخصية
      
      orphanIdNumber: _asInt(map['orphanIdNumber']) ?? 0,
      dateOfBirth: _asDate(map['dateOfBirth']) ?? DateTime(2000, 1, 1),
      gender: _asString(map['gender']) ?? '',
      orphanType: _asString(map['orphanType']) ?? '',
      healthStatus: _asString(map['healthStatus']),
      orphanPhotoUrl: _asString(map['orphanPhotoUrl']),

      // بيانات الأب
      fatherFullName: _asString(map['fatherFullName']),
      fatherIdNumber: _asInt(map['fatherIdNumber']),
      fatherIdPhotoUrl: _asString(map['fatherIdPhotoUrl']),
      fatherAge: _asInt(map['fatherAge']),

      // بيانات الأم
      motherFullName: _asString(map['motherFullName']),
      motherIdNumber: _asInt(map['motherIdNumber']),
      motherIdPhotoUrl: _asString(map['motherIdPhotoUrl']),
      motherAge: _asInt(map['motherAge']),

      // بيانات المتوفي
      deceasedFullName: _asString(map['deceasedFullName']),
      deceasedIdNumber: _asInt(map['deceasedIdNumber']),
      deceasedPhotoUrl: _asString(map['deceasedPhotoUrl']),
      causeOfDeath: _asString(map['causeOfDeath']),
      dateOfDeath: _asDate(map['dateOfDeath']),
      deathCertificateUrl: _asString(map['deathCertificateUrl']),

      // بيانات المعيل
      breadwinnerFullName: _asString(map['breadwinnerFullName']),
      breadwinnerIdNumber: _asInt(map['breadwinnerIdNumber']),
      breadwinnerIdPhotoUrl: _asString(map['breadwinnerIdPhotoUrl']),
      breadwinnerKinship: _asString(map['breadwinnerKinship']),
      breadwinnerMaritalStatus: _asString(map['breadwinnerMaritalStatus']),
      breadwinnerAge: _asInt(map['breadwinnerAge']),

      // بيانات العائلة
      numberOfMales: _asInt(map['numberOfMales']) ?? 0,
      numberOfFemales: _asInt(map['numberOfFemales']) ?? 0,
      totalFamilyMembers: _asInt(map['totalFamilyMembers']) ?? 0,
      mobileNumber: _asInt(map['mobileNumber']),
      alternativeMobileNumber: _asInt(map['alternativeMobileNumber']),
      whatsappNumber: _asInt(map['whatsappNumber']),

      // التعليم والصحة
      schoolName: _asString(map['schoolName']),
      grade: _asString(map['grade']),
      educationLevel: _asString(map['educationLevel']),
      educationStatus: _asString(map['educationStatus']),
      healthCondition: _asString(map['healthCondition']),

      // السكن والوضع المادي
      governorate: _asString(map['governorate']),
      city: _asString(map['city']),
      neighborhood: _asString(map['neighborhood']),
      landmark: _asString(map['landmark']),
      housingCondition: _asString(map['housingCondition']),
      housingOwnership: _asString(map['housingOwnership']),
      monthlyIncome: _asString(map['monthlyIncome']),
      incomeSources: _asString(map['incomeSources']),

      // المستندات
      birthCertificateUrl: _asString(map['birthCertificateUrl']),
      otherDocumentsUrl: _asString(map['otherDocumentsUrl']),

      // الكفالة
      sponsorshipStatus: _asString(map['sponsorshipStatus']),
      sponsorshipAmount: _asDouble(map['sponsorshipAmount']),
      sponsorshipType: _asString(map['sponsorshipType']),
      sponsorshipDate: _asDate(map['sponsorshipDate']),

      // ملاحظات
      notes: _asString(map['notes']),

      // الحقول التلقائية
      createdAt: _asDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _asDate(map['updatedAt']) ?? DateTime.now(),
      isArchived: _asBool(map['isArchived'], defaultValue: false),
      archivedAt: _asDate(map['archivedAt']),
    );
  }

  Orphan copyWith({
    String? id,
    String? institutionId,
    String? kafalaHeadId,
    int? orphanNo,
    // الإسم الخماسي
    String? orphanName,
    String? fatherName,
    String? grandfatherName,
    String? greatGrandfatherName,
    String? familyName,
    // المعلومات الشخصية
    int? orphanIdNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? orphanType,
    String? healthStatus,
    String? orphanPhotoUrl,
    // بيانات الأب
    String? fatherFullName,
    int? fatherIdNumber,
    String? fatherIdPhotoUrl,
    int? fatherAge,
    // بيانات الأم
    String? motherFullName,
    int? motherIdNumber,
    String? motherIdPhotoUrl,
    int? motherAge,
    // بيانات المتوفي
    String? deceasedFullName,
    int? deceasedIdNumber,
    String? deceasedPhotoUrl,
    String? causeOfDeath,
    DateTime? dateOfDeath,
    String? deathCertificateUrl,
    // بيانات المعيل
    String? breadwinnerFullName,
    int? breadwinnerIdNumber,
    String? breadwinnerIdPhotoUrl,
    String? breadwinnerKinship,
    String? breadwinnerMaritalStatus,
    int? breadwinnerAge,
    // بيانات العائلة
    int? numberOfMales,
    int? numberOfFemales,
    int? totalFamilyMembers,
    int? mobileNumber,
    int? alternativeMobileNumber,
    int? whatsappNumber,
    // التعليم والصحة
    String? schoolName,
    String? grade,
    String? educationLevel,
    String? educationStatus,
    String? healthCondition,
    // السكن والوضع المادي
    String? governorate,
    String? city,
    String? neighborhood,
    String? landmark,
    String? housingCondition,
    String? housingOwnership,
    String? monthlyIncome,
    String? incomeSources,
    // المستندات
    String? birthCertificateUrl,
    String? otherDocumentsUrl,
    // الكفالة
    String? sponsorshipStatus,
    double? sponsorshipAmount,
    String? sponsorshipType,
    DateTime? sponsorshipDate,
    // ملاحظات
    String? notes,
    // الحقول التلقائية
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    DateTime? archivedAt,
  }) {
    return Orphan(
      id: id ?? this.id,
      institutionId: institutionId ?? this.institutionId,
      kafalaHeadId: kafalaHeadId ?? this.kafalaHeadId,
      orphanNo: orphanNo ?? this.orphanNo,
      // الإسم الخماسي
      orphanName: orphanName ?? this.orphanName,
      fatherName: fatherName ?? this.fatherName,
      grandfatherName: grandfatherName ?? this.grandfatherName,
      greatGrandfatherName: greatGrandfatherName ?? this.greatGrandfatherName,
      familyName: familyName ?? this.familyName,
      // المعلومات الشخصية
      orphanIdNumber: orphanIdNumber ?? this.orphanIdNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      orphanType: orphanType ?? this.orphanType,
      healthStatus: healthStatus ?? this.healthStatus,
      orphanPhotoUrl: orphanPhotoUrl ?? this.orphanPhotoUrl,
      // بيانات الأب
      fatherFullName: fatherFullName ?? this.fatherFullName,
      fatherIdNumber: fatherIdNumber ?? this.fatherIdNumber,
      fatherIdPhotoUrl: fatherIdPhotoUrl ?? this.fatherIdPhotoUrl,
      fatherAge: fatherAge ?? this.fatherAge,
      // بيانات الأم
      motherFullName: motherFullName ?? this.motherFullName,
      motherIdNumber: motherIdNumber ?? this.motherIdNumber,
      motherIdPhotoUrl: motherIdPhotoUrl ?? this.motherIdPhotoUrl,
      motherAge: motherAge ?? this.motherAge,
      // بيانات المتوفي
      deceasedFullName: deceasedFullName ?? this.deceasedFullName,
      deceasedIdNumber: deceasedIdNumber ?? this.deceasedIdNumber,
      deceasedPhotoUrl: deceasedPhotoUrl ?? this.deceasedPhotoUrl,
      causeOfDeath: causeOfDeath ?? this.causeOfDeath,
      dateOfDeath: dateOfDeath ?? this.dateOfDeath,
      deathCertificateUrl: deathCertificateUrl ?? this.deathCertificateUrl,
      // بيانات المعيل
      breadwinnerFullName: breadwinnerFullName ?? this.breadwinnerFullName,
      breadwinnerIdNumber: breadwinnerIdNumber ?? this.breadwinnerIdNumber,
      breadwinnerIdPhotoUrl:
          breadwinnerIdPhotoUrl ?? this.breadwinnerIdPhotoUrl,
      breadwinnerKinship: breadwinnerKinship ?? this.breadwinnerKinship,
      breadwinnerMaritalStatus:
          breadwinnerMaritalStatus ?? this.breadwinnerMaritalStatus,
      breadwinnerAge: breadwinnerAge ?? this.breadwinnerAge,
      // بيانات العائلة
      numberOfMales: numberOfMales ?? this.numberOfMales,
      numberOfFemales: numberOfFemales ?? this.numberOfFemales,
      totalFamilyMembers: totalFamilyMembers ?? this.totalFamilyMembers,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      alternativeMobileNumber:
          alternativeMobileNumber ?? this.alternativeMobileNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      // التعليم والصحة
      schoolName: schoolName ?? this.schoolName,
      grade: grade ?? this.grade,
      educationLevel: educationLevel ?? this.educationLevel,
      educationStatus: educationStatus ?? this.educationStatus,
      healthCondition: healthCondition ?? this.healthCondition,
      // السكن والوضع المادي
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      landmark: landmark ?? this.landmark,
      housingCondition: housingCondition ?? this.housingCondition,
      housingOwnership: housingOwnership ?? this.housingOwnership,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      incomeSources: incomeSources ?? this.incomeSources,
      // المستندات
      birthCertificateUrl: birthCertificateUrl ?? this.birthCertificateUrl,
      otherDocumentsUrl: otherDocumentsUrl ?? this.otherDocumentsUrl,
      // الكفالة
      sponsorshipStatus: sponsorshipStatus ?? this.sponsorshipStatus,
      sponsorshipAmount: sponsorshipAmount ?? this.sponsorshipAmount,
      sponsorshipType: sponsorshipType ?? this.sponsorshipType,
      sponsorshipDate: sponsorshipDate ?? this.sponsorshipDate,
      // ملاحظات
      notes: notes ?? this.notes,
      // الحقول التلقائية
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}
