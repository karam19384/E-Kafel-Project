class ReportFilter {
  final String? reportType;
  final DateTime? startDate;
  final DateTime? endDate;

  // === فلاتر عامة ===
  final String? governorate;
  final String? city;
  final String? neighborhood;
  final String? searchQuery;
  final String? sortBy;
  final bool? sortAscending;

  // === فلاتر الأيتام ===
  final String? orphanStatus;
  final String? orphanType;
  final String? gender;
  final String? educationStatus;
  final String? healthCondition;
  final String? housingCondition;
  final String? sponsorshipStatus;
  final String? educationLevel;
  final String? housingOwnership;

  // === فلاتر رقمية للأيتام ===
  final int? minOrphanNo;
  final int? maxOrphanNo;
  final int? minOrphanIdNumber;
  final int? maxOrphanIdNumber;
  final int? minAge;
  final int? maxAge;
  final int? minFamilyMembers;
  final int? maxFamilyMembers;

  // === فلاتر الكفالات ===
  final String? sponsorType;
  final String? financialStatus;
  final double? minSponsorshipAmount;
  final double? maxSponsorshipAmount;
  final double? minBudget;
  final double? maxBudget;
  final double? minSpent;
  final double? maxSpent;

  // === فلاتر المهام ===
  final String? taskPriority;
  final String? taskStatus;
  final String? assignedTo;
  final String? taskType;
  final String? taskLocation;

  // === فلاتر المشرفين ===
  final String? userRole;
  final String? functionalLodgment;
  final String? areaResponsibleFor;
  final String? uid;

  // === فلاتر الزيارات ===
  final String? visitStatus;
  final String? visitArea;

  ReportFilter({
    this.reportType,
    this.startDate,
    this.endDate,

    // فلاتر عامة
    this.governorate,
    this.city,
    this.neighborhood,
    this.searchQuery,
    this.sortBy,
    this.sortAscending = true,

    // فلاتر الأيتام
    this.orphanStatus,
    this.orphanType,
    this.gender,
    this.educationStatus,
    this.healthCondition,
    this.housingCondition,
    this.sponsorshipStatus,
    this.educationLevel,
    this.housingOwnership,

    // فلاتر رقمية للأيتام
    this.minOrphanNo,
    this.maxOrphanNo,
    this.minOrphanIdNumber,
    this.maxOrphanIdNumber,
    this.minAge,
    this.maxAge,
    this.minFamilyMembers,
    this.maxFamilyMembers,

    // فلاتر الكفالات
    this.sponsorType,
    this.financialStatus,
    this.minSponsorshipAmount,
    this.maxSponsorshipAmount,
    this.minBudget,
    this.maxBudget,
    this.minSpent,
    this.maxSpent,

    // فلاتر المهام
    this.taskPriority,
    this.taskStatus,
    this.assignedTo,
    this.taskType,
    this.taskLocation,

    // فلاتر المشرفين
    this.userRole,
    this.functionalLodgment,
    this.areaResponsibleFor,
    this.uid,

    // فلاتر الزيارات
    this.visitStatus,
    this.visitArea,
  });

  ReportFilter copyWith({
    String? reportType,
    DateTime? startDate,
    DateTime? endDate,

    // فلاتر عامة
    String? governorate,
    String? city,
    String? neighborhood,
    String? searchQuery,
    String? sortBy,
    bool? sortAscending,

    // فلاتر الأيتام
    String? orphanStatus,
    String? orphanType,
    String? gender,
    String? educationStatus,
    String? healthCondition,
    String? housingCondition,
    String? sponsorshipStatus,
    String? educationLevel,
    String? housingOwnership,

    // فلاتر رقمية للأيتام
    int? minOrphanNo,
    int? maxOrphanNo,
    int? minOrphanIdNumber,
    int? maxOrphanIdNumber,
    int? minAge,
    int? maxAge,
    int? minFamilyMembers,
    int? maxFamilyMembers,

    // فلاتر الكفالات
    String? sponsorType,
    String? financialStatus,
    double? minSponsorshipAmount,
    double? maxSponsorshipAmount,
    double? minBudget,
    double? maxBudget,
    double? minSpent,
    double? maxSpent,

    // فلاتر المهام
    String? taskPriority,
    String? taskStatus,
    String? assignedTo,
    String? taskType,
    String? taskLocation,

    // فلاتر المشرفين
    String? userRole,
    String? functionalLodgment,
    String? areaResponsibleFor,
    String? uid,

    // فلاتر الزيارات
    String? visitStatus,
    String? visitArea,
  }) {
    return ReportFilter(
      reportType: reportType ?? this.reportType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,

      // فلاتر عامة
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,

      // فلاتر الأيتام
      orphanStatus: orphanStatus ?? this.orphanStatus,
      orphanType: orphanType ?? this.orphanType,
      gender: gender ?? this.gender,
      educationStatus: educationStatus ?? this.educationStatus,
      healthCondition: healthCondition ?? this.healthCondition,
      housingCondition: housingCondition ?? this.housingCondition,
      sponsorshipStatus: sponsorshipStatus ?? this.sponsorshipStatus,
      educationLevel: educationLevel ?? this.educationLevel,
      housingOwnership: housingOwnership ?? this.housingOwnership,

      // فلاتر رقمية للأيتام
      minOrphanNo: minOrphanNo ?? this.minOrphanNo,
      maxOrphanNo: maxOrphanNo ?? this.maxOrphanNo,
      minOrphanIdNumber: minOrphanIdNumber ?? this.minOrphanIdNumber,
      maxOrphanIdNumber: maxOrphanIdNumber ?? this.maxOrphanIdNumber,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      minFamilyMembers: minFamilyMembers ?? this.minFamilyMembers,
      maxFamilyMembers: maxFamilyMembers ?? this.maxFamilyMembers,

      // فلاتر الكفالات
      sponsorType: sponsorType ?? this.sponsorType,
      financialStatus: financialStatus ?? this.financialStatus,
      minSponsorshipAmount: minSponsorshipAmount ?? this.minSponsorshipAmount,
      maxSponsorshipAmount: maxSponsorshipAmount ?? this.maxSponsorshipAmount,
      minBudget: minBudget ?? this.minBudget,
      maxBudget: maxBudget ?? this.maxBudget,
      minSpent: minSpent ?? this.minSpent,
      maxSpent: maxSpent ?? this.maxSpent,

      // فلاتر المهام
      taskPriority: taskPriority ?? this.taskPriority,
      taskStatus: taskStatus ?? this.taskStatus,
      assignedTo: assignedTo ?? this.assignedTo,
      taskType: taskType ?? this.taskType,
      taskLocation: taskLocation ?? this.taskLocation,

      // فلاتر المشرفين
      userRole: userRole ?? this.userRole,
      functionalLodgment: functionalLodgment ?? this.functionalLodgment,
      areaResponsibleFor: areaResponsibleFor ?? this.areaResponsibleFor,
      uid: uid ?? this.uid,
      // فلاتر الزيارات
      visitStatus: visitStatus ?? this.visitStatus,
      visitArea: visitArea ?? this.visitArea,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportType': reportType,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),

      // فلاتر عامة
      'governorate': governorate,
      'city': city,
      'neighborhood': neighborhood,
      'searchQuery': searchQuery,
      'sortBy': sortBy,
      'sortAscending': sortAscending,

      // فلاتر الأيتام
      'orphanStatus': orphanStatus,
      'orphanType': orphanType,
      'gender': gender,
      'educationStatus': educationStatus,
      'healthCondition': healthCondition,
      'housingCondition': housingCondition,
      'sponsorshipStatus': sponsorshipStatus,
      'educationLevel': educationLevel,
      'housingOwnership': housingOwnership,

      // فلاتر رقمية للأيتام
      'minOrphanNo': minOrphanNo,
      'maxOrphanNo': maxOrphanNo,
      'minOrphanIdNumber': minOrphanIdNumber,
      'maxOrphanIdNumber': maxOrphanIdNumber,
      'minAge': minAge,
      'maxAge': maxAge,
      'minFamilyMembers': minFamilyMembers,
      'maxFamilyMembers': maxFamilyMembers,

      // فلاتر الكفالات
      'sponsorType': sponsorType,
      'financialStatus': financialStatus,
      'minSponsorshipAmount': minSponsorshipAmount,
      'maxSponsorshipAmount': maxSponsorshipAmount,
      'minBudget': minBudget,
      'maxBudget': maxBudget,
      'minSpent': minSpent,
      'maxSpent': maxSpent,

      // فلاتر المهام
      'taskPriority': taskPriority,
      'taskStatus': taskStatus,
      'assignedTo': assignedTo,
      'taskType': taskType,
      'taskLocation': taskLocation,

      // فلاتر المشرفين
      'userRole': userRole,
      'functionalLodgment': functionalLodgment,
      'areaResponsibleFor': areaResponsibleFor,
      'uid': uid,
      // فلاتر الزيارات
      'visitStatus': visitStatus,
      'visitArea': visitArea,
    };
  }

  factory ReportFilter.fromMap(Map<String, dynamic> map) {
    return ReportFilter(
      reportType: map['reportType'] as String?,
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : null,
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,

      // فلاتر عامة
      governorate: map['governorate'] as String?,
      city: map['city'] as String?,
      neighborhood: map['neighborhood'] as String?,
      searchQuery: map['searchQuery'] as String?,
      sortBy: map['sortBy'] as String?,
      sortAscending: map['sortAscending'] as bool? ?? true,

      // فلاتر الأيتام
      orphanStatus: map['orphanStatus'] as String?,
      orphanType: map['orphanType'] as String?,
      gender: map['gender'] as String?,
      educationStatus: map['educationStatus'] as String?,
      healthCondition: map['healthCondition'] as String?,
      housingCondition: map['housingCondition'] as String?,
      sponsorshipStatus: map['sponsorshipStatus'] as String?,
      educationLevel: map['educationLevel'] as String?,
      housingOwnership: map['housingOwnership'] as String?,

      // فلاتر رقمية للأيتام
      minOrphanNo: map['minOrphanNo'] as int?,
      maxOrphanNo: map['maxOrphanNo'] as int?,
      minOrphanIdNumber: map['minOrphanIdNumber'] as int?,
      maxOrphanIdNumber: map['maxOrphanIdNumber'] as int?,
      minAge: map['minAge'] as int?,
      maxAge: map['maxAge'] as int?,
      minFamilyMembers: map['minFamilyMembers'] as int?,
      maxFamilyMembers: map['maxFamilyMembers'] as int?,

      // فلاتر الكفالات
      sponsorType: map['sponsorType'] as String?,
      financialStatus: map['financialStatus'] as String?,
      minSponsorshipAmount: map['minSponsorshipAmount'] as double?,
      maxSponsorshipAmount: map['maxSponsorshipAmount'] as double?,
      minBudget: map['minBudget'] as double?,
      maxBudget: map['maxBudget'] as double?,
      minSpent: map['minSpent'] as double?,
      maxSpent: map['maxSpent'] as double?,

      // فلاتر المهام
      taskPriority: map['taskPriority'] as String?,
      taskStatus: map['taskStatus'] as String?,
      assignedTo: map['assignedTo'] as String?,
      taskType: map['taskType'] as String?,
      taskLocation: map['taskLocation'] as String?,

      // فلاتر المشرفين
      userRole: map['userRole'] as String?,
      functionalLodgment: map['functionalLodgment'] as String?,
      areaResponsibleFor: map['areaResponsibleFor'] as String?,
      uid: map['uid'],
      // فلاتر الزيارات
      visitStatus: map['visitStatus'] as String?,
      visitArea: map['visitArea'] as String?,
    );
  }

  bool get hasFilters {
    return reportType != null ||
        startDate != null ||
        endDate != null ||
        governorate != null ||
        city != null ||
        neighborhood != null ||
        searchQuery != null ||
        orphanStatus != null ||
        orphanType != null ||
        gender != null ||
        educationStatus != null ||
        healthCondition != null ||
        housingCondition != null ||
        sponsorshipStatus != null ||
        educationLevel != null ||
        housingOwnership != null ||
        minOrphanNo != null ||
        maxOrphanNo != null ||
        minOrphanIdNumber != null ||
        maxOrphanIdNumber != null ||
        minAge != null ||
        maxAge != null ||
        minFamilyMembers != null ||
        maxFamilyMembers != null ||
        sponsorType != null ||
        financialStatus != null ||
        minSponsorshipAmount != null ||
        maxSponsorshipAmount != null ||
        minBudget != null ||
        maxBudget != null ||
        minSpent != null ||
        maxSpent != null ||
        taskPriority != null ||
        taskStatus != null ||
        assignedTo != null ||
        taskType != null ||
        taskLocation != null ||
        userRole != null ||
        functionalLodgment != null ||
        areaResponsibleFor != null ||
        uid != null ||
        visitStatus != null ||
        visitArea != null;
  }

  // دالة مساعدة للحصول على خيارات الفرز المناسبة لنوع التقرير
  List<Map<String, String>> getSortOptions() {
    switch (reportType) {
      case 'أيتام':
        return [
          {'value': 'fullName', 'label': 'الاسم الكامل'},
          {'value': 'orphanName', 'label': 'اسم اليتيم'},
          {'value': 'familyName', 'label': 'اسم العائلة'},
          {'value': 'city', 'label': 'المدينة'},
          {'value': 'governorate', 'label': 'المحافظة'},
          {'value': 'dateOfBirth', 'label': 'تاريخ الميلاد'},
          {'value': 'createdAt', 'label': 'تاريخ التسجيل'},
          {'value': 'sponsorshipStatus', 'label': 'حالة الكفالة'},
          {'value': 'orphanNo', 'label': 'رقم اليتيم'},
        ];
      case 'كفالات':
        return [
          {'value': 'name', 'label': 'اسم المشروع'},
          {'value': 'type', 'label': 'النوع'},
          {'value': 'budget', 'label': 'الميزانية'},
          {'value': 'spent', 'label': 'المصروفات'},
          {'value': 'createdAt', 'label': 'تاريخ الإنشاء'},
          {'value': 'status', 'label': 'الحالة'},
        ];
      case 'مشرفين':
        return [
          {'value': 'uid', 'label': 'المعرف'},
          {'value': 'fullName', 'label': 'الاسم'},
          {'value': 'userRole', 'label': 'الدور'},
          {'value': 'areaResponsibleFor', 'label': 'المنطقة المسؤولة'},
          {'value': 'functionalLodgment', 'label': 'السكن الوظيفي'},
          {'value': 'createdAt', 'label': 'تاريخ التسجيل'},
        ];
      case 'مهام':
        return [
          {'value': 'title', 'label': 'عنوان المهمة'},
          {'value': 'dueDate', 'label': 'تاريخ الاستحقاق'},
          {'value': 'priority', 'label': 'الأولوية'},
          {'value': 'status', 'label': 'الحالة'},
          {'value': 'taskType', 'label': 'نوع المهمة'},
          {'value': 'createdAt', 'label': 'تاريخ الإنشاء'},
        ];
      case 'زيارات':
        return [
          {'value': 'orphanName', 'label': 'اسم اليتيم'},
          {'value': 'date', 'label': 'تاريخ الزيارة'},
          {'value': 'area', 'label': 'المنطقة'},
        ];
      default:
        return [];
    }
  }

  @override
  String toString() {
    return 'ReportFilter{reportType: $reportType, governorate: $governorate, city: $city, neighborhood: $neighborhood, searchQuery: $searchQuery, sortBy: $sortBy, sortAscending: $sortAscending, orphanStatus: $orphanStatus, orphanType: $orphanType, gender: $gender, educationStatus: $educationStatus, healthCondition: $healthCondition, housingCondition: $housingCondition, sponsorshipStatus: $sponsorshipStatus, educationLevel: $educationLevel, housingOwnership: $housingOwnership, sponsorType: $sponsorType, financialStatus: $financialStatus, minSponsorshipAmount: $minSponsorshipAmount, maxSponsorshipAmount: $maxSponsorshipAmount, taskPriority: $taskPriority, taskStatus: $taskStatus, assignedTo: $assignedTo, taskType: $taskType, taskLocation: $taskLocation, userRole: $userRole, functionalLodgment: $functionalLodgment, areaResponsibleFor: $areaResponsibleFor, visitStatus: $visitStatus, visitArea: $visitArea}';
  }
}
