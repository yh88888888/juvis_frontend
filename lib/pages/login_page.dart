import 'package:flutter/material.dart';
import 'package:juvis_faciliry/components/login_components/custom_form.dart';
import 'package:juvis_faciliry/components/login_components/logo.dart';
import 'package:juvis_faciliry/size.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SizedBox(height: xlarge_gap),
            Logo("로그인"),
            SizedBox(height: large_gap),
            CustomForm(),
          ],
        ),
      ),
    );
  }
}
