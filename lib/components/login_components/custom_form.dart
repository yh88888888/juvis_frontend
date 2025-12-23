import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ 추가
import 'package:juvis_faciliry/_core/session/session_provider.dart';
import 'package:juvis_faciliry/_core/session/session_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../size.dart';
import 'custom_text_filed.dart';

class CustomForm extends ConsumerStatefulWidget {
  const CustomForm({super.key});

  @override
  ConsumerState<CustomForm> createState() => _CustomFormState();
}

class _CustomFormState extends ConsumerState<CustomForm> {
  final _formKey = GlobalKey<FormState>();
  final idController = TextEditingController(); // username
  final pwController = TextEditingController(); // password

  bool _showErrors = false; // 에러 표시 여부 상태
  bool _saveId = false; // 아이디 저장
  bool _isLoading = false; // 로그인 중 로딩 표시용
  String? _loginError; // 아이디/비밀번호 불일치 메시지

  @override
  void initState() {
    super.initState();
    _loadSavedId(); // ✅ 로그인 화면은 "표시용"만
  }

  /// ✅ 로그인 화면에서 할 일:
  /// - 아이디 저장(save_id)이면 idController 채우기
  /// - 체크박스 상태만 복원
  /// ❌ 여기서 세션 자동복구(자동로그인 실행)는 하지 않음

  Future<void> _loadSavedId() async {
    final prefs = await SharedPreferences.getInstance();

    final savedId = prefs.getString('saved_id') ?? '';
    final saveId = prefs.getBool('save_id') ?? false;

    if (!mounted) return;
    setState(() {
      _saveId = saveId;
      if (saveId && savedId.isNotEmpty) {
        idController.text = savedId;
      }
    });
  }

  /// ✅ 로그인 성공 후 "설정값" 저장은 여기서만
  Future<void> _persistLoginPrefs(String username) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('save_id', _saveId);

    if (_saveId) {
      await prefs.setString('saved_id', username);
    } else {
      await prefs.remove('saved_id');
    }
  }

  @override
  void dispose() {
    idController.dispose();
    pwController.dispose();
    super.dispose();
  }

  // 🔹 로그인 요청 + 세션 업데이트 + 화면 이동
  Future<void> _submitLogin() async {
    final username = idController.text.trim();
    final password = pwController.text;

    setState(() {
      _loginError = null;
    });

    // 1) 유효성 검사 먼저
    setState(() => _showErrors = true);
    if (!_formKey.currentState!.validate()) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showErrors = false);
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ 로그인은 SessionNotifier가 담당 (토큰/세션 저장도 notifier 쪽에서)
      final SessionUser user = await ref
          .read(sessionProvider.notifier)
          .login(username: username, password: password);

      // ✅ UI 설정(아이디저장/자동로그인)은 여기서만 저장
      await _persistLoginPrefs(username);

      // ✅ (선택) 자동로그인 체크를 껐다면, 혹시 남아있는 토큰으로
      // 다음 앱 시작 때 자동복구되는 걸 원천 차단하고 싶으면
      // SessionNotifier에 clearStorage() 같은 함수를 만들어서 호출
      //
      // if (!_autoLogin) {
      //   await ref.read(sessionProvider.notifier).clearStorage(); // <- 토큰 제거
      // }

      if (!mounted) return;

      // role / id / name 은 이제 세션에서 가져올 수 있음
      final userId = user.id;
      final name = user.name;
      final role = user.role;

      if (role == "BRANCH") {
        Navigator.pushReplacementNamed(
          context,
          "/home",
          arguments: {'name': name, 'userId': userId},
        );
      } else if (role == "HQ") {
        if (kIsWeb) {
          Navigator.pushReplacementNamed(
            context,
            "/admin_web",
            arguments: {'name': name, 'userId': userId},
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            "/admin_app",
            arguments: {'name': name, 'userId': userId},
          );
        }
      } else if (role == "VENDOR") {
        Navigator.pushReplacementNamed(
          context,
          "/vendor",
          arguments: {'name': name, 'userId': userId},
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("알 수 없는 사용자 권한입니다.")));
      }
    } catch (e) {
      // SessionNotifier.login()에서 던진 에러 처리
      setState(() {
        _loginError = "로그인 실패: ${e.toString()}";
      });
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _loginError = null);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            minimumSize: const Size(400, 60),
          ),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: _showErrors
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField("아이디", controller: idController),
                SizedBox(height: medium_gap),
                CustomTextField("비밀번호", controller: pwController),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _saveId,
                          onChanged: (value) {
                            setState(() {
                              _saveId = value ?? false;
                            });
                          },
                        ),
                        const Text('아이디 저장'),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: large_gap),
                TextButton(
                  onPressed: _isLoading ? null : _submitLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Login"),
                ),
                if (_loginError != null) ...[
                  SizedBox(height: large_gap),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      _loginError!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
