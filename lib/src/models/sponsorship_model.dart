import 'package:cloud_firestore/cloud_firestore.dart';

class SponsorshipProject {
  final String id;
  final String institutionId;
  final String name;
  final String type; // مثال: "مشروع كفالة" , "مشروع تعليمي"...
  final String description;
  final double budget; // الميزانية المعتمدة
  final double spent; // مصروفات
  final String status; // active | pending | completed | archived
  final DateTime createdAt;
  final DateTime updatedAt;

  SponsorshipProject({
    required this.id,
    required this.institutionId,
    required this.name,
    required this.type,
    required this.description,
    required this.budget,
    required this.spent,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  double get available => (budget - spent).clamp(0, double.infinity);

  factory SponsorshipProject.fromMap(Map<String, dynamic> map, String id) {
    return SponsorshipProject(
      id: id,
      institutionId: map['institutionId'] ?? '',
      name: map['fullName'] ?? '',
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      budget: (map['budget'] ?? 0).toDouble(),
      spent: (map['spent'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institutionId': institutionId,
      'fullName': name,
      'type': type,
      'description': description,
      'budget': budget,
      'spent': spent,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SponsorshipProject copyWith({
    String? id,
    String? institutionId,
    String? name,
    String? type,
    String? description,
    double? budget,
    double? spent,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SponsorshipProject(
      id: id ?? this.id,
      institutionId: institutionId ?? this.institutionId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SponsorshipEventItem {
  final String id;
  final String projectId;
  final String title;
  final String details;
  final String performedByUid;
  final DateTime timestamp;
  final double? amount; // اختياري: للصرف/الإضافة المالية
  final String type; // e.g. "expense" | "income" | "status_change" | "note"

  SponsorshipEventItem({
    required this.id,
    required this.projectId,
    required this.title,
    required this.details,
    required this.performedByUid,
    required this.timestamp,
    this.amount,
    required this.type,
  });

  factory SponsorshipEventItem.fromMap(Map<String, dynamic> map, String id) {
    return SponsorshipEventItem(
      id: id,
      projectId: map['projectId'] ?? '',
      title: map['title'] ?? '',
      details: map['details'] ?? '',
      performedByUid: map['performedByUid'] ?? '',
      timestamp: (map['timestamp'] is Timestamp)
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      amount: (map['amount'] == null) ? null : (map['amount'] as num).toDouble(),
      type: map['type'] ?? 'note',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'title': title,
      'details': details,
      'performedByUid': performedByUid,
      'timestamp': Timestamp.fromDate(timestamp),
      'amount': amount,
      'type': type,
    };
  }
}
