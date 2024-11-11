import 'package:flutter/material.dart';
/*import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';*/
import 'package:url_launcher/url_launcher.dart';
import 'custom_tab_view.dart'; // custom_tab_view.dart 가져오기'
import 'custom_search_bar.dart'; // custom_search_bar.dart 가져오기


class SafetyInfoScreen extends StatelessWidget {
  final SearchController _searchController = SearchController();
  final Map<String, List<Map<String, String>>> disasterData = {
    '자연재난': [
      {'name': '침수', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/nat/flooding.html'},
      {'name': '태풍', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/nat/typhoon.html'},
      {'name': '호우', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/nat/downpour.html'},
      {'name': '낙뢰', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/nat/thunderstroke.html'},
      {'name': '강풍', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/nat/gale.html'},
      {'name': '풍랑', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/nat/storm.html'},
      {'name': '대설', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/nat/heavySnow.html'},
      {'name': '한파', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/nat/coldWave.html'},
      {'name': '폭염', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/nat/heatWave.html'},
    ],
    '사회재난': [
      {'name': '화재', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/sot/fire.html'},
      {'name': '산불', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/sot/forestFire.html'},
      {'name': '건축물 붕괴', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/sot/building.html'},
      {'name': '폭발', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/sot/explosion.html'},
      {'name': '교통사고', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/lit/traffic.html'},
      {'name': '전기·가스사고', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/sot/electricGas.html'},
    ],
    '생활안전': [
      {'name': '여름철물놀이사고', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/lit/summer.html'},
      {'name': '산행안전사고', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/lit/hiking.html'},
      {'name': '응급처치', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/lit/emergency.html'},
      {'name': '해파리피해', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/lit/jellyfish.html'},
      {'name': '심폐소생술', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/lit/CPR.html'},
      {'name': '붉은불개미', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/lit/ant.html'},
      {'name': '승강기 안전사고', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/lit/elevator.html'},
      {'name': '놀이시설 안전사고', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/lit/playground.html'},
    ],
    '비상대비': [
      {'name': '테러', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/sot/terror.html'},
      {'name': '비상사태', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/set/emergencySit.html'},
      {'name': '민방공', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/set/civilAirDefence.html'},
      {'name': '화생방무기', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/set/CBP.html'},
      {'name': '비상대비 물자', 'url': 'https://m.safekorea.go.kr/idsiSFK/neo/main_m/set/supplies.html'}
    ],
  };

  SafetyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: disasterData.keys.length, // 대분류의 개수만큼 탭을 생성
      child: Scaffold(
        backgroundColor: Colors.white,
        body:
          Column(
            children: [
              CustomSearchBar(
                searchController: _searchController,
                onSearchChanged: (String query) {
                  print('Search query: $query'); // 검색어 입력 시 출력
                },
              ),
              Expanded(
                child:
                CustomTabView(
                tabTitles: disasterData.keys.toList(), // 대분류 이름 리스트
                tabContents: disasterData.keys.map((category) {
                  final items = disasterData[category]!;
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // 한 행에 3개의 아이템 표시
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                        childAspectRatio: 2 / 1, // 카드의 비율
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return GestureDetector(
                          onTap: () => _openUrl(item['url']!),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3), // 그림자 위치 조정
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                item['name']!,
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
              ),
            ],
          )
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
}
