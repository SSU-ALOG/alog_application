import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Set<String> _selectedFilters = {'ALL'};
  bool _locationPermissionGranted = false;
  NLatLng? _currentLocation;

  final NLatLng defaultLocation = const NLatLng(37.4966895, 126.957504);
  final Completer<NaverMapController> mapControllerCompleter = Completer();
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

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  // 위치 권한 요청 및 현재 위치 설정
  Future<void> _requestLocationPermission() async {
    try {
      PermissionStatus permissionStatus = await Permission.locationWhenInUse.status;

      // log("Current permission status: $permissionStatus", name: "_requestLocationPermission");

      if (permissionStatus.isGranted) {
        // 위치 권한이 허용된 경우 현재 위치 가져오기
        _locationPermissionGranted = true;
        await _setCurrentLocation();
      } else if (permissionStatus.isDenied) {
        // 권한이 거부된 경우 권한 요청
        PermissionStatus requestedStatus = await Permission.locationWhenInUse.request();
        if (requestedStatus.isGranted) {
          _locationPermissionGranted = true;
          await _setCurrentLocation();
        }
      } else if (permissionStatus.isPermanentlyDenied) {
        // 영구적으로 권한이 거부된 경우 설정 화면으로 이동하도록 유도
        await openAppSettings();
      }

      // 권한이 부여되지 않았을 경우
      if (!_locationPermissionGranted) {
        setState(() {
          _currentLocation = defaultLocation;
        });
      }
    } catch (e) {
      log("Exception during permission request: $e", name: "_requestLocationPermission");
    }
  }

  // 현재 위치 가져오기
  Future<void> _setCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        log("Current Location status: $position", name: "_setCurrentLocation");
        // _currentLocation = NLatLng(position.latitude, position.longitude);
        _currentLocation = defaultLocation;
      });
    } catch (e) {
      setState(() {
        _currentLocation = defaultLocation;
      });
    }
    _moveToCurrentLocation();
  }

  // 지도 중심을 현재 위치로 이동
  Future<void> _moveToCurrentLocation() async {
    if (_currentLocation != null) {
      final NaverMapController controller = await mapControllerCompleter.future;
      controller.updateCamera(
        NCameraUpdate.fromCameraPosition(
          NCameraPosition(
            target: _currentLocation!,
            zoom: 14,
          ),
        ),
      );
      _addCurrentLocationMarker();
    }
  }

  // 현재 위치에 마커 추가
  void _addCurrentLocationMarker() async {
    if (_currentLocation == null) return;

    final NaverMapController controller = await mapControllerCompleter.future;

    final NOverlayImage markerIcon = await NOverlayImage.fromWidget(
      widget: const MarkerIcon(color: Colors.redAccent),
      size: const Size(40, 40),
      context: context,
    );

    final marker = NMarker(
      id: 'currentLocationMarker',
      position: _currentLocation!,
      icon: markerIcon,
    );

    controller.addOverlay(marker);
  }

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
          NaverMap(
            options: const NaverMapViewOptions(
              indoorEnable: true,
              locationButtonEnable: true,
              logoClickEnable: false,
              consumeSymbolTapEvents: false,
            ),
            onMapReady: (controller) async {
              mapControllerCompleter.complete(controller);
              log("onMapReady", name: "onMapReady");
            },
          ),
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
                      prefix: const SizedBox(width: 20),
                      hintText: '검색어를 입력해주세요',
                      suffixIcon: const Icon(Icons.search, color: Colors.grey),
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
                  padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: filterNames.map(
                          (filter) => MapFilterChip(
                        label: filter,
                        isSelected: _selectedFilters.contains(filter),
                        onSelected: () => _toggleFilter(filter),
                      ),
                    ).toList(),
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
                offset: Offset(0, 0),
              ),
            ],
            border: Border.all(
              color: isSelected ? Colors.redAccent : Colors.grey.shade300,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class MarkerIcon extends StatelessWidget {
  final Color color;

  const MarkerIcon({Key? key, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}