import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> snackbarKey =
    GlobalKey<ScaffoldMessengerState>();

class UserInfoScreen extends StatefulWidget {
  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  bool isLogin = false;
  String? name = '햇님이'; // 테스트용 임시 값
  String? email = 'ididid@naver.com'; // 테스트용 임시 값
  String? phoneNumber = '010-1236-1235'; // 테스트용 임시 값
  String? profileImageUrl; // 프로필 이미지 URL (null일 경우 기본 이미지 사용)

  // String? accessToken;
  // String? expiresAt;
  // String? tokenType;
  // String? refreshToken;

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
                Navigator.pop(context);
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
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl!)
                    : AssetImage('assets/images/default_profile.png')
                        as ImageProvider,
                backgroundColor: Colors.grey[200],
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
                phoneNumber ?? '전화번호 없음',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 400),
              GestureDetector(
                onTap: () {
                  // 로그아웃 로직 구현
                  // 로그아웃 후 화면을 초기화하거나 다른 화면으로 전환
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
                      fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  // 네이버 로그인 연동 해제 로직
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
