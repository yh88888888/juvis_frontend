import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:juvis_faciliry/components/maintenance_components/maintenance_api.dart';
import 'package:juvis_faciliry/components/maintenance_components/maintenance_category.dart';
import 'package:juvis_faciliry/components/photo_components/photo_upload_contoller.dart';

class MaintenanceCreatePage extends StatefulWidget {
  final MaintenanceCategory category;

  /// ✅ Bottom nav는 그대로
  final Widget? bottomNav;

  const MaintenanceCreatePage({
    super.key,
    required this.category,
    this.bottomNav,
  });

  @override
  State<MaintenanceCreatePage> createState() => _MaintenanceCreatePageState();
}

class _MaintenanceCreatePageState extends State<MaintenanceCreatePage> {
  int? _maintenanceId;
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // ✅ 사진 업로드 로직 분리
  late final PhotoUploadController _photoCtrl;

  bool _locked = false;
  bool _saved = false;
  bool _submitted = false;
  bool _loading = false;

  static const Color pageBg = Color(0xFFFFF3F6);

  bool get _allPhotosUploaded => _photoCtrl.allPhotosUploaded;

  @override
  void initState() {
    super.initState();
    _photoCtrl = PhotoUploadController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _photoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_locked || _submitted) return;

    setState(() {
      _saved = false;
      _loading = true; // 업로드 진행 표시
    });

