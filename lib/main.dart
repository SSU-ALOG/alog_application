import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'map.dart';

void main() async {
  await initialize();
  _permission();
  runApp(const App());
}

// 초기화 함수
Future<void> initialize() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 변수 설정
  await dotenv.load(fileName: '.env');

  // 지도 초기화
  await NaverMapSdk.instance.initialize(
      clientId: dotenv.env['NAVER_MAP_API_KEY'],
      onAuthFailed: (e) => log("네이버맵 인증오류 : $e", name: "onAuthFailed")
  );
}

// 퍼미션 함수
void _permission() async {
  var requestStatus = await Permission.location.request();
  var status = await Permission.location.status;
  if (requestStatus.isPermanentlyDenied || status.isPermanentlyDenied) {
    openAppSettings();
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App',
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
                // 추가 기능 구현
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
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex, // 선택된 인덱스
        children: _screens,    // 화면 위젯들
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
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("문자 모아보기 화면"));
  }
}

class SafetyInfoScreen extends StatelessWidget {
  const SafetyInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("안전 정보 화면"));
  }
}

class IncidentScreen extends StatelessWidget {
  const IncidentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("사건·사고 화면"));
  }
}