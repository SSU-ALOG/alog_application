import 'package:flutter/material.dart';

class CustomTabView extends StatelessWidget {
  final List<String> tabTitles; // Tab 제목 -> 선택할 탭
  final List<Widget> tabContents; // Tab 내용 -> 탭 선택 시 뜨는 화면
  final TabController? controller; // 외부에서 TabController를 전달받을 수 있도록 추가

  const CustomTabView({
    Key? key,
    required this.tabTitles,
    this.controller,
    required this.tabContents,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TabBar(
          controller: controller, // 외부에서 전달받은 TabController를 사용
          tabs: tabTitles.map((title) => Tab(text: title)).toList(),
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 2.0, color: Colors.black), // 인디케이터 커스터마이징
          ),
          labelStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ), // 선택된 탭 텍스트 스타일
          unselectedLabelColor: Colors.grey, // 선택되지 않은 탭 텍스트 색상
        ),
        Expanded(
          child: TabBarView(
            controller: controller, // TabController를 TabBarView에 전달
            children: tabContents,
          ),
        ),
      ],
    );
  }
}
