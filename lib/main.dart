import 'package:flutter/material.dart';
// import 'map.dart';

void main() async {
  // await initialize();
  runApp(const App());
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
    const NaverMapScreen(),
    const NotificationsScreen(),
    const SafetyInfoScreen(),
    const IncidentScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              onPressed: () {
                // 추가 기능 구현
              },
            ),
            title: const Text(
              '지도',
              style: TextStyle(
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
        children: _screens, // 화면 위젯들
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: '지도',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications),
                label: '문자 모아보기',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.info),
                label: '안전정보',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.remove_red_eye),
                label: '사건·사고',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 더미 위젯들
// 본인 파트 따로 파일 만들어서 빼주면 감사링~
class NaverMapScreen extends StatelessWidget {
  const NaverMapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("지도 화면"));
  }
}

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