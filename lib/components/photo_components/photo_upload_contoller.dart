import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'photo_models.dart';
import 'photo_presign.dart';

class PhotoUploadController extends ChangeNotifier {
  PhotoUploadController({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// 로컬 선택된 파일
  final List<XFile> localPhotos = [];

  /// ✅ key: XFile.path, value: 업로드 결과
  final Map<String, UploadedPhoto> _uploadedByPath = {};

  bool _isUploading = false;

  bool get isUploading => _isUploading;

  /// ✅ UI에서 쓰는 업로드 결과(현재 localPhotos 순서대로)
  List<UploadedPhoto> get uploadedPhotos => localPhotos
      .map((x) => _uploadedByPath[x.path])
      .whereType<UploadedPhoto>()
      .toList();

  /// "현재 로컬 사진 수 == 업로드 완료 수"여야 업로드 완료
  bool get allPhotosUploaded => uploadedPhotos.length == localPhotos.length;

  Future<void> pickImages({int imageQuality = 85}) async {
    final images = await _picker.pickMultiImage(imageQuality: imageQuality);
    if (images.isEmpty) return;

    // ✅ 같은 path 중복 선택 방지
    final existing = localPhotos.map((e) => e.path).toSet();
    for (final img in images) {
      if (!existing.contains(img.path)) {
        localPhotos.add(img);
      }
    }
    notifyListeners();
  }

  void removeLocalPhoto(int index) {
    if (_isUploading) return;

    final removed = localPhotos.removeAt(index);
    _uploadedByPath.remove(removed.path); // ✅ 캐시도 함께 제거
    notifyListeners();
  }

  /// ✅ 저장할 때만 호출
  /// - 이미 업로드된(path 동일) 파일은 presign/PUT을 건너뜀 → 중복 PUT 방지
  Future<void> uploadMissingPhotosForSave() async {
    if (_isUploading) return;

    _isUploading = true;
    notifyListeners();

    try {
      for (final xfile in localPhotos) {
        // ✅ 핵심: 같은 로컬 파일이면 재업로드 금지
        if (_uploadedByPath.containsKey(xfile.path)) continue;

        final fileName = xfile.name;
        final lower = fileName.toLowerCase();
        final contentType = lower.endsWith('.png')
            ? 'image/png'
            : (lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg');

        final bytes = await xfile.readAsBytes();

        // 1) presign
        final presign = await UploadApi.presign(
          fileName: fileName,
          contentType: contentType,
        );

        // 2) PUT to S3
        await UploadApi.putToS3Bytes(
          uploadUrl: presign.uploadUrl,
          bytes: bytes,
          contentType: contentType,
        );

        final publicUrl =
            presign.publicUrl ?? UploadApi.buildPublicUrl(presign.fileKey);

        _uploadedByPath[xfile.path] = UploadedPhoto(
          fileKey: presign.fileKey,
          publicUrl: publicUrl,
        );

        notifyListeners();
      }
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  List<String> get uploadedKeys =>
      uploadedPhotos.map((p) => p.fileKey).toList();

  void clear() {
    if (_isUploading) return;
    localPhotos.clear();
    _uploadedByPath.clear();
    notifyListeners();
  }
}
