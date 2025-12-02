import 'package:flutter/material.dart';
import 'package:juvis_faciliry/pages/home_page.dart';
import 'package:juvis_faciliry/pages/login_page.dart';

void main() {
  runApp(JuvisApp());
}

class JuvisApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/login",
      routes: {
        "/login": (context) => LoginPage(),
        "/home": (context) => HomePage(),
      },
    );
  }
}
