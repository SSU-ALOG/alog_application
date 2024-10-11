import 'dart:async';
import 'dart:developer';

import 'package:alog/main.dart';
import 'package:flutter/material.dart';

class IncidentScreen extends StatefulWidget {
  const IncidentScreen({Key? key}) : super(key: key);

  @override
  _IncidentScreenState createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {

  Set<String> _selectedDisaster = {'ALL'};
  final List<String> disasterCategories = [
    'ALL',
    '범죄',
    '화재',
    '건강위해',
    '안전사고',
    '자연재해',
    '재난',
    '동식물 재난',
    '도시 서비스',
    '디지털 서비스',
    '기타'
  ];

  void _toggleFilter(String filter) {
    setState(() {
      if (filter == 'ALL') {
        // ALL 선택 시 다른 필터를 해제
        _selectedDisaster.clear();
        _selectedDisaster.add('ALL');
      } else {
        // 다른 필터 선택 시 ALL 해제
        if (_selectedDisaster.contains('ALL')) {
          _selectedDisaster.remove('ALL');
        }
        if (_selectedDisaster.contains(filter)) {
          _selectedDisaster.remove(filter);
        } else {
          _selectedDisaster.add(filter);
        }
      }
      // 선택된 필터가 없을 시 자동으로 ALL 선택
      if (_selectedDisaster.isEmpty) {
        _selectedDisaster.add('ALL');
      }
    });
  }




  Set<String> _selectedDisasterStatus = {'ALL'};
  final List<String> disasterStatus = [
    'ALL',
    '진행중',
    '상황종료',
    '긴급',
  ];
  final Map<String, IconData> disasterStatusIcons = {
    '진행중': Icons.warning,
    '상황종료': Icons.check_circle,
    '긴급': Icons.error_outline,
  };

  void _toggleStatusFilter(String filter) {
    setState(() {
      if (filter == 'ALL') {
        // ALL 선택 시 다른 필터를 해제
        _selectedDisasterStatus.clear();
        _selectedDisasterStatus.add('ALL');
      } else {
        // 다른 필터 선택 시 ALL 해제
        if (_selectedDisasterStatus.contains('ALL')) {
          _selectedDisasterStatus.remove('ALL');
        }
        if (_selectedDisasterStatus.contains(filter)) {
          _selectedDisasterStatus.remove(filter);
        } else {
          _selectedDisasterStatus.add(filter);
        }
      }
      // 선택된 필터가 없을 시 자동으로 ALL 선택
      if (_selectedDisasterStatus.isEmpty) {
        _selectedDisasterStatus.add('ALL');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar는 main.dart에
      body: Column(
        children: [
          // 검색창, 필터 버튼 등 고정된 상단 위젯
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 검색창
                Padding(
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
                      decoration: InputDecoration(
                        hintText: '검색어를 입력해주세요',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                // 재난종류 카테고리
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 5, 16, 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...disasterCategories.map(
                              (filter) => DisasterFilterChip(
                            label: filter,
                            isSelected: _selectedDisaster.contains(filter),
                            onSelected: () => _toggleFilter(filter),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 재난상태 카테고리
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 5, 16, 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...disasterStatus.map(
                              (filter) => StatusFilterChip(
                            label: filter,
                            isSelected: _selectedDisasterStatus.contains(filter),
                            onSelected: () => _toggleStatusFilter(filter),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 지역 선택 드롭다운
                RegionDropDown(),
                SizedBox(height: 16.0),
              ],
            ),
          ),


          // 사건 리스트
          Expanded(
            child: ListView(
              children: [
                EventCard(
                  status: '진행 중',
                  date: '2024.10.03',
                  description: 'Description. Lorem ipsum dolor sit amet.',
                  backgroundColor: Colors.orange.shade100,
                  iconColor: Colors.orange,
                  icon: disasterStatusIcons['진행중'],
                ),
                EventCard(
                  status: '상황 종료',
                  date: '2024.10.03',
                  description: 'Description. Lorem ipsum dolor sit amet.',
                  backgroundColor: Colors.green.shade100,
                  iconColor: Colors.green,
                  icon: disasterStatusIcons['상황종료'],
                ),
                EventCard(
                  status: '긴급 재난',
                  date: '2024.10.03',
                  description: 'Description. Lorem ipsum dolor sit amet.',
                  backgroundColor: Colors.red.shade100,
                  iconColor: Colors.red,
                  icon: disasterStatusIcons['긴급'],
                ),
              ],
            ),
          ),
        ]
      )
    );
  }
}

// filter widget
class DisasterFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const DisasterFilterChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: onSelected,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.redAccent : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 0)
              ),
            ],
            border: Border.all(
              color: isSelected ? Colors.redAccent : Colors.grey.shade300,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Padding(
            padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StatusFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  // 각 재난 상황별 필터 색상 설정
  final Map<String, Color> disasterStatusColors = {
    'ALL': Colors.redAccent,    // 배경 빨간색
    '진행중': Colors.orange,     // 배경 주황색
    '상황종료': Colors.green,   // 배경 초록색
    '긴급': Colors.redAccent,    // 배경 빨간색 (텍스트 색상도 빨간색)
  };

  StatusFilterChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  // isSelected: selectedRegion == status,
  // backgroundColor: disasterStatusColors[status] ?? Colors.white,
  // textColor: status == '긴급' ? Colors.redAccent : Colors.white,

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: onSelected,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? disasterStatusColors[label] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 0)
              ),
            ],
            border: Border.all(
              color: isSelected ? disasterStatusColors[label]! : Colors.grey.shade300,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Padding(
            padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : disasterStatusColors[label],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// dropdown widget
class RegionDropDown extends StatefulWidget{
  @override
  _RegionDropDownState createState() => _RegionDropDownState();
}
class _RegionDropDownState extends State<RegionDropDown> {
  String? selectedRegion = 'ALL';

  final List<String> regions = [
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

  @override
  Widget build(BuildContext context){
    return Row(
      children: [
        Text('지역:'),
        SizedBox(width: 8.0),
        DropdownButton<String>(
          value: selectedRegion,
          items: regions
              .map((region) => DropdownMenuItem(
            value: region,
            child: Text(region),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              selectedRegion = value; // 선택 값 update
            });
          },
        ),
      ], // children
    );
  }
}

class EventCard extends StatelessWidget {
  final String status;
  final String date;
  final String description;
  final Color backgroundColor;
  final Color iconColor;

  const EventCard({
    required this.status,
    required this.date,
    required this.description,
    required this.backgroundColor,
    required this.iconColor, IconData? icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: iconColor,
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  '발생일시: $date',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 8.0),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
