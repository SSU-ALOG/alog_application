import 'package:flutter/material.dart';
import 'dart:async';

// import 'package:flutter_naver_login/flutter_naver_login.dart';

// final GlobalKey<ScaffoldMessengerState> snackbarKey =
//     GlobalKey<ScaffoldMessengerState>();

class UserLoginScreen extends StatefulWidget {
  @override
  _UserLoginScreenState createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {

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
                Navigator.pop(context);
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
            // Implement Naver login functionality here
            // Call the Naver Login API or relevant method
            //   await NaverLogin();
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
