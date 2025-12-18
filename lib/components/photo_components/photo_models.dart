import 'package:juvis_faciliry/components/maintenance_components/maintenance_category.dart';

class UploadedPhoto {
  final String fileKey;
  final String publicUrl;

  UploadedPhoto({required this.fileKey, required this.publicUrl});
}

class PresignReq {
  final String fileName;
  final String contentType;

  PresignReq({required this.fileName, required this.contentType});

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'contentType': contentType,
  };
}

class PresignRes {
  final String uploadUrl;
  final String fileKey;
  final String? publicUrl;

  PresignRes({required this.uploadUrl, required this.fileKey, this.publicUrl});

  factory PresignRes.fromJson(Map<String, dynamic> json) {
    final uploadUrl = json['uploadUrl'];
    final fileKey = json['fileKey'];
    final publicUrl = json['publicUrl'];

    if (uploadUrl == null || fileKey == null) {
      throw Exception(
        'presign 응답 필드 누락: uploadUrl=$uploadUrl, fileKey=$fileKey / json=$json',
      );
    }

    return PresignRes(
      uploadUrl: uploadUrl as String,
      fileKey: fileKey as String,
      publicUrl: publicUrl as String?, // ✅ 없으면 null
    );
  }
}

class MaintenancePhotoDto {
  final String fileKey;
  final String url;

  MaintenancePhotoDto({required this.fileKey, required this.url});

  Map<String, dynamic> toJson() => {'fileKey': fileKey, 'url': url};
}

class MaintenanceCreateDto {
  final String title;
  final String description;
  final MaintenanceCategory category;
  final bool submit; // 저장: false, 제출용 생성: true (우리는 저장은 false만 쓸 것)
  final List<MaintenancePhotoDto> photos;

  MaintenanceCreateDto({
    required this.title,
    required this.description,
    required this.category,
    required this.submit,
    required this.photos,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': category.toJson,
    'submit': submit,
    'photos': photos.map((p) => p.toJson()).toList(),
  };
}
