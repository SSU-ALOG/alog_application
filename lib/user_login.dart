import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'user_info.dart';
import 'main.dart';  // isLogin 변수를 사용하기 위해 main.dart를 import

// import 'package:flutter_naver_login/flutter_naver_login.dart';

// final GlobalKey<ScaffoldMessengerState> snackbarKey =
//     GlobalKey<ScaffoldMessengerState>();

class UserLoginScreen extends StatefulWidget {
  @override
  _UserLoginScreenState createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {

  // 네이버 로그인
  Future<void> signInWithNaver(BuildContext context) async {
    try {
      // 네이버 로그인 결과를 기다림
      final res = await FlutterNaverLogin.logIn();

      // 현재 액세스 토큰 가져오기
      NaverAccessToken accessTokenData = await FlutterNaverLogin.currentAccessToken;
      var accessToken = accessTokenData.accessToken;
      var tokenType = accessTokenData.tokenType;

      print("accessToken $accessToken");
      print("tokenType $tokenType");

      // 사용자 정보 확인
      setState(() {
        isLogin = true;
        name = res.account.nickname;  // 사용자 이름(닉네임)
        email = res.account.email;    // 이메일
        phoneNumber = res.account.mobile;  // 전화번호
      });

      // 로그인 후 회원정보 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => UserInfoScreen(),
        ),
      );
    } catch (error) {
      // 로그인 실패 시 에러 처리
      print("네이버 로그인 실패: $error");
    }
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
              '회원가입 및 로그인',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () async {
            await signInWithNaver(context);
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
              'assets/images/naver_login.png',
              // Replace with the actual image path for Naver login
              width: 300,
              height: 80, // Adjust the width and height to match the design
              fit: BoxFit.fitWidth, // Ensures the image scales nicely
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}