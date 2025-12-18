import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'photo_models.dart';
import 'photo_presign.dart';

class PhotoUploadController extends ChangeNotifier {
  PhotoUploadController({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  // 로컬 선택된 파일
  final List<XFile> localPhotos = [];

  // 업로드 완료(서버 attach 가능한 정보)
  final List<UploadedPhoto> uploadedPhotos = [];

  // 업로드 중 상태 (추가)
  bool _isUploading = false;

  bool get isUploading => _isUploading;

  // "현재 로컬 사진 수 == 업로드 완료 수"여야 업로드 완료
  bool get allPhotosUploaded => localPhotos.length == uploadedPhotos.length;

  Future<void> pickImages({int imageQuality = 85}) async {
    final images = await _picker.pickMultiImage(imageQuality: imageQuality);
    if (images.isEmpty) return;

    localPhotos.addAll(images);
    notifyListeners();
  }

  void removeLocalPhoto(int index) {
    // 업로드 중에는 변경 막는게 안전 (선택)
    if (_isUploading) return;

    if (index < uploadedPhotos.length) {
      uploadedPhotos.removeAt(index);
    }
    localPhotos.removeAt(index);
    notifyListeners();
  }

  Future<void> uploadAllPhotosIfNeeded() async {
    debugPrint(
      'UPLOAD ENTER local=${localPhotos.length}, uploaded=${uploadedPhotos.length}, isUploading=$_isUploading',
    );
    if (allPhotosUploaded) return;
    if (_isUploading) return;

    _isUploading = true;
    notifyListeners();

    try {
      for (int i = uploadedPhotos.length; i < localPhotos.length; i++) {
        debugPrint('UPLOAD LOOP i=$i / local=${localPhotos.length}');

        final xfile = localPhotos[i];
        final fileName = xfile.name;

        final lower = fileName.toLowerCase();
        final contentType = lower.endsWith('.png')
            ? 'image/png'
            : (lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg');

        final bytes = await xfile.readAsBytes();
        debugPrint(
          'UPLOAD bytes=${bytes.length}, fileName=$fileName, type=$contentType',
        );

        // 1) presign
        final presign = await UploadApi.presign(
          fileName: fileName,
          contentType: contentType,
        );

        // 2) PUT upload to S3
        await UploadApi.putToS3Bytes(
          uploadUrl: presign.uploadUrl,
          bytes: bytes,
          contentType: contentType,
        );

        final publicUrl =
            presign.publicUrl ?? UploadApi.buildPublicUrl(presign.fileKey);

        uploadedPhotos.add(
          UploadedPhoto(fileKey: presign.fileKey, publicUrl: publicUrl),
        );

        notifyListeners();
      }
    } catch (e) {
      debugPrint('UPLOAD ERROR: $e');
      rethrow;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  List<String> get uploadedKeys =>
      uploadedPhotos.map((p) => p.fileKey).toList();

  void clear() {
    if (_isUploading) return; // 선택
    localPhotos.clear();
    uploadedPhotos.clear();
    notifyListeners();
  }
}
