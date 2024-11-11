import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_naver_login/flutter_naver_login.dart';

import 'user_login.dart';
import 'main.dart';  // isLogin 변수를 사용하기 위해 main.dart를 import

final GlobalKey<ScaffoldMessengerState> snackbarKey =
GlobalKey<ScaffoldMessengerState>();

class UserInfoScreen extends StatefulWidget {
  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {

  /// Show [error] content in a ScaffoldMessenger snackbar
  void _showSnackError(String error) {
    snackbarKey.currentState?.showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(error.toString()),
      ),
    );
  }

  @override
  void initState() {
    // FlutterNaverLogin.initSdk(
    //   clientId: 'YOUR_CLIENT_ID',
    //   clientName: 'YOUR_CLIENT_NAME',
    //   clientSecret: 'YOUR_CLIENT_SECRET',
    // );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () {
                Navigator.of(context). pushReplacement(MaterialPageRoute(
                  builder: (context) => AppScreen(),
                ));
              },
            ),
            title: const Text(
              '회원정보',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          // 화면 중앙에 정렬하는 Center 위젯
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // 세로 방향 (위에서 아래로)
            crossAxisAlignment: CrossAxisAlignment.center, // 가로 방향 중앙 정렬

            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],  // 아이콘 배경색
                child: Icon(
                  Icons.person,  // 사람 아이콘
                  size: 50,  // 아이콘 크기
                  color: Colors.grey,  // 아이콘 색상
                ),
              ),
              const SizedBox(height: 10),
              Text(
                name ?? '이름 없음',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                email ?? '이메일 없음',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                phoneNumber ?? ' 전화번호 없음',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 250), // 400 -> 250 수정
              GestureDetector(
                onTap: () {
                  // 로그아웃 로직 구현
                  // 로그아웃 후 화면을 초기화하거나 다른 화면으로 전환
                  naverLogout(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3), // 그림자 색상 및 투명도
                        spreadRadius: 1, // 그림자 퍼지는 거리
                        blurRadius: 5, // 그림자 블러 처리 정도
                        offset: Offset(0, 3), // 그림자 위치
                      ),
                    ],
                  ),
                  child: Image.asset(
                      'assets/images/naver_logout.png', // 로그아웃 이미지 경로
                      width: 200,
                      height: 60,
                      fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 5), // 10 -> 5 수정
              TextButton(
                onPressed: () {
                  // 네이버 로그인 연동 해제 로직
                  unlinkNaverAccount(context);
                },
                child: const Text(
                  '네이버 로그인 연동해제',
                  style: TextStyle(
                    color: Colors.grey,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}

// 네이버 로그아웃
Future<void> naverLogout(BuildContext context) async {
  try {
    // 네이버 로그아웃 실행
    await FlutterNaverLogin.logOut();
    print("Logout successful");

    // 로그인 상태 false로 업데이트
    isLogin = false;

    // 로그인 페이지로 이동 (현재 페이지를 대체)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => UserLoginScreen(),
      ),
    );
  } catch (error) {
    print("Logout failed: $error");
  }
}


// 네이버 로그인 연동 해제 (회원 탈퇴) 기능
Future<void> unlinkNaverAccount(BuildContext context) async {
  try {
    //wait FlutterNaverLogin.logOut();  // 로그아웃
    await FlutterNaverLogin.logOutAndDeleteToken();  // 네이버 연동 해제

    // 성공 시 처리 로직
    print("네이버 계정 연동 해제 성공");
    isLogin = false;

    // 회원 탈퇴 후 로그인을 요청하는 페이지로 이동
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => UserLoginScreen(),
      ),
    );
  } catch (error) {
    print("네이버 계정 연동 해제 실패: $error");
  }
}