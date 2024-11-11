import 'package:flutter/material.dart';
import 'custom_search_bar.dart';
import 'custom_tab_view.dart';
import 'custom_choice_chip_group.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SearchController _searchController = SearchController();

  // 더미 메시지 데이터
  final List<Map<String, String>> messages = [
    {
      'type': '실종알림문자',
      'content': '영등포구에서 배회중인 문무철씨(남, 80세)를 찾습니다. 키: 170cm...',
      'time': '2시간 전',
      'icon': 'warning',
    },
    {
      'type': '안전안내문자',
      'content': '10월 11일까지 주말 한파 초 300도 이내 수준입니다...',
      'time': '3시간 전',
      'icon': 'info',
    },
    {
      'type': '안전안내문자',
      'content': '화재 사고로 인한 인근 지역 주민들은...',
      'time': '3시간 전',
      'icon': 'info',
    },
    {
      'type': '실종알림문자',
      'content': '양산시 주민 김효섭씨(여, 93세)를 찾습니다...',
      'time': '4시간 전',
      'icon': 'warning',
    },
    {
      'type': '긴급안내문자',
      'content': '도로 상의 쓰레기를 치워주시기 바랍니다...',
      'time': '4시간 전',
      'icon': 'alert',
    },
  ];

  // 시도, 시군구, 읍면동 데이터
  final Map<String, List<String>> _districts = {
    '서울': ['강남구', '강북구', '서초구'],
    '부산': ['해운대구', '수영구', '동래구'],
    '대구': ['중구', '수성구', '달서구'],
  };

  final Map<String, List<String>> _towns = {
    '강남구': ['역삼동', '삼성동', '논현동'],
    '해운대구': ['우동', '중동', '좌동'],
    '중구': ['동인동', '대봉동', '삼덕동'],
  };

  String? _selectedCity; // 시도 선택
  String? _selectedDistrict; // 시군구 선택
  String? _selectedTown; // 읍면동 선택

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 탭 수 설정
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
                tabTitles: ["긴급단계", "발송지역"],
                tabContents: <Widget>[
                  // 첫 번째 탭: 필터와 메시지 리스트
                  Column(
                    children: [
                      const CustomChoiceChipGroup(
                        options: ['ALL', '위급재난', '긴급재난', '안전안내', '실종알림'],
                        initialSelected: 'ALL',
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return MessageCard(
                              messageType: message['type']!,
                              messageContent: message['content']!,
                              messageTime: message['time']!,
                              iconType: message['icon']!,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  // 두 번째 탭: 발송지역 탭 (드롭다운 한 줄에 출력)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                value: _selectedCity,
                                items: _districts.keys.toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCity = value;
                                    _selectedDistrict = null; // 시군구 초기화
                                    _selectedTown = null; // 읍면동 초기화
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDropdown(
                                value: _selectedDistrict,
                                items: _selectedCity != null ? _districts[_selectedCity!]! : [],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDistrict = value;
                                    _selectedTown = null; // 읍면동 초기화
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDropdown(
                                value: _selectedTown,
                                items: _selectedDistrict != null ? _towns[_selectedDistrict!]! : [],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedTown = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return MessageCard(
                              messageType: message['type']!,
                              messageContent: message['content']!,
                              messageTime: message['time']!,
                              iconType: message['icon']!,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 드롭다운 생성 함수
  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButton<String>(
      isExpanded: true,
      value: value,
      hint: const Text('선택'),
      items: items.map<DropdownMenuItem<String>>((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class MessageCard extends StatelessWidget {
  final String messageType;
  final String messageContent;
  final String messageTime;
  final String iconType;

  const MessageCard({
    Key? key,
    required this.messageType,
    required this.messageContent,
    required this.messageTime,
    required this.iconType,
  }) : super(key: key);

  IconData _getIconData(String iconType) {
    switch (iconType) {
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      case 'alert':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xffF9F7F7),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: Icon(
          _getIconData(iconType),
          color: iconType == 'warning' ? Colors.red : Colors.blue,
        ),
        title: Text(messageType),
        subtitle: Text(messageContent),
        trailing: Text(messageTime),
      ),
    );
  }
}
