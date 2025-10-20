import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final DateTime dueDate;
  final DateTime createdAt;
  final String institutionId;
  final String kafalaHeadId;
  final String? assignedTo; // مشرف المهمة
  final String? taskLocation; // مكان المهمة
  final String? taskType; // نوع المهمة

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.createdAt,
    required this.institutionId,
    required this.kafalaHeadId,
    this.assignedTo,
    this.taskLocation,
    this.taskType,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? taskType,
    String? taskLocation,
    String? assignedTo,
    DateTime? dueDate,
    String? institutionId,
    String? createdBy,
    String? priority,
    String? status,
    DateTime? createdAt,
    String? kafalaHeadId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      taskLocation: taskLocation ?? this.taskLocation,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      institutionId: institutionId ?? this.institutionId,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      kafalaHeadId: kafalaHeadId ?? this.kafalaHeadId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'institutionId': institutionId,
      'kafalaHeadId': kafalaHeadId,
      'assignedTo': assignedTo,
      'taskLocation': taskLocation,
      'taskType': taskType,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      priority: map['priority'] ?? 'متوسط',
      status: map['status'] ?? 'pending',
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      institutionId: map['institutionId'] ?? '',
      kafalaHeadId: map['kafalaHeadId'] ?? '',
      assignedTo: map['assignedTo'],
      taskLocation: map['taskLocation'],
      taskType: map['taskType'],
      
    );
  }



}
