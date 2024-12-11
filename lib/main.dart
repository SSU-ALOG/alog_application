import 'dart:developer';

import 'package:alog/user_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'accident_registration.dart';
import 'incident.dart';
import 'map.dart';
import 'incident.dart';
import 'user_login.dart';
import 'user_info.dart';
import 'streaming_sender.dart';
import 'streaming_viewer.dart';
import 'message.dart';
import 'safetyinfo.dart';
import 'accident_registration.dart';

bool isLogin = false;  // 전역 변수로 로그인 상태를 관리
String? name;
String? email;
String? phoneNumber;

void main() async {
  await initialize();
  runApp(const App());
}

// 초기화 함수
Future<void> initialize() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  // Firebase 초기화

  // 환경 변수 설정
  await dotenv.load(fileName: '.env');

  // 지도 초기화
  await NaverMapSdk.instance.initialize(
      clientId: dotenv.env['NCP_MAP_API_KEY_ID'],
      onAuthFailed: (e) => log("네이버맵 인증오류 : $e", name: "onAuthFailed")
  );

  // 알림 권한 요청
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // FCM 초기화 및 백그라운드 메시지 핸들러 등록
  await Firebase.initializeApp();
  FirebaseMessaging.instance.subscribeToTopic('alog-all').then((_) { });
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

/// 백그라운드 및 종료 상태에서 수신한 FCM 메시지를 처리하는 핸들러
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('백그라운드 또는 종료 상태에서 메시지 수신: ${message.messageId}');
  NotificationService().handleIncomingMessage(message);
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App',
      debugShowCheckedModeBanner: false, // 우상단 DEBUG 띠 없앰
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AppScreen(),
    );
  }
}

class AppScreen extends StatefulWidget {
  const AppScreen({Key? key}) : super(key: key);

  @override
  _AppScreenState createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MapScreen(),
    const NotificationsScreen(),
    const SafetyInfoScreen(),
    const IncidentScreen(),
  ];

  final List<String> _appBarTitles = [
    '지도',
    '문자 모아보기',
    '안전정보',
    '사건·사고'
  ];

  final List<IconData> _navigationIcons = [
    Icons.map,
    Icons.notifications,
    Icons.info,
    Icons.remove_red_eye
  ];

  @override
  void initState() {
    super.initState();

    // FCM 초기화 및 토큰 가져오기
    FirebaseMessaging.instance.getToken().then((token) {
      log("FCM 토큰: $token");
      // 서버로 토큰 전송 로직 추가
    });

    // 포그라운드에서 메시지 처리
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('포그라운드에서 메시지 수신: ${message.messageId}');
      NotificationService().handleIncomingMessage(message);
    });

    // 메시지 클릭 시 처리
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('클릭 후 앱 열림, 메시지: ${message.messageId}');
      // 특정 화면으로 이동 등의 추가 로직 작성 가능
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 데이터 초기화는 한 번만 실행
    if (!_isDataLoaded) {
      Provider.of<IssueProvider>(context, listen: false).fetchRecentIssues();
      _isDataLoaded = true; // 초기화 완료
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset : false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              onPressed: () {
                // 사건 등록 스크린
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AccidentRegistScreen()),
                );
              },
            ),
            title: Text(
              _appBarTitles[_selectedIndex],
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.person, color: Colors.black),
                onPressed: () {
                  // 프로필 기능 구현
                  // Navigate to the user_login.dart page

                  // Naver login session 존재 시. UserInfoScreen()으로 넘어가게끔

                  // Naver login session 없을 시. UserLoginScreen()으로 넘어가게끔
                  // 우선 이걸로 activity 넘어가게끔 함.
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => isLogin ? UserInfoScreen() : UserLoginScreen() ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex, // 선택된 인덱스
        children: _screens,    // 화면 위젯
      ),
      bottomNavigationBar: Container(
        height: 90,
        child: Theme(   // 터치 애니메이션 효과 제거를 위해 Theme 사용
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.redAccent,
            selectedFontSize: 12,
            unselectedItemColor: Colors.grey,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index; // 선택된 인덱스 업데이트
              });
            },
            items: List.generate(
              _appBarTitles.length,
                  (index) => BottomNavigationBarItem(
                icon: Icon(_navigationIcons[index]),
                label: _appBarTitles[index],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// 더미 위젯들
// 본인 파트 따로 파일 만들어서 빼주면 감사링~
// class NotificationsScreen extends StatelessWidget {
//   const NotificationsScreen({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(child: Text("문자 모아보기 화면"));
//   }
// }
//
// class SafetyInfoScreen extends StatelessWidget {
//   const SafetyInfoScreen({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(child: Text("안전 정보 화면"));
//   }
// }
//
// class IncidentScreen extends StatelessWidget {
//   const IncidentScreen({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(child: Text("사건·사고 화면"));
//   }
// }