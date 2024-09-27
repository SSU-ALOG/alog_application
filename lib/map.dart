import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Set<String> _selectedFilters = {'ALL'};

  final List<String> filterNames = [
    'ALL',
    '범죄',
    '건강위해',
    '안전사고',
    '자연재해',
    '재난',
    '동식물',
    '기타',
  ];

  void _toggleFilter(String filter) {
    setState(() {
      if (filter == 'ALL') {
        // ALL 선택 시 다른 필터를 해제
        _selectedFilters.clear();
        _selectedFilters.add('ALL');
      } else {
        // 다른 필터 선택 시 ALL 해제
        if (_selectedFilters.contains('ALL')) {
          _selectedFilters.remove('ALL');
        }
        if (_selectedFilters.contains(filter)) {
          _selectedFilters.remove(filter);
        } else {
          _selectedFilters.add(filter);
        }
      }
      // 선택된 필터가 없을 시 자동으로 ALL 선택
      if (_selectedFilters.isEmpty) {
        _selectedFilters.add('ALL');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Map(),
          Column(
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
              // 필터
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 5, 16, 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...filterNames.map(
                            (filter) => MapFilterChip(
                          label: filter,
                          isSelected: _selectedFilters.contains(filter),
                          onSelected: () => _toggleFilter(filter),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Map extends StatelessWidget {
  final Completer<NaverMapController> mapControllerCompleter = Completer();

  @override
  Widget build(BuildContext context) {
    return NaverMap(
      options: const NaverMapViewOptions(
        indoorEnable: true,
        locationButtonEnable: true,
        consumeSymbolTapEvents: false,
      ),
      onMapReady: (controller) async {
        mapControllerCompleter.complete(controller);
        log("onMapReady", name: "onMapReady");
      },
    );
  }
}

class MapFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const MapFilterChip({
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
