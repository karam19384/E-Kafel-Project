part of 'orphans_bloc.dart';

abstract class OrphansEvent extends Equatable {
  const OrphansEvent();

  @override
  List<Object?> get props => [];
}

// جلب قائمة الأيتام
class LoadOrphans extends OrphansEvent {
  final String institutionId; 
  const LoadOrphans({required this.institutionId}); 
  @override
  List<Object?> get props => [institutionId]; 
}

// إضافة يتيم جديد
class AddOrphan extends OrphansEvent {
  final Orphan orphan; // النموذج كامل لليتيم
  final File? idCardFile;
  final File? deathCertificateFile;
  final File? orphanPhotoFile;
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
    idCardBytes,
    deathCertificateBytes,
    orphanPhotoBytes,
  ];
}

// تحديث بيانات يتيم
class UpdateOrphan extends OrphansEvent {
  final String orphanId;
    final String institutionId;

  final Map<String, dynamic> updatedData;

  const UpdateOrphan(this.orphanId, this.updatedData , this.institutionId); 

  @override
  List<Object?> get props => [orphanId, updatedData];
}

// أرشفة يتيم
class ArchiveOrphan extends OrphansEvent {
  final String orphanId;
  final String institutionId;

  const ArchiveOrphan(this.orphanId , this.institutionId); 

  @override
  List<Object> get props => [orphanId];
}