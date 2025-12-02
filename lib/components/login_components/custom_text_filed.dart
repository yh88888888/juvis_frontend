import 'package:flutter/material.dart';

import '../../size.dart';

class CustomTextField extends StatelessWidget {
  final String text;
  final TextEditingController controller;

  const CustomTextField(this.text, {required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text),
        SizedBox(height: small_gap),
        TextFormField(
          controller: controller,
          readOnly: false,
          // 반드시 false (또는 제거)
          enableInteractiveSelection: true,
          // 커서 이동, 선택 가능
          autofocus: false,
          // 자동 포커스는 필요에 따라
          keyboardType: TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "빈 칸을 입력해 주세요";
            }

            if (text == "아이디") {
              if (value.length < 4) return "아이디는 최소 4자 이상이어야 합니다";
              if (value.length > 20) return "아이디는 최대 20자까지 가능합니다";
            }

            if (text == "비밀번호") {
              if (value.length < 4) return "비밀번호는 최소 4자리 이상이어야 합니다";
              if (value.length > 20) return "비밀번호는 최대 20자리까지 가능합니다";
            }

            return null;
          },
          obscureText: text == "비밀번호",
          decoration: InputDecoration(
            hintText: "$text를 입력해 주세요",
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.black, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.red, width: 2.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.red.shade700, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}
