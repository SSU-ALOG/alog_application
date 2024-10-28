import 'package:flutter/material.dart';

class CustomTabView extends StatelessWidget {
  final List<String> tabTitles; // Tab 제목 -> 선택할 탭
  final List<Widget> tabContents; // Tab 내용 -> 탭 선택 시 뜨는 화면

  const CustomTabView({
    Key? key,
    required this.tabTitles,
    required this.tabContents,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TabBar(
          tabs: tabTitles.map((title) => Tab(text: title)).toList(),
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 2.0, color: Colors.black), // 인디케이터 커스터마이징
          ),
          labelStyle: TextStyle(
              color: Colors.black,
              fontWeight:FontWeight.bold
          ), // 선택된 탭 텍스트 색상
          unselectedLabelColor: Colors.grey, // 선택되지 않은 탭 텍스트 색상
        ),
        Expanded(
          child: TabBarView(
            children: tabContents,
          ),
        ),
      ],
    );
  }
}
