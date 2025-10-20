import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reports_model.dart';
import '../models/filter_model.dart';
import '../models/orphan_model.dart';
import '../models/sponsorship_model.dart';
import '../models/tasks_model.dart';
import '../models/user_model.dart';
import '../models/visit_model.dart';

class ReportsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createReport(ReportModel report) async {
    try {
      final docRef = _firestore.collection('reports').doc();
      final newReport = report.copyWith(reportId: docRef.id);
      await docRef.set(newReport.toMap());
      return docRef.id;
    } catch (e) {
      print("🔥 Error creating report: $e");
      rethrow;
    }
  }

  Future<List<ReportModel>> getReportsByKafalaHead(String kafalaHeadId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('kafalaHeadId', isEqualTo: kafalaHeadId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print("🔥 Error fetching reports: $e");
      rethrow;
    }
  }

  Future<ReportModel?> getReportById(String reportId) async {
    try {
      final doc = await _firestore.collection('reports').doc(reportId).get();
      if (doc.exists) {
        return ReportModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("🔥 Error fetching report by ID: $e");
      rethrow;
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).delete();
    } catch (e) {
      print("🔥 Error deleting report: $e");
      rethrow;
    }
  }

  Future<List<ReportModel>> getReportsByInstitution(String institutionId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('institutionId', isEqualTo: institutionId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print("🔥 Error fetching institution reports: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFilteredOrphans(ReportFilter filter) async {
    try {
      Query query = _firestore.collection('orphans');

      if (filter.governorate != null && filter.governorate!.isNotEmpty) {
        query = query.where('governorate', isEqualTo: filter.governorate);
      }
      if (filter.city != null && filter.city!.isNotEmpty) {
        query = query.where('city', isEqualTo: filter.city);
      }
      if (filter.neighborhood != null && filter.neighborhood!.isNotEmpty) {
        query = query.where('neighborhood', isEqualTo: filter.neighborhood);
      }

      if (filter.orphanStatus != null && filter.orphanStatus!.isNotEmpty) {
        query = query.where('sponsorshipStatus', isEqualTo: filter.orphanStatus);
      }
      if (filter.orphanType != null && filter.orphanType!.isNotEmpty) {
        query = query.where('orphanType', isEqualTo: filter.orphanType);
      }
      if (filter.gender != null && filter.gender!.isNotEmpty) {
        query = query.where('gender', isEqualTo: filter.gender);
      }
      if (filter.educationStatus != null && filter.educationStatus!.isNotEmpty) {
        query = query.where('educationStatus', isEqualTo: filter.educationStatus);
      }
      if (filter.educationLevel != null && filter.educationLevel!.isNotEmpty) {
        query = query.where('educationLevel', isEqualTo: filter.educationLevel);
      }
      if (filter.healthCondition != null && filter.healthCondition!.isNotEmpty) {
        query = query.where('healthCondition', isEqualTo: filter.healthCondition);
      }
      if (filter.housingCondition != null && filter.housingCondition!.isNotEmpty) {
        query = query.where('housingCondition', isEqualTo: filter.housingCondition);
      }
      if (filter.housingOwnership != null && filter.housingOwnership!.isNotEmpty) {
        query = query.where('housingOwnership', isEqualTo: filter.housingOwnership);
      }

      if (filter.minOrphanNo != null) {
        query = query.where('orphanNo', isGreaterThanOrEqualTo: filter.minOrphanNo);
      }
      if (filter.maxOrphanNo != null) {
        query = query.where('orphanNo', isLessThanOrEqualTo: filter.maxOrphanNo);
      }
      if (filter.minOrphanIdNumber != null) {
        query = query.where('orphanIdNumber', isGreaterThanOrEqualTo: filter.minOrphanIdNumber);
      }
      if (filter.maxOrphanIdNumber != null) {
        query = query.where('orphanIdNumber', isLessThanOrEqualTo: filter.maxOrphanIdNumber);
      }
      if (filter.minFamilyMembers != null) {
        query = query.where('totalFamilyMembers', isGreaterThanOrEqualTo: filter.minFamilyMembers);
      }
      if (filter.maxFamilyMembers != null) {
        query = query.where('totalFamilyMembers', isLessThanOrEqualTo: filter.maxFamilyMembers);
      }

      if (filter.startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!));
      }
      if (filter.endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!));
      }

      final snapshot = await query.get();
      List<Map<String, dynamic>> results = [];

      for (var doc in snapshot.docs) {
        final orphan = Orphan.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
        final orphanMap = orphan.toMap();
        
        final age = _calculateAge(orphan.dateOfBirth);
        orphanMap['age'] = age;
        
        results.add(orphanMap);
      }

      if (filter.minAge != null || filter.maxAge != null) {
        results = results.where((orphan) {
          final age = orphan['age'] as int? ?? 0;
          if (filter.minAge != null && age < filter.minAge!) return false;
          if (filter.maxAge != null && age > filter.maxAge!) return false;
          return true;
        }).toList();
      }

      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        results = results.where((orphan) {
          return orphan['fullName']?.toString().toLowerCase().contains(query) == true ||
                 orphan['orphanName']?.toString().toLowerCase().contains(query) == true ||
                 orphan['familyName']?.toString().toLowerCase().contains(query) == true ||
                 orphan['orphanIdNumber']?.toString().contains(filter.searchQuery!) == true ||
                 orphan['city']?.toString().toLowerCase().contains(query) == true ||
                 orphan['governorate']?.toString().toLowerCase().contains(query) == true ||
                 orphan['neighborhood']?.toString().toLowerCase().contains(query) == true ||
                 orphan['schoolName']?.toString().toLowerCase().contains(query) == true;
        }).toList();
      }

      if (filter.sortBy != null) {
        results.sort((a, b) {
          var aValue = a[filter.sortBy!] ?? '';
          var bValue = b[filter.sortBy!] ?? '';
          
          if (aValue is String && bValue is String) {
            return filter.sortAscending! ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
          }
          if (aValue is DateTime && bValue is DateTime) {
            return filter.sortAscending! ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
          }
          if (aValue is num && bValue is num) {
            return filter.sortAscending! ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
          }
          return 0;
        });
      }

      return results;
    } catch (e) {
      print("🔥 Error fetching filtered orphans: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFilteredSponsors(ReportFilter filter) async {
    try {
      Query query = _firestore.collection('sponsorship_projects');

      if (filter.sponsorType != null && filter.sponsorType!.isNotEmpty) {
        query = query.where('type', isEqualTo: filter.sponsorType);
      }
      if (filter.financialStatus != null && filter.financialStatus!.isNotEmpty) {
        query = query.where('status', isEqualTo: filter.financialStatus);
      }

      if (filter.minSponsorshipAmount != null) {
        query = query.where('budget', isGreaterThanOrEqualTo: filter.minSponsorshipAmount);
      }
      if (filter.maxSponsorshipAmount != null) {
        query = query.where('budget', isLessThanOrEqualTo: filter.maxSponsorshipAmount);
      }
      if (filter.minBudget != null) {
        query = query.where('budget', isGreaterThanOrEqualTo: filter.minBudget);
      }
      if (filter.maxBudget != null) {
        query = query.where('budget', isLessThanOrEqualTo: filter.maxBudget);
      }
      if (filter.minSpent != null) {
        query = query.where('spent', isGreaterThanOrEqualTo: filter.minSpent);
      }
      if (filter.maxSpent != null) {
        query = query.where('spent', isLessThanOrEqualTo: filter.maxSpent);
      }

      if (filter.startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!));
      }
      if (filter.endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!));
      }

      final snapshot = await query.get();
      List<Map<String, dynamic>> results = [];

      for (var doc in snapshot.docs) {
        final project = SponsorshipProject.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        results.add(project.toMap());
      }

      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        results = results.where((project) {
          return project['name']?.toString().toLowerCase().contains(filter.searchQuery!.toLowerCase()) == true ||
                 project['description']?.toString().toLowerCase().contains(filter.searchQuery!.toLowerCase()) == true ||
                 project['type']?.toString().toLowerCase().contains(filter.searchQuery!.toLowerCase()) == true;
        }).toList();
      }

      if (filter.sortBy != null) {
        results.sort((a, b) {
          var aValue = a[filter.sortBy!] ?? '';
          var bValue = b[filter.sortBy!] ?? '';
          
          if (aValue is String && bValue is String) {
            return filter.sortAscending! ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
          }
          if (aValue is num && bValue is num) {
            return filter.sortAscending! ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
          }
          return 0;
        });
      }

      return results;
    } catch (e) {
      print("🔥 Error fetching filtered sponsors: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFilteredSupervisors(ReportFilter filter) async {
    try {
      Query query = _firestore.collection('users');

      if (filter.userRole != null && filter.userRole!.isNotEmpty) {
        query = query.where('userRole', isEqualTo: filter.userRole);
      }
      if (filter.areaResponsibleFor != null && filter.areaResponsibleFor!.isNotEmpty) {
        query = query.where('areaResponsibleFor', isEqualTo: filter.areaResponsibleFor);
      }
      if (filter.functionalLodgment != null && filter.functionalLodgment!.isNotEmpty) {
        query = query.where('functionalLodgment', isEqualTo: filter.functionalLodgment);
      }

      if (filter.startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!));
      }
      if (filter.endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!));
      }

      final snapshot = await query.get();
      List<Map<String, dynamic>> results = [];

      for (var doc in snapshot.docs) {
        final user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        results.add(user.toMap());
      }

      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        results = results.where((user) {
          return user['fullName']?.toString().toLowerCase().contains(filter.searchQuery!.toLowerCase()) == true ||
                 user['email']?.toString().toLowerCase().contains(filter.searchQuery!.toLowerCase()) == true ||
                 user['mobileNumber']?.toString().contains(filter.searchQuery!) == true ||
                 user['institutionName']?.toString().toLowerCase().contains(filter.searchQuery!.toLowerCase()) == true;
        }).toList();
      }

      if (filter.sortBy != null) {
        results.sort((a, b) {
          var aValue = a[filter.sortBy!] ?? '';
          var bValue = b[filter.sortBy!] ?? '';
          
          if (aValue is String && bValue is String) {
            return filter.sortAscending! ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
          }
          return 0;
        });
      }

      return results;
    } catch (e) {
      print("🔥 Error fetching filtered supervisors: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFilteredTasks(ReportFilter filter) async {
    try {
      Query query = _firestore.collection('tasks');

      if (filter.taskPriority != null && filter.taskPriority!.isNotEmpty) {
        query = query.where('priority', isEqualTo: filter.taskPriority);
      }
      if (filter.taskStatus != null && filter.taskStatus!.isNotEmpty) {
        query = query.where('status', isEqualTo: filter.taskStatus);
      }
      if (filter.assignedTo != null && filter.assignedTo!.isNotEmpty) {
        query = query.where('assignedTo', isEqualTo: filter.assignedTo);
      }
      if (filter.taskType != null && filter.taskType!.isNotEmpty) {
        query = query.where('taskType', isEqualTo: filter.taskType);
      }
      if (filter.taskLocation != null && filter.taskLocation!.isNotEmpty) {
        query = query.where('taskLocation', isEqualTo: filter.taskLocation);
      }

      if (filter.startDate != null) {
        query = query.where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!));
      }
      if (filter.endDate != null) {
        query = query.where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!));
      }

      final snapshot = await query.get();
      List<Map<String, dynamic>> results = [];

      for (var doc in snapshot.docs) {
        final task = TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        results.add(task.toMap());
      }

      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        results = results.where((task) {
          return task['title']?.toString().toLowerCase().contains(filter.searchQuery!.toLowerCase()) == true ||
                 task['description']?.toString().toLowerCase().contains(filter.searchQuery!.toLowerCase()) == true ||
                 task['taskType']?.toString().toLowerCase().contains(filter.searchQuery!.toLowerCase()) == true ||
                 task['taskLocation']?.toString().toLowerCase().contains(filter.searchQuery!.toLowerCase()) == true;
        }).toList();
      }

      if (filter.sortBy != null) {
        results.sort((a, b) {
          var aValue = a[filter.sortBy!] ?? '';
          var bValue = b[filter.sortBy!] ?? '';
          
          if (aValue is String && bValue is String) {
            return filter.sortAscending! ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
          }
          if (aValue is DateTime && bValue is DateTime) {
            return filter.sortAscending! ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
          }
          return 0;
        });
      }

      return results;
    } catch (e) {
      print("🔥 Error fetching filtered tasks: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFilteredVisits(ReportFilter filter) async {
    try {
      Query query = _firestore.collection('visits');

      if (filter.visitArea != null && filter.visitArea!.isNotEmpty) {
        query = query.where('area', isEqualTo: filter.visitArea);
      }
      if (filter.visitStatus != null && filter.visitStatus!.isNotEmpty) {
        query = query.where('status', isEqualTo: filter.visitStatus);
      }

      if (filter.startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: filter.startDate!.toIso8601String());
      }
      if (filter.endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: filter.endDate!.toIso8601String());
      }

      final snapshot = await query.get();
      List<Map<String, dynamic>> results = [];

      for (var doc in snapshot.docs) {
        final visit = Visit.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        results.add(visit.toMap());
      }

      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        results = results.where((visit) {
          return visit['orphanName']?.toString().toLowerCase().contains(filter.searchQuery!.toLowerCase()) == true ||
                 visit['area']?.toString().toLowerCase().contains(filter.searchQuery!.toLowerCase()) == true;
        }).toList();
      }

      if (filter.sortBy != null) {
        results.sort((a, b) {
          var aValue = a[filter.sortBy!] ?? '';
          var bValue = b[filter.sortBy!] ?? '';
          
          if (aValue is String && bValue is String) {
            return filter.sortAscending! ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
          }
          return 0;
        });
      }

      return results;
    } catch (e) {
      print("🔥 Error fetching filtered visits: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFilteredData(ReportFilter filter) async {
    switch (filter.reportType) {
      case 'أيتام':
        return await getFilteredOrphans(filter);
      case 'كفالات':
        return await getFilteredSponsors(filter);
      case 'مشرفين':
        return await getFilteredSupervisors(filter);
      case 'مهام':
        return await getFilteredTasks(filter);
      case 'زيارات':
        return await getFilteredVisits(filter);
      default:
        return [];
    }
  }

  Future<Map<String, dynamic>> getOrphanStatistics(String institutionId) async {
    try {
      final orphansSnapshot = await _firestore
          .collection('orphans')
          .where('institutionId', isEqualTo: institutionId)
          .get();

      final sponsorsSnapshot = await _firestore
          .collection('sponsors')
          .where('institutionId', isEqualTo: institutionId)
          .get();

      final totalOrphans = orphansSnapshot.docs.length;
      final sponsoredCount = sponsorsSnapshot.docs.length;

      return {
        'totalOrphans': totalOrphans,
        'sponsoredCount': sponsoredCount,
        'waitingCount': totalOrphans - sponsoredCount,
      };
    } catch (e) {
      print("🔥 Error fetching statistics: $e");
      rethrow;
    }
  }

  Future<Map<String, List<String>>> getFilterOptions() async {
    try {
      final orphansSnapshot = await _firestore.collection('orphans').get();
      final projectsSnapshot = await _firestore.collection('sponsorship_projects').get();
      final usersSnapshot = await _firestore.collection('users').get();
      final tasksSnapshot = await _firestore.collection('tasks').get();
      final visitsSnapshot = await _firestore.collection('visits').get();

      final governorates = orphansSnapshot.docs.map((doc) {
        final data = doc.data();
        return data['governorate'] as String?;
      }).where((gov) => gov != null && gov.isNotEmpty).toSet().toList();

      final cities = orphansSnapshot.docs.map((doc) {
        final data = doc.data();
        return data['city'] as String?;
      }).where((city) => city != null && city.isNotEmpty).toSet().toList();

      final neighborhoods = orphansSnapshot.docs.map((doc) {
        final data = doc.data();
        return data['neighborhood'] as String?;
      }).where((neighborhood) => neighborhood != null && neighborhood.isNotEmpty).toSet().toList();

      final orphanStatuses = orphansSnapshot.docs.map((doc) {
        final data = doc.data();
        return data['sponsorshipStatus'] as String?;
      }).where((status) => status != null && status.isNotEmpty).toSet().toList();

      final educationLevels = orphansSnapshot.docs.map((doc) {
        final data = doc.data();
        return data['educationLevel'] as String?;
      }).where((level) => level != null && level.isNotEmpty).toSet().toList();

      final sponsorTypes = projectsSnapshot.docs.map((doc) {
        final project = SponsorshipProject.fromMap(doc.data(), doc.id);
        return project.type;
      }).where((type) => type.isNotEmpty).toSet().toList();

      final userRoles = usersSnapshot.docs.map((doc) {
        final user = UserModel.fromMap(doc.data());
        return user.userRole;
      }).where((role) => role.isNotEmpty).toSet().toList();

      final areas = usersSnapshot.docs.map((doc) {
        final user = UserModel.fromMap(doc.data());
        return user.areaResponsibleFor;
      }).where((area) => area != null && area.isNotEmpty).toSet().toList();

      final functionalLodgments = usersSnapshot.docs.map((doc) {
        final user = UserModel.fromMap(doc.data());
        return user.functionalLodgment;
      }).where((lodgment) => lodgment != null && lodgment.isNotEmpty).toSet().toList();

      final taskPriorities = tasksSnapshot.docs.map((doc) {
        final task = TaskModel.fromMap(doc.data(), doc.id);
        return task.priority;
      }).where((priority) => priority.isNotEmpty).toSet().toList();

      final taskTypes = tasksSnapshot.docs.map((doc) {
        final task = TaskModel.fromMap(doc.data(), doc.id);
        return task.taskType;
      }).where((type) => type != null && type.isNotEmpty).toSet().toList();

      final taskLocations = tasksSnapshot.docs.map((doc) {
        final task = TaskModel.fromMap(doc.data(), doc.id);
        return task.taskLocation;
      }).where((location) => location != null && location.isNotEmpty).toSet().toList();

      final visitAreas = visitsSnapshot.docs.map((doc) {
        final visit = Visit.fromMap(doc.data(), doc.id);
        return visit.area;
      }).where((area) => area.isNotEmpty).toSet().toList();

      final defaultGovernorates = ['غزة', 'الوسطى', 'الشمال', 'خان يونس', 'رفح'];
      final defaultCities = ['غزة', 'جباليا', 'بيت لاهيا', 'بيت حانون', 'الشاطئ'];
      final defaultNeighborhoods = ['الرمال', 'الشجاعية', 'التفاح', 'الصبرة', 'الزيتون'];

      return {
        'governorates': governorates.isNotEmpty ? governorates.cast<String>() : defaultGovernorates,
        'cities': cities.isNotEmpty ? cities.cast<String>() : defaultCities,
        'neighborhoods': neighborhoods.isNotEmpty ? neighborhoods.cast<String>() : defaultNeighborhoods,
        'orphanStatuses': orphanStatuses.isNotEmpty ? orphanStatuses.cast<String>() : ['مكفول', 'في الانتظار', 'متوقف'],
        'orphanTypes': ['يتيم الأب', 'يتيم الأم', 'يتيم كلا الوالدين'],
        'genders': ['ذكر', 'أنثى'],
        'educationStatuses': ['ملتحق', 'غير ملتحق', 'متسرب'],
        'educationLevels': educationLevels.isNotEmpty ? educationLevels.cast<String>() : ['ابتدائي', 'متوسط', 'ثانوي', 'جامعي'],
        'healthConditions': ['جيد', 'متوسط', 'سيء', 'يحتاج رعاية'],
        'housingConditions': ['جيد', 'متوسط', 'سيء', 'غير لائق'],
        'housingOwnerships': ['ملك', 'إيجار', 'عارية', 'آخر'],
        'sponsorTypes': sponsorTypes.isNotEmpty ? sponsorTypes : ['مشروع كفالة', 'مشروع تعليمي', 'مشروع صحي'],
        'financialStatuses': ['نشط', 'متوقف', 'منتهي', 'معلق'],
        'userRoles': userRoles.isNotEmpty ? userRoles : ['supervisor', 'kafalaHead', 'admin'],
        'areas': areas.isNotEmpty ? areas.cast<String>() : ['المنطقة الشمالية', 'المنطقة الجنوبية', 'المنطقة الشرقية', 'المنطقة الغربية'],
        'functionalLodgments': functionalLodgments.isNotEmpty ? functionalLodgments.cast<String>() : ['داخلي', 'خارجي'],
        'taskPriorities': taskPriorities.isNotEmpty ? taskPriorities : ['عالي', 'متوسط', 'منخفض'],
        'taskStatuses': ['معلقة', 'قيد التنفيذ', 'مكتملة', 'ملغاة'],
        'taskTypes': taskTypes.isNotEmpty ? taskTypes.cast<String>() : ['زيارة ميدانية', 'متابعة كفالة', 'تقرير', 'اجتماع'],
        'taskLocations': taskLocations.isNotEmpty ? taskLocations.cast<String>() : ['مقر الجمعية', 'الميدان', 'منزل اليتيم', 'مكتب'],
        'visitStatuses': ['مكتملة', 'معلقة', 'ملغاة'],
        'visitAreas': visitAreas.isNotEmpty ? visitAreas : ['غزة', 'جباليا', 'بيت لاهيا', 'بيت حانون'],
      };
    } catch (e) {
      print("🔥 Error fetching filter options: $e");
      return {
        'governorates': ['غزة', 'الوسطى', 'الشمال', 'خان يونس', 'رفح'],
        'cities': ['غزة', 'جباليا', 'بيت لاهيا', 'بيت حانون', 'الشاطئ'],
        'neighborhoods': ['الرمال', 'الشجاعية', 'التفاح', 'الصبرة', 'الزيتون'],
        'orphanStatuses': ['مكفول', 'في الانتظار', 'متوقف'],
        'orphanTypes': ['يتيم الأب', 'يتيم الأم', 'يتيم كلا الوالدين'],
        'genders': ['ذكر', 'أنثى'],
        'educationStatuses': ['ملتحق', 'غير ملتحق', 'متسرب'],
        'educationLevels': ['ابتدائي', 'متوسط', 'ثانوي', 'جامعي'],
        'healthConditions': ['جيد', 'متوسط', 'سيء', 'يحتاج رعاية'],
        'housingConditions': ['جيد', 'متوسط', 'سيء', 'غير لائق'],
        'housingOwnerships': ['ملك', 'إيجار', 'عارية', 'آخر'],
        'sponsorTypes': ['مشروع كفالة', 'مشروع تعليمي', 'مشروع صحي'],
        'financialStatuses': ['نشط', 'متوقف', 'منتهي', 'معلق'],
        'userRoles': ['supervisor', 'kafalaHead', 'admin'],
        'areas': ['المنطقة الشمالية', 'المنطقة الجنوبية', 'المنطقة الشرقية', 'المنطقة الغربية'],
        'functionalLodgments': ['داخلي', 'خارجي'],
        'taskPriorities': ['عالي', 'متوسط', 'منخفض'],
        'taskStatuses': ['معلقة', 'قيد التنفيذ', 'مكتملة', 'ملغاة'],
        'taskTypes': ['زيارة ميدانية', 'متابعة كفالة', 'تقرير', 'اجتماع'],
        'taskLocations': ['مقر الجمعية', 'الميدان', 'منزل اليتيم', 'مكتب'],
        'visitStatuses': ['مكتملة', 'معلقة', 'ملغاة'],
        'visitAreas': ['غزة', 'جباليا', 'بيت لاهيا', 'بيت حانون'],
      };
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}