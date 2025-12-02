import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../size.dart';
import 'custom_text_filed.dart';

class CustomForm extends StatefulWidget {
  const CustomForm({super.key});

  @override
  State<CustomForm> createState() => _CustomFormState();
}

class _CustomFormState extends State<CustomForm> {
  final _formKey = GlobalKey<FormState>();
  final idController = TextEditingController(); // username
  final pwController = TextEditingController(); // password

  bool _showErrors = false; // 에러 표시 여부 상태
  bool _saveId = false; // 아이디 저장
  bool _autoLogin = false; // 자동 로그인
  bool _isLoading = false; // 로그인 중 로딩 표시용
  String? _loginError; // 아이디/비밀번호 불일치 메시지

  @override
  void initState() {
    super.initState();
    _loadSavedLoginInfo();
  }

  Future<void> _loadSavedLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();

    final savedId = prefs.getString('saved_id') ?? '';
    final saveId = prefs.getBool('save_id') ?? false;
    final autoLogin = prefs.getBool('auto_login') ?? false;

    setState(() {
      _saveId = saveId;
      _autoLogin = autoLogin;
      if (saveId && savedId.isNotEmpty) {
        idController.text = savedId;
      }
    });

    // ⚠️ 실제 자동 로그인은 토큰 기반으로 구현하는 게 안전함
    // if (autoLogin) {
    //   await _submitLogin(); // 나중에 토큰 기반 자동 로그인으로 변경
    // }
  }

  @override
  void dispose() {
    idController.dispose();
    pwController.dispose();
    super.dispose();
  }

  // 🔹 로그인 요청 + 응답 처리 + 화면 이동
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

    const String apiBase = "http://10.0.2.2:8080"; // Android 에뮬레이터 기준
    final uri = Uri.parse("$apiBase/api/auth/login");

    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      // 2) HTTP 상태 코드 체크
      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = jsonDecode(res.body);

        // 3) 서버에서 내려준 status == 200 인지 체크
        if (decoded["status"] == 200) {
          final body = decoded["body"];
          final userId = body["id"];
          final resUsername = body["username"];
          final roles = body["roles"];
          final name = body["name"];

          print(
            "로그인/가입 성공 userId=$userId, username=$resUsername, roles=$roles",
          );

          // ✅ 로그인 성공 시, 아이디/설정 저장
          final prefs = await SharedPreferences.getInstance();

          // "아이디 저장" 체크되어 있으면 아이디 저장, 아니면 삭제
          if (_saveId) {
            await prefs.setString('saved_id', username);
            await prefs.setBool('save_id', true);
          } else {
            await prefs.remove('saved_id');
            await prefs.setBool('save_id', false);
          }

          // "자동 로그인" 설정 저장 (토큰 연동은 나중에)
          await prefs.setBool('auto_login', _autoLogin);

          if (!mounted) return;

          // 🔸 HomePage로 이동 (뒤로가기 누르면 로그인으로 안 돌아오게)
          Navigator.pushReplacementNamed(
            context,
            "/home",
            arguments: {'name': name, 'userId': userId},
          );
        } else {
          // status != 200 인 경우
          final msg = decoded["msg"] ?? "알 수 없는 오류";
          setState(() {
            _loginError = "에러발생";
          });
          ;
          _showSnackBar("요청 실패: $msg");
        }
      } else if (res.statusCode == 401) {
        setState(() {
          _loginError = "아이디 혹은 비밀번호가 틀렸습니다.";
        });
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() => _loginError = null);
          }
        });
        // _showSnackBar("아aaa이디 혹은 비밀번호가 틀렸습니다.");

        // ✅ 3) 그 외 상태코드 → 진짜 서버 오류
      } else {
        _showSnackBar("서버 오류가 발생했습니다. (코드: ${res.statusCode})");
        print("실패: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      _showSnackBar("네트워크 오류: $e");
      print("예외 발생: $e");
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

                // ✅ 아이디 저장 / 자동 로그인 Row
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _autoLogin,
                          onChanged: (value) {
                            setState(() {
                              _autoLogin = value ?? false;
                            });
                          },
                        ),
                        const Text('자동 로그인'),
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
                // 🔹 여기 추가: 로그인 에러 메시지 출력
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
