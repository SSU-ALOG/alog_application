
import 'package:flutter/material.dart';
import 'package:alog/widget/custom_search_bar.dart'; // custom_search_bar.dart 가져오기
import 'package:alog/widget/custom_tab_view.dart'; // custom_tab_view.dart 가져오기
import 'package:alog/widget/custom_choice_chip_group.dart';


class SafetyInfoScreen extends StatefulWidget {
  const SafetyInfoScreen({Key? key}) : super(key: key);

  @override
  _SafetyInfoScreenState createState() => _SafetyInfoScreenState();
}

class _SafetyInfoScreenState extends State<SafetyInfoScreen> {
  final SearchController _searchController = SearchController();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // 탭 수 설정
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: <Widget>[
            // 검색창
            CustomSearchBar(
              searchController: _searchController,
              onSearchChanged: (String query) {
                print('Search query: $query'); // 검색어 입력 시 출력
              },
            ),
            // 탭 바와 탭 뷰
            Expanded(
              child: CustomTabView(
                tabTitles: ["자연재난", "사회재난", "생활안전", "비상대비"],
                tabContents: <Widget>[
                  // 첫 번째 탭: 필터와 메시지 리스트
                  Column(
                    children: [
                      const CustomChoiceChipGroup(
                        options: ['ALL', '위급재난', '긴급재난', '안전안내', '실종알림'],
                        initialSelected: 'ALL',
                      ),
                      const Divider(),
                    ],
                  ),
                  // 두 번째 탭: 발송지역 (데모용)
                  const Center(
                    child: Text('발송지역 탭입니다.'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
