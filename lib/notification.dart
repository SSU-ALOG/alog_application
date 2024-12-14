import 'dart:async';
import 'dart:developer';
import 'package:alog/providers/message_provider.dart';
import 'package:flutter/material.dart';
import 'package:alog/models/message.dart';
import 'package:alog/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:alog/widget/custom_tab_view.dart'; // CustomTabView를 import
import 'package:alog/widget/custom_choice_chip_group.dart'; // CustomChoiceChipGroup import

// Emergency Steps (긴급단계 리스트)
const List<String> emergencySteps = [
  'ALL',
  '위급재난',
  '긴급재난',
  '안전안내',
  '실종알림',
];

// Region List (발송 지역 리스트)
const List<String> regionList = [
  'ALL',
  '서울특별시',
  '부산광역시',
  '대구광역시',
  '인천광역시',
  '광주광역시',
  '대전광역시',
  '울산광역시',
  '세종특별자치시',
  '경기도',
  '충청북도',
  '충청남도',
  '전라남도',
  '경상북도',
  '경상남도',
  '강원특별자치도',
  '전북특별자치도',
  '제주특별자치도'
];

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Message>> futureMessages;
  late TabController _tabController;
  final ApiService apiService = ApiService();

  // 필터 상태 변수
  String _selectedEmergencyStep = 'ALL';
  String _selectedRegion = 'ALL';
  String _searchQuery = '';

  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isDataLoaded) {
      _initializeData(); // 데이터 초기화
      _isDataLoaded = true;
    }
  }

  void _initializeData() {
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);

    messageProvider.addListener(() {
      _updateContentList(messageProvider);
    });
  }

  void _updateContentList(MessageProvider messageProvider) {
    // MessageProvider에서 데이터를 가져옴
    futureMessages = Future(() async {
      // MessageProvider의 데이터를 가져와서 빈 데이터 처리
      final List<Message> messages = messageProvider.messages;

      if (messages.isEmpty) {
        return [];
      }

      // "찾습니다" 문구를 기준으로 분류 업데이트
      for (var message in messages) {
        if (message.msgContent.contains("찾습니다")) {
          message.emergencyStep = "실종알림";
        }
      }

      return messages;
    });
  }

  void _selectEmergencyStep(String step) {
    setState(() {
      _selectedEmergencyStep = step; // 선택된 필터 업데이트
    });
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<Message> _applyFilters(List<Message> messages) {
    return messages.where((message) {
      final emergencyStepMatch = _selectedEmergencyStep == 'ALL' ||
          message.emergencyStep.contains(_selectedEmergencyStep);
      final regionMatch = _selectedRegion == 'ALL' ||
          message.regionName.contains(_selectedRegion);
      final searchMatch = _searchQuery.isEmpty ||
          message.msgContent.contains(_searchQuery) ||
          message.regionName.contains(_searchQuery);

      return emergencyStepMatch && regionMatch && searchMatch;
    }).toList();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // 키보드로 인해 UI가 밀리지 않도록 설정
      body: Column(
        children: [
          _buildSearchBox(),
          SizedBox(
            height: 100,
            child: CustomTabView(
              controller: _tabController,
              tabTitles: ['긴급단계', '발송지역'],
              tabContents: [
                _buildEmergencyStepFilter(),
                _buildRegionDropdown(),
              ],
            ),
          ),
          Divider(
            color: Colors.black12,
            height: 4.0,
          ),
          Expanded(
            child: _buildMessageList(),
          ),
        ],
      ),
    );
  }

  // 검색 창
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
          onChanged: (query) {
            setState(() {
              _searchQuery = query; // 검색어 업데이트
            });
          },
          onSubmitted: (query) {
            _performSearch(query); // enter 입력 시 검색 실행
          },
          decoration: InputDecoration(
            prefix: const SizedBox(width: 20),
            hintText: '검색어를 입력해주세요',
            suffixIcon: GestureDetector(
              onTap: () {
                _performSearch(_searchQuery);
              },
              child: const Icon(Icons.search, color: Colors.grey),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // 메시지 리스트를 빌드하는 함수
  Widget _buildMessageList() {
    return FutureBuilder<List<Message>>(
      future: futureMessages, // 초기화된 futureMessages
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // 데이터 로드 중
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // 오류 발생 시
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final messages = snapshot.data ?? [];
        final filteredMessages = _applyFilters(messages);

        if (filteredMessages.isEmpty) {
          // 메시지가 없을 경우
          return const Center(
            child: Text(
              '재난 문자 내용이 없습니다.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // 메시지가 있을 경우 ListView로 렌더링
        return ListView.builder(
          itemCount: filteredMessages.length,
          itemBuilder: (context, index) {
            final message = filteredMessages[index];

            return MessageCard(
              messageType: message.emergencyStep, // 긴급단계
              messageContent: message.msgContent, // 메시지 내용
              messageTime: message.createDate, // 생성 날짜
            );
          },
        );
      },
    );
  }


  // 필터 탭 내용
  Widget _buildEmergencyStepFilter() {
    return CustomChoiceChipGroup(
      options: emergencySteps,
      initialSelected: _selectedEmergencyStep,
      onSelectionChanged: (selected) {
        _selectEmergencyStep(selected); // 선택된 값 업데이트
      },
    );
  }

  // 발송 지역 드롭다운
  Widget _buildRegionDropdown() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 8.0),
      child: Row(
        children: [
          // 레이블 텍스트
          Text(
            '발송지역 선택:', // 레이블 이름
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(width: 10), // 레이블과 드롭다운 사이 간격

          // 드롭다운 위젯
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedRegion,
              items: regionList.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRegion = value!;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageCard extends StatelessWidget {
  final String messageType;
  final String messageContent;
  final String messageTime;

  const MessageCard({
    Key? key,
    required this.messageType,
    required this.messageContent,
    required this.messageTime,
  }) : super(key: key);

  IconData _getIconData(String emergencyStep) {
    switch (emergencyStep) {
      case '실종알림':
        return Icons.person_pin_circle; // 실종알림
      case '위급재난':
        return Icons.warning; // 위급재난
      case '긴급재난':
        return Icons.error; // 긴급재난
      case '안전안내':
        return Icons.info; // 안전안내
      default:
        return Icons.chat_outlined; // 기본 아이콘
    }
  }

  Color _getIconColor(String emergencyStep) {
    switch (emergencyStep) {
      case '위급재난':
        return Colors.red; // 빨간색
      case '긴급재난':
        return Colors.yellow; // 노란색
      case '안전안내':
        return Colors.blue; // 파란색
      case '실종알림':
        return Colors.grey; // 주황색
      default:
        return Colors.black26; // 기본 색상
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xffF9F7F7),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // 아이콘과 텍스트를 가운데 정렬
          children: [
            // 아이콘 영역
            SizedBox(
              height: 50, // 아이콘 높이를 중앙에 맞추기 위한 상자 크기
              child: Center(
                child: Icon(
                  _getIconData(messageType), // emergencyStep에 따른 아이콘 설정
                  color: _getIconColor(messageType), // emergencyStep에 따른 색상 설정
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 10), // 아이콘과 텍스트 간격

            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 텍스트와 날짜를 Row로 배치
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$messageType문자', // messageType 뒤에 "문자" 추가
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        messageTime, // 오른쪽 상단에 날짜 표시
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5), // 간격
                  Text(
                    messageContent,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
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