    try {
      await _photoCtrl.pickImages(imageQuality: 85);
      await _photoCtrl.uploadAllPhotosIfNeeded(); // ✅ 선택 직후 업로드
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('사진 업로드 실패: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _removeLocalPhoto(int index) {
    if (_locked || _submitted) return;

    setState(() {
      _saved = false; // 사진 변경은 다시 저장 필요
    });

    _photoCtrl.removeLocalPhoto(index);
  }

  Future<void> _uploadAllPhotosIfNeeded() async {
    await _photoCtrl.uploadAllPhotosIfNeeded();
  }

  void _unlockFieldsForEdit() {
    setState(() {
      _locked = false;
      _saved = false;
    });
  }

  Future<void> _onSavePressed() async {
    if (_submitted) return;

    setState(() => _loading = true);

    try {
      // ✅ 사진 선택되어 있으면 업로드 먼저
      await _photoCtrl.uploadAllPhotosIfNeeded();

      final photos = _photoCtrl.uploadedPhotos
          .map((p) => MaintenancePhotoDto(fileKey: p.fileKey, url: p.publicUrl))
          .toList();

      final dto = MaintenanceCreateDto(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: widget.category,
        submit: false,
        // ✅ 저장은 DRAFT로 생성
        photos: photos, // ✅ 서버 createByBranch에서 MaintenancePhoto 저장됨
      );

      final res = await MaintenanceApi.create(dto);

      if (!mounted) return;

      if (res.statusCode != 200) {
        debugPrint('SAVE fail status=${res.statusCode}, body=${res.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패 (status: ${res.statusCode})')),
        );
        return;
      }

      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final body = (map['body'] ?? map) as Map<String, dynamic>;
      _maintenanceId = (body['id'] as num).toInt();

      setState(() {
        _saved = true;
        _locked = true;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장이 완료되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onSubmitPressed() async {
    if (_submitted) return;

    // ✅ 저장(= id 확보) 안 됐으면 먼저 저장하게
    if (!_saved || _maintenanceId == null) {
      await _onSavePressed();
      if (!mounted) return;
      if (_maintenanceId == null) return; // 저장 실패 시 종료
    }

    setState(() => _loading = true);

    try {
      final res = await MaintenanceApi.submit(_maintenanceId!);

      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          _submitted = true;
          _locked = true;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('제출이 완료되었습니다.')));
      } else {
        debugPrint('SUBMIT fail status=${res.statusCode}, body=${res.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('제출 실패 (status: ${res.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onEditPressed() {
    if (_submitted) return;
    if (!_saved) return;
    _unlockFieldsForEdit();
  }

  @override
  Widget build(BuildContext context) {
    final categoryLabel = widget.category.displayName;

    final canEdit = _saved && !_submitted && !_loading;
    final canSubmit = _saved && !_submitted && !_loading;
    final canSave = !_submitted && !_loading && !_photoCtrl.isUploading;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        centerTitle: true,
        title: Text.rich(
          TextSpan(
            text: '쥬비스다이어트 ',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFF9EB5),
              height: 1.3,
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.bottomNav,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  '유지보수 요청서 작성',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.category_outlined),
                      const SizedBox(width: 10),
                      Text(
                        categoryLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _FieldCard(
                  child: TextFormField(
                    controller: _titleCtrl,
                    enabled: true,
                    readOnly: _locked,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    maxLines: 1,
                    decoration: const InputDecoration(
                      labelText: '제목',
                      hintText: '예) 조명 깜빡임, 콘센트 고장 등',
                      border: InputBorder.none,
                    ),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return '제목을 입력해주세요.';
                      if (t.length < 2) return '제목은 2자 이상 입력해주세요.';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _FieldCard(
                  child: TextFormField(
                    controller: _descCtrl,
                    enabled: true,
                    readOnly: _locked,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 6,
                    maxLines: null,
                    decoration: const InputDecoration(
                      labelText: '내용',
                      hintText: '증상/위치/발생시간/사진 여부 등을 자세히 적어주세요.',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ✅ 사진 영역: controller listen
                AnimatedBuilder(
                  animation: _photoCtrl,
                  builder: (context, _) {
                    final files = _photoCtrl.localPhotos;
                    final uploadedCount = _photoCtrl.uploadedPhotos.length;

                    return Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              '사진',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const Spacer(),
                            OutlinedButton.icon(
                              onPressed: (_locked || _submitted)
                                  ? null
                                  : _pickImages,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('추가'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (files.isEmpty)
                          const Text('선택된 사진이 없습니다.')
                        else
                          _PhotoGrid(
                            files: files,
                            locked: _locked || _submitted,
                            onRemove: _removeLocalPhoto,
                            uploadedCount: uploadedCount,
                          ),
                        const SizedBox(height: 10),
                        Text(
                          '업로드 상태: $uploadedCount/${files.length} 완료',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canSave ? _onSavePressed : null,
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('저장'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: canEdit ? _onEditPressed : null,
                        child: const Text('수정'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: canSubmit ? _onSubmitPressed : null,
                        child: const Text('제출'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _photoCtrl,
                  builder: (context, _) => _StatusHint(
                    saved: _saved,
                    locked: _locked,
                    submitted: _submitted,
                    allPhotosUploaded: _photoCtrl.allPhotosUploaded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final Widget child;

  const _FieldCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: child,
    );
  }
}

class _StatusHint extends StatelessWidget {
  final bool saved;
  final bool locked;
  final bool submitted;
  final bool allPhotosUploaded;

  const _StatusHint({
    required this.saved,
    required this.locked,
    required this.submitted,
    required this.allPhotosUploaded,
  });

  @override
  Widget build(BuildContext context) {
    final String text = submitted
        ? '제출 완료 상태입니다.'
        : saved
        ? (allPhotosUploaded ? '저장 완료: 제출 가능' : '저장 전 사진 업로드가 필요합니다.')
        : '작성 후 저장하면 입력칸이 잠깁니다. 수정 후에는 다시 저장해야 제출할 수 있어요.';

    return Text(text, style: const TextStyle(color: Colors.black54));
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<XFile> files; // ✅ File -> XFile
  final bool locked;
  final void Function(int index) onRemove;
  final int uploadedCount;

  const _PhotoGrid({
    required this.files,
    required this.locked,
    required this.onRemove,
    required this.uploadedCount,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (_, i) {
        final uploaded = i < uploadedCount;

        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(files[i].path), // ✅ XFile -> File(path)로 표시만
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.black.withOpacity(0.55),
                ),
                child: Text(
                  uploaded ? '업로드됨' : '대기',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            if (!locked)
              Positioned(
                right: 6,
                top: 6,
                child: InkWell(
                  onTap: () => onRemove(i),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.55),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
