import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:alog/widget/custom_tab_view.dart'; // custom_tab_view.dart 가져오기

class SafetyInfoScreen extends StatefulWidget {
  @override
  _SafetyInfoScreenState createState() => _SafetyInfoScreenState();
}

class _SafetyInfoScreenState extends State<SafetyInfoScreen>
    with SingleTickerProviderStateMixin {
  Map<String, Map<String, String>> infoData = {}; // JSON 데이터를 저장할 변수
  String searchQuery = ''; // 검색어 저장
  bool searchResultExists = true; // 검색 결과 존재 여부
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  /// 검색 핸들러 함수
  void _handleSearch(String query) {
    setState(() {
      searchQuery = query;
      searchResultExists = _updateSearchResults(query);
    });
  }

  /// 검색 결과 업데이트
  bool _updateSearchResults(String query) {
    for (var category in infoData.keys) {
      final items = infoData[category]!;
      if (items.keys.any((key) => key.toLowerCase().contains(query.toLowerCase()))) {
        final tabIndex = infoData.keys.toList().indexOf(category);
        _tabController.animateTo(tabIndex); // 검색 결과가 있는 탭으로 이동
        return true;
      }
    }
    return false;
  }

  /// JSON 데이터를 로드하는 함수
  Future<void> _loadJsonData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/info_data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      setState(() {
        infoData = jsonData.map((key, value) {
          return MapEntry(
            key,
            Map<String, String>.from(value as Map),
          );
        });

        // 데이터 로드 후 TabController 초기화
        _tabController = TabController(
          length: infoData.keys.length,
          vsync: this,
        );
      });
    } catch (e) {
      print("Error loading JSON: $e");
    }
  }

  /// URL 열기 함수
  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print("Could not launch $url");
    }
  }

  /// 검색창 위젯 빌드 함수
  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(1.0),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4.0,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: TextField(
          onChanged: _handleSearch,
          decoration: const InputDecoration(
            prefix: SizedBox(width: 20),
            hintText: '검색어를 입력해주세요',
            border: InputBorder.none,
            suffixIcon: Icon(Icons.search),
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  /// 검색 결과 없는 경우 표시
  Widget _buildNoSearchResults() {
    return Expanded(
      child: Center(
        child: const Text(
          '검색 결과가 없습니다.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  /// 탭 콘텐츠 빌드 함수
  List<Widget> _buildTabContents(List<String> categories) {
    return categories.map((category) {
      final items = infoData[category]!;
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 한 행에 3개의 아이템 표시
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 54 / 38, // 카드의 비율
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final entry = items.entries.elementAt(index);
            return GestureDetector(
              onTap: () => _openUrl(entry.value),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: Offset(0, 3), // 그림자 위치 조정
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    child: Text(
                      entry.key,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  /// 전체 UI 빌드
  @override
  Widget build(BuildContext context) {
    if (infoData.isEmpty || _tabController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()), // 로딩 중
      );
    }

    final List<String> categories = infoData.keys.toList();

    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false, // 키보드가 올라와도 화면 밀림 방지
        body: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height, // 화면 높이 제한
            ),
            child: Column(
              children: [
                _buildSearchBox(),
                searchResultExists
                    ? Expanded(
                  child: CustomTabView(
                    controller: _tabController,
                    tabTitles: categories,
                    tabContents: _buildTabContents(categories),
                  ),
                )
                    : _buildNoSearchResults(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}