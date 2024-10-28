import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  Set<String> _selectedFilters = {'ALL'};
  bool _locationPermissionGranted = false;
  NLatLng? _currentLocation;
  // bool _isPressed = false;
  bool _isExpanded = false;
  // Color _dragBarColor = Colors.grey[300]!;
  bool _isDetailView = false;
  Map<String, dynamic>? _selectedContent;

  final NLatLng defaultLocation = const NLatLng(37.4960895, 126.957504);
  final Completer<NaverMapController> mapControllerCompleter = Completer();
  final DraggableScrollableController _draggableController = DraggableScrollableController();

  final List<String> filterNames = [
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
    '기타',
  ];
  final List<Map<String, dynamic>> _contentList = [
    {"title": "사건 1", "category": "범죄", "description": "현재 라이브 스트리밍 수: 0", "location": NLatLng(37.4900895, 126.959504), "view": 10},
    {"title": "사건 2", "category": "화재", "description": "현재 라이브 스트리밍 수: 0", "location": NLatLng(37.4980895, 126.959504), "view": 50},
    {"title": "사건 3", "category": "건강위해", "description": "현재 라이브 스트리밍 수: 0", "location": NLatLng(37.4920895, 126.955504), "view": 100},
    {"title": "사건 4", "category": "안전사고", "description": "현재 라이브 스트리밍 수: 0", "location": NLatLng(37.4950895, 126.953504), "view": 150},
    {"title": "사건 5", "category": "자연재해", "description": "현재 라이브 스트리밍 수: 0", "location": NLatLng(37.4970895, 126.951504), "view": 200},

    // 1km 바깥에 있는 지점들 추가
    {"title": "사건 6", "category": "범죄", "description": "현재 라이브 스트리밍 수: 0", "location": NLatLng(37.4850895, 126.945504), "view": 5},  // 1.5km 바깥
    {"title": "사건 7", "category": "화재", "description": "현재 라이브 스트리밍 수: 0", "location": NLatLng(37.5030895, 126.960504), "view": 30}, // 1.2km 바깥
    {"title": "사건 8", "category": "건강위해", "description": "현재 라이브 스트리밍 수: 0", "location": NLatLng(37.4990895, 126.940504), "view": 70}, // 2.0km 바깥
    {"title": "사건 9", "category": "안전사고", "description": "현재 라이브 스트리밍 수: 0", "location": NLatLng(37.4800895, 126.980504), "view": 120}, // 3.0km 바깥
    {"title": "사건 10", "category": "자연재해", "description": "현재 라이브 스트리밍 수: 0", "location": NLatLng(37.4700895, 126.970504), "view": 90}, // 3.5km 바깥
  ];


  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _initializeDraggableController();
  }

  void _initializeDraggableController() {
    _draggableController.addListener(() {
      if (!_draggableController.isAttached) return;

      // 드래그가 끝날 때 위치에 따라 자동으로 열거나 닫기
      if (_draggableController.size > 0.1 && !_isExpanded) {
        _draggableController.animateTo(
          0.82,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _isExpanded = true;
      } else if (_draggableController.size <= 0.1 && _isExpanded) {
        _draggableController.animateTo(
          0.05,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _isExpanded = false;
      }
    });
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
      dev.log("Exception during permission request: $e", name: "_requestLocationPermission");
    }
  }

  // 현재 위치 가져오기
  Future<void> _setCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        dev.log("Current Location status: $position", name: "_setCurrentLocation");
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
      _addContentMarkers();
    }
  }

  // 현재 위치에 마커 추가
  void _addCurrentLocationMarker() async {
    if (_currentLocation == null) return;

    final NaverMapController controller = await mapControllerCompleter.future;

    final NOverlayImage markerIcon = await NOverlayImage.fromWidget(
      widget: const MarkerIcon(color: Colors.red),
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

  // 콘텐츠 마커 추가
  void _addContentMarkers() async {
    final NaverMapController controller = await mapControllerCompleter.future;

    for (var content in _contentList) {
      final location = content['location'] as NLatLng;
      final int view = content['view'] ?? 10;

      double markerSize = 20 + sqrt(view);

      // 마커 생성
      final marker = NMarker(
        id: content['title'], // 마커 ID를 고유하게 설정
        position: location,
        icon: await NOverlayImage.fromWidget(
          context: context,
          size: Size(markerSize, markerSize), // view 값에 따른 크기 설정
          widget: _buildDefaultMarker(),
        ),
        anchor: NPoint(0.5, 0.5), // 마커의 중심점을 기준으로 위치 설정
      );

      controller.addOverlay(marker);
    }
  }

  // 지도 중심과의 거리 계산 함수 (단위: 미터)
  double _calculateDistance(NLatLng start, NLatLng end) {
    const earthRadius = 6371; // 지구 반경 (단위: km)

    double dLat = _degreesToRadians(end.latitude - start.latitude);
    double dLon = _degreesToRadians(end.longitude - start.longitude);

    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(start.latitude)) * cos(_degreesToRadians(end.latitude)) * sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c * 1000; // km를 meter로 변환

    return distance;
  }

  // 각도를 라디안으로 변환하는 함수
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
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
              locationButtonEnable: false,
              logoClickEnable: false,
              consumeSymbolTapEvents: false,
            ),
            onMapReady: (controller) async {
              mapControllerCompleter.complete(controller);
              dev.log("onMapReady", name: "onMapReady");
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
          // 목록
          DraggableScrollableSheet(
            controller: _draggableController,
            initialChildSize: 0.05,
            minChildSize: 0.05,
            maxChildSize: 0.82,
            snap: true,
            builder: (context, scrollController) {
              return NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  if (notification.extent == 0.82 && !_isExpanded) {
                    setState(() {
                      _isExpanded = true;
                    });
                  } else if (notification.extent == 0.05 && _isExpanded) {
                    setState(() {
                      _isExpanded = false;
                    });
                  }
                  return true;
                },
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Container(
                    height: 570,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        // 드래그 바
                        GestureDetector(
                          onPanUpdate: (details) {
                            if (details.delta.dy < 0 && !_isExpanded) {
                              // 위로 드래그할 때 (시트를 열기)
                              _draggableController.animateTo(
                                0.82,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              setState(() {
                                _isExpanded = true;
                              });
                            } else if (details.delta.dy > 0 && _isExpanded) {
                              // 아래로 드래그할 때 (시트를 닫기)
                              _draggableController.animateTo(
                                0.05,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              setState(() {
                                _isExpanded = false;
                              });
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            height: 5,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _isDetailView ? _buildDetailView() : _buildContentList(scrollController),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 마커 빌더
  Widget _buildDefaultMarker() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
      ),
    );
  }

  // 콘텐츠 목록 빌더
  Widget _buildContentList(ScrollController scrollController) {
    return ListView.builder(
      controller: scrollController,
      itemCount: _contentList.length,
      itemBuilder: (context, index) {
        final content = _contentList[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10.0),
              title: Text(
                content['title'],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "category: ${content['category']}\n${content['description']}",
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                setState(() {
                  _selectedContent = content;
                  _isDetailView = true;
                });
              },
            ),
          ),
        );
      },
    );
  }

  // 상세 정보 뷰 빌더
  Widget _buildDetailView() {
    String? imageUrl = _selectedContent?['imageUrl'];
    NLatLng? contentLocation = _selectedContent?['location'];

    bool isWithin1km = contentLocation != null && _currentLocation != null
        ? _calculateDistance(_currentLocation!, contentLocation) <= 1000
        : false;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 제목
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isDetailView = false;
                  });
                },
                child: const Icon(Icons.close, size: 30, color: Colors.black),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedContent?['title'] ?? '사고 제목',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 사진 또는 영상
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              image: imageUrl != null
                  ? DecorationImage(
                image: NetworkImage(imageUrl), // 이미지 URL이 있는 경우 이미지 표시
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: imageUrl == null
                ? const Icon(
              Icons.videocam,
              size: 50,
              color: Colors.grey,
            )
                : null, // 이미지가 없는 경우
          ),
          const SizedBox(height: 16),

          // 텍스트 설명
          Text(
            "분류",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedContent?['category'] ?? '분류',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "사고 설명",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedContent?['detail'] ?? '설명 내용이 없습니다.',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5, // 줄 간격
            ),
          ),
          const SizedBox(height: 30),

          // 게시자 정보 섹션
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'USER',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '게시자 정보',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: isWithin1km ? () {
                  // 여기서 추가적인 동작을 정의
                } : null, // 1km 이내일 때만 활성화, 그렇지 않으면 null로 비활성화
                icon: const Icon(Icons.live_tv, color: Colors.white),
                label: const Text('Live'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isWithin1km ? Colors.redAccent : Colors.grey, // 활성화 상태에 따라 색상 변경
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
              color: isSelected ? Colors.red : Colors.grey.shade300,
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
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
