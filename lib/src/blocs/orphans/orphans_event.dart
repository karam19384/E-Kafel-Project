part of 'orphans_bloc.dart';

abstract class OrphansEvent extends Equatable {
  const OrphansEvent();

  @override
  List<Object?> get props => [];
}

// جلب قائمة الأيتام
class LoadOrphans extends OrphansEvent {}

// إضافة يتيم جديد
class AddOrphan extends OrphansEvent {
  final Orphan orphan; // النموذج كامل لليتيم
  final File? idCardFile;
  final File? deathCertificateFile;
  final File? orphanPhotoFile;
  // تم إضافة final هنا لتكون الخصائص قابلة للوصول
  final Uint8List? idCardBytes;
  final Uint8List? deathCertificateBytes;
  final Uint8List? orphanPhotoBytes;

  const AddOrphan({
    required this.orphan,
    this.idCardFile,
    this.deathCertificateFile,
    this.orphanPhotoFile,
    this.idCardBytes,
    this.deathCertificateBytes,
    this.orphanPhotoBytes,
  });

  @override
  List<Object?> get props => [
    orphan,
    idCardFile,
    deathCertificateFile,
    orphanPhotoFile,
    // تم إضافة متغيرات bytes هنا
    idCardBytes,
    deathCertificateBytes,
    orphanPhotoBytes,
  ];
}

// تحديث بيانات يتيم
class UpdateOrphan extends OrphansEvent {
  final String orphanId;
  final Map<String, dynamic> updatedData;

  const UpdateOrphan(this.orphanId, this.updatedData);

  @override
  List<Object?> get props => [orphanId, updatedData];
}

/*
// حذف يتيم
class DeleteOrphan extends OrphansEvent {
  final String orphanId;

  const DeleteOrphan(this.orphanId);

  @override
  List<Object?> get props => [orphanId];
}
*/
class ArchiveOrphan extends OrphansEvent {
  final String orphanId;

  const ArchiveOrphan(this.orphanId);

  @override
  List<Object> get props => [orphanId];
}