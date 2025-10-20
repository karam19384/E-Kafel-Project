// lib/src/blocs/orphans/orphans_event.dart
part of 'orphans_bloc.dart';

abstract class OrphansEvent extends Equatable {
  const OrphansEvent();

  @override
  List<Object?> get props => [];
}

// تحميل الأيتام مع فلاتر اختيارية
class LoadOrphans extends OrphansEvent {
  final String institutionId;
  final Map<String, dynamic>? filters;
  const LoadOrphans({required this.institutionId, this.filters});

  @override
  List<Object?> get props => [institutionId, filters];
}

// عدّاد الأيتام المؤرشفين
class LoadArchivedOrphansCount extends OrphansEvent {
  final String institutionId;
  const LoadArchivedOrphansCount({required this.institutionId});

  @override
  List<Object?> get props => [institutionId];
}

// البحث
class SearchOrphans extends OrphansEvent {
  final String institutionId;
  final String searchTerm;
  final Map<String, dynamic>? filters;
  const SearchOrphans({
    required this.institutionId,
    required this.searchTerm,
    this.filters,
  });

  @override
  List<Object?> get props => [institutionId, searchTerm, filters];
}

// إضافة يتيم (مع ملفات اختيارية)
class AddOrphan extends OrphansEvent {
  final Orphan orphan;

  final File? orphanPhotoFile;
  final File? fatherIdPhotoFile;
  final File? motherIdPhotoFile;
  final File? deceasedPhotoFile;
  final File? deathCertificateFile;
  final File? birthCertificateFile;
  final File? breadwinnerIdPhotoFile;

  const AddOrphan({
    required this.orphan,
    this.orphanPhotoFile,
    this.fatherIdPhotoFile,
    this.motherIdPhotoFile,
    this.deceasedPhotoFile,
    this.deathCertificateFile,
    this.birthCertificateFile,
    this.breadwinnerIdPhotoFile,
  });

  @override
  List<Object?> get props => [
        orphan,
        orphanPhotoFile,
        fatherIdPhotoFile,
        motherIdPhotoFile,
        deceasedPhotoFile,
        deathCertificateFile,
        birthCertificateFile,
        breadwinnerIdPhotoFile,
      ];
}

// تحديث يتيم
class UpdateOrphan extends OrphansEvent {
  final String orphanId;
  final String institutionId;
  final Map<String, dynamic> updatedData;

  const UpdateOrphan({
    required this.orphanId,
    required this.institutionId,
    required this.updatedData,
  });

  @override
  List<Object?> get props => [orphanId, institutionId, updatedData];
}

// أرشفة يتيم
class ArchiveOrphan extends OrphansEvent {
  final String orphanId;
  final String institutionId;

  const ArchiveOrphan({
    required this.orphanId,
    required this.institutionId,
  });

  @override
  List<Object?> get props => [orphanId, institutionId];
}

// إرسال إشعار (يدعم orphanId اختياريًا)
class SendOrphanNotification extends OrphansEvent {
  final String institutionId;
  final String title;
  final String message;
  final String type;
  final String? orphanId; // <-- تمت الإضافة

  const SendOrphanNotification({
    required this.institutionId,
    required this.title,
    required this.message,
    required this.type,
    this.orphanId, // <-- تمت الإضافة
  });

  @override
  List<Object?> get props => [institutionId, title, message, type, orphanId];
}
