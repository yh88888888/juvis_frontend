import 'package:flutter/foundation.dart';

// 스프링부트가 내 PC에서 8080으로 떠 있다고 가정
const String prodApi = "https://api.yourdomain.com"; // 배포용 운영 서버
const String devApiWeb = "http://localhost:8080"; // 웹 개발용
const String devApiAndroid = "http://10.0.2.2:8080"; // 에뮬 개발용

const bool isProduction = bool.fromEnvironment('dart.vm.product');

String get apiBase {
  if (isProduction) {
    return prodApi;
  }
  if (kIsWeb) {
    return devApiWeb;
  } else {
    return devApiAndroid;
  }
}
