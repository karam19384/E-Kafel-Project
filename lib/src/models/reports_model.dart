import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_kafel/src/models/filter_model.dart';

class ReportModel {
  final String reportId;
  final String kafalaHeadId;
  final String supervisorId;
  final String institutionId;
  final String title;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> filters;
  final Timestamp createdAt;
  final String? reportType;
  final String? region;
  final String? city;
  final String? orphanStatus;
  final String? sponsorType;
  final String? financialStatus;
  final String? searchQuery;
  final String? sortBy;
  final bool? sortAscending;

  ReportModel({
    required this.reportId,
    required this.kafalaHeadId,
    required this.supervisorId,
    required this.institutionId,
    required this.title,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.filters,
    required this.createdAt,
    this.reportType,
    this.region,
    this.city,
    this.orphanStatus,
    this.sponsorType,
    this.financialStatus,
    this.searchQuery,
    this.sortBy,
    this.sortAscending = true,
  });
// في class ReportModel - أضف هذه الدالة
ReportFilter toFilter() {
  return ReportFilter(
    reportType: reportType,
    governorate: region,
    city: city,
    orphanStatus: orphanStatus,
    sponsorType: sponsorType,
    financialStatus: financialStatus,
    searchQuery: searchQuery,
    sortBy: sortBy,
    sortAscending: sortAscending,
    startDate: startDate,
    endDate: endDate,
  );
}
  ReportModel copyWith({
    String? reportId,
    String? kafalaHeadId,
    String? supervisorId,
    String? institutionId,
    String? title,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? filters,
    Timestamp? createdAt,
    String? reportType,
    String? region,
    String? city,
    String? orphanStatus,
    String? sponsorType,
    String? financialStatus,
    String? searchQuery,
    String? sortBy,
    bool? sortAscending,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      kafalaHeadId: kafalaHeadId ?? this.kafalaHeadId,
      supervisorId: supervisorId ?? this.supervisorId,
      institutionId: institutionId ?? this.institutionId,
      title: title ?? this.title,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      filters: filters ?? this.filters,
      createdAt: createdAt ?? this.createdAt,
      reportType: reportType ?? this.reportType,
      region: region ?? this.region,
      city: city ?? this.city,
      orphanStatus: orphanStatus ?? this.orphanStatus,
      sponsorType: sponsorType ?? this.sponsorType,
      financialStatus: financialStatus ?? this.financialStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'kafalaHeadId': kafalaHeadId,
      'supervisorId': supervisorId,
      'institutionId': institutionId,
      'title': title,
      'type': type,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'filters': filters,
      'createdAt': createdAt,
      'reportType': reportType,
      'region': region,
      'city': city,
      'orphanStatus': orphanStatus,
      'sponsorType': sponsorType,
      'financialStatus': financialStatus,
      'searchQuery': searchQuery,
      'sortBy': sortBy,
      'sortAscending': sortAscending,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      reportId: map['reportId'] as String,
      kafalaHeadId: map['kafalaHeadId'] as String,
      supervisorId: map['supervisorId'] as String,
      institutionId: map['institutionId'] as String,
      title: map['title'] as String,
      type: map['type'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      filters: Map<String, dynamic>.from(map['filters'] as Map? ?? {}),
      createdAt: map['createdAt'] as Timestamp,
      reportType: map['reportType'] as String?,
      region: map['region'] as String?,
      city: map['city'] as String?,
      orphanStatus: map['orphanStatus'] as String?,
      sponsorType: map['sponsorType'] as String?,
      financialStatus: map['financialStatus'] as String?,
      searchQuery: map['searchQuery'] as String?,
      sortBy: map['sortBy'] as String?,
      sortAscending: map['sortAscending'] as bool?,
    );
  }

  bool get hasFilters {
    return reportType != null ||
        region != null ||
        city != null ||
        orphanStatus != null ||
        sponsorType != null ||
        financialStatus != null ||
        searchQuery != null ||
        sortBy != null ||
        filters.isNotEmpty;
  }

  String get filtersSummary {
    final List<String> activeFilters = [];
    
    if (reportType != null) activeFilters.add('نوع التقرير: $reportType');
    if (region != null) activeFilters.add('المنطقة: $region');
    if (city != null) activeFilters.add('المدينة: $city');
    if (orphanStatus != null) activeFilters.add('حالة اليتيم: $orphanStatus');
    if (sponsorType != null) activeFilters.add('نوع الكفالة: $sponsorType');
    if (financialStatus != null) activeFilters.add('الحالة المالية: $financialStatus');
    if (searchQuery != null) activeFilters.add('بحث: $searchQuery');
    if (sortBy != null) activeFilters.add('ترتيب حسب: $sortBy');
    
    filters.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        activeFilters.add('$key: $value');
      }
    });
    
    return activeFilters.isEmpty ? 'لا توجد فلاتر' : activeFilters.join(' • ');
  }

  factory ReportModel.fromFilter({
    required String kafalaHeadId,
    required String supervisorId,
    required String institutionId,
    required String title,
    required String type,
    required Map<String, dynamic> filterData,
  }) {
    return ReportModel(
      reportId: DateTime.now().millisecondsSinceEpoch.toString(),
      kafalaHeadId: kafalaHeadId,
      supervisorId: supervisorId,
      institutionId: institutionId,
      title: title,
      type: type,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      filters: filterData,
      createdAt: Timestamp.now(),
      reportType: filterData['reportType'] as String?,
      region: filterData['region'] as String?,
      city: filterData['city'] as String?,
      orphanStatus: filterData['orphanStatus'] as String?,
      sponsorType: filterData['sponsorType'] as String?,
      financialStatus: filterData['financialStatus'] as String?,
      searchQuery: filterData['searchQuery'] as String?,
      sortBy: filterData['sortBy'] as String?,
      sortAscending: filterData['sortAscending'] as bool? ?? true,
    );
  }
}