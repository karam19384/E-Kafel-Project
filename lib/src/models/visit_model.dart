// ملف: lib/models/visit.dart
class Visit {
  final String? id;
  final String orphanName;
  final String date;
  final String area;
  final String? status;

  Visit({
    this.id,
    required this.orphanName,
    required this.date,
    required this.area,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'orphanName': orphanName,
      'date': date,
      'area': area,
      'status': status,
    };
  }

  factory Visit.fromMap(Map<String, dynamic> map, String id) {
    return Visit(
      id: id,
      orphanName: map['orphanName'] ?? '',
      date: map['date'] ?? '',
      area: map['area'] ?? '',
      status: map['status'] ?? '',
    );
  }
}
