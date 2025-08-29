// ملف: lib/models/visit.dart
class Visit {
  final String? id;
  final String orphanName;
  final String date;
  final String area;

  Visit({
    this.id,
    required this.orphanName,
    required this.date,
    required this.area,
  });

  Map<String, dynamic> toMap() {
    return {
      'orphanName': orphanName,
      'date': date,
      'area': area,
    };
  }

  factory Visit.fromMap(Map<String, dynamic> map, String id) {
    return Visit(
      id: id,
      orphanName: map['orphanName'] ?? '',
      date: map['date'] ?? '',
      area: map['area'] ?? '',
    );
  }
}