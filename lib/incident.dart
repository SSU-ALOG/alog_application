import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:alog/accident_detail.dart';
import 'package:alog/models/issue.dart';
import 'package:alog/services/api_service.dart';

// Disaster Categories
const List<String> disasterCategories = [
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

// Status list
const List<String> disasterStatusList = [
  'ALL',
  '진행중',
  '상황종료',
  '긴급',
];

// region list
const List<String> regions = [
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

// set ColorSet class for matching main color and shade color
class ColorSet {
  final Color main;
  final Color shade;

  const ColorSet({required this.main, required this.shade});
}

// Disaster status colors
const Map<String, ColorSet> disasterStatusColors = {
  'ALL': ColorSet(main: Color(0xFFFF6969), shade: Color(0xFFFFE2E5)),
  // 배경 빨간색
  '진행중': ColorSet(main: Color(0xFFFFB37C), shade: Color(0xFFFFF4E4)),
  // 배경 주황색
  '상황종료': ColorSet(main: Color(0xFF3AC0A0), shade: Color(0xFFE7F4E8)),
  // 배경 초록색
  '긴급': ColorSet(main: Colors.redAccent, shade: Color(0xFFFFE2E5))
  // 배경 빨간색 (텍스트 색상도 빨간색)
};

// Disaster status icons
const Map<String, IconData> disasterStatusIcons = {
  '진행중': Icons.error_rounded,
  '상황종료': Icons.check_circle,
  '긴급': Icons.circle_notifications_rounded
};

// set default event design
ColorSet getDisasterColorSet(String status) {
  return disasterStatusColors[status] ??
      ColorSet(
        main: Colors.grey,
        shade: Colors.grey.shade200,
      );
}

IconData getDisasterIcon(String status) {
  return disasterStatusIcons[status] ?? Icons.error_rounded;
}

class IncidentScreen extends StatefulWidget {
  const IncidentScreen({Key? key}) : super(key: key);

  @override
  _IncidentScreenState createState() => _IncidentScreenState();
}

// 필터링 상태
Set<String> _selectedDisaster = {'ALL'};
Set<String> _selectedDisasterStatus = {'ALL'};
String _selectedRegion = 'ALL';

class _IncidentScreenState extends State<IncidentScreen> {
  late Future<List<Issue>> futureIssues;
  final ApiService apiService = ApiService(); // ApiService 인스턴스 생성

  @override
  void initState() {
    super.initState();
    // ApiService를 통해 fetchRecentIssues 호출
    futureIssues = apiService.fetchRecentIssues();
  }

  void _toggleFilter(Set<String> selectedSet, String filter) {
    setState(() {
      if (filter == 'ALL') {
        selectedSet.clear();
        selectedSet.add('ALL');
      } else {
        if (selectedSet.contains('ALL')) selectedSet.remove('ALL');
        if (!selectedSet.add(filter)) selectedSet.remove(filter);
      }
      if (selectedSet.isEmpty) selectedSet.add('ALL');
    });
  }

  List<Issue> _applyFilters(List<Issue> issues) {
    return issues.where((issue) {
      // status
      final statusMatch = _selectedDisasterStatus.contains('ALL') ||
          _selectedDisasterStatus.contains(issue.status);

      // category
      final categoryMatch = _selectedDisaster.contains('ALL') ||
          _selectedDisaster.contains(issue.category);

      // region
      final regionMatch =
          _selectedRegion == 'ALL' || issue.addr.contains(_selectedRegion);

      return statusMatch && categoryMatch && regionMatch;
    }).toList();
  }

  // call apiservice for fetching issue data
  Future<List<Issue>> fetchAndSortIssues() async {
    final apiService = ApiService();
    List<Issue> issues = await apiService.fetchRecentIssues();

    // 가져온 데이터를 로그로 출력
    for (var issue in issues) {
      dev.log('Fetched Issue: ${issue.toJson()}', name: 'fetchAndSortIssues');
    }

    // sort by date
    return sortIssuesByDate(issues);
  }

// sort issues using date
  List<Issue> sortIssuesByDate(List<Issue> issues) {
    List<Issue> sortedIssues = List.from(issues);
    sortedIssues.sort((a, b) {
      return b.date.compareTo(a.date);
    });
    return sortedIssues;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar- main.dart
        backgroundColor: Colors.white,
        body: Column(children: [
          // upper widget: search box, category, status, and region
          _buildFilters(),

          // Accidents list
          Expanded(
            child: FutureBuilder<List<Issue>>(
              future: futureIssues, // fetchRecentIssues 호출 후 정렬 data
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Failed to load issues: ${snapshot.error}'));
                }

                final issues = snapshot.data ?? [];
                final filteredAndSortedIssues = sortIssuesByDate(_applyFilters(issues)); // filter 적용 후 정렬

                return filteredAndSortedIssues.isEmpty
                    ? Center(child: Text('해당하는 재난 정보가 없습니다.🥵'))
                    : ListView.builder(
                        itemCount: filteredAndSortedIssues.length,
                        itemBuilder: (context, index) {
                          final issue = filteredAndSortedIssues[index];
                          final colorSet = getDisasterColorSet(issue.status);
                          final icon = getDisasterIcon(issue.status);

                          return EventCard(
                            issue: issue, // Issue 객체 전달
                            backgroundColor: colorSet.shade,
                            iconColor: colorSet.main,
                            icon: icon,
                          );
                        },
                      );
              },
            ),
          ),
        ]));
  }

  // search box, disaster category, disaster status, region
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBox(),
          _buildCategoryFilter(),
          _buildStatusFilter(),
          _buildRegionDropdown(),
        ],
      ),
    );
  }

  // search box
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
          decoration: InputDecoration(
            prefix: const SizedBox(width: 20),
            hintText: '검색어를 입력해주세요',
            suffixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // disaster category
  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      child: Row(
        children: disasterCategories.map((filter) {
          return DisasterFilterChip(
            label: filter,
            isSelected: _selectedDisaster.contains(filter),
            onSelected: () => _toggleFilter(_selectedDisaster, filter),
          );
        }).toList(),
      ),
    );
  }

  // disaster status
  Widget _buildStatusFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      child: Row(
        children: disasterStatusList.map((filter) {
          return DisasterStatusFilterChip(
            label: filter,
            isSelected: _selectedDisasterStatus.contains(filter),
            onSelected: () => _toggleFilter(_selectedDisasterStatus, filter),
          );
        }).toList(),
      ),
    );
  }

  // region
  Widget _buildRegionDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<String>(
        value: _selectedRegion,
        items: regions.map((region) {
          return DropdownMenuItem(
            value: region,
            child: Text(region),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedRegion = value!;
          });
        },
      ),
    );
  }
}

// Disaster Category filter widget
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
            color: isSelected ? Color(0xFFFF6969) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 0)),
            ],
            border: Border.all(
              color: isSelected ? Color(0xFFFF6969) : Colors.grey.shade300,
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

// Disaster Status filter widget
class DisasterStatusFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  DisasterStatusFilterChip({
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
            color:
                isSelected ? disasterStatusColors[label]!.main : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 0)),
            ],
            border: Border.all(
              color: isSelected
                  ? disasterStatusColors[label]!.main
                  : Colors.grey.shade300,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Padding(
            padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : label.contains('ALL') ? Colors.black : disasterStatusColors[label]!.main,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Issue issue; // Issue 객체 전달받음
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final double iconSize;

  const EventCard(
      {required this.issue,
      required this.backgroundColor,
      required this.iconColor,
      required this.icon,
      this.iconSize = 30.0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // DetailScreen으로 navigate
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(issue: issue),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6.0,
                offset: Offset(0, 3),
              )
            ]),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: iconSize),
            SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    issue.addr,
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    '발생일시: ${issue.date.toIso8601String()}',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8.0),
                  Text(issue.description ?? 'none'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
