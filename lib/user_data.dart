import 'package:flutter/foundation.dart';

class UserData extends ChangeNotifier {
  bool isLogin = false; // 로그인 상태
  String? name;         // 사용자 이름
  String? email;        // 이메일
  String? phoneNumber;  // 전화번호

  // 로그인 시 사용자 정보와 상태 업데이트
  void login(String newName, String newEmail, String newPhoneNumber) {
    isLogin = true;
    name = newName;
    email = newEmail;
    phoneNumber = newPhoneNumber;
    notifyListeners(); // 상태 변경 알림
  }

  // 로그아웃 시 상태 초기화
  void logout() {
    isLogin = false;
    name = null;
    email = null;
    phoneNumber = null;
    notifyListeners(); // 상태 변경 알림
  }
}
