import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:alog/providers/issue_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'streaming_sender.dart';
import 'streaming_viewer.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final Completer<NaverMapController> mapControllerCompleter = Completer();
  final DraggableScrollableController _draggableController = DraggableScrollableController();
  final NLatLng defaultLocation = const NLatLng(37.4960895, 126.957504);
  final FocusNode _searchFocusNode = FocusNode();
  final double defaultZoomLevel = 14;
  final List<NMarker> _markers = [];
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

  late double screenHeight;
  late double extraHeight;
  late double minHeightRatio;
  late double maxHeightRatio;

  OverlayEntry? _clusterInfoOverlayEntry;
  TextEditingController _searchController = TextEditingController();
  Set<String> _selectedFilters = {'ALL'};
  String _searchKeyword = '';
  double _zoomLevel = 14.0;
  double _mapRotation = 0.0;
  bool _locationPermissionGranted = false;
  bool _isExpanded = false;
  bool _isDetailView = false;
  bool _isSearching = false;
  bool _isDataLoaded = false;
  NLatLng? _currentLocation;
  Map<String, dynamic>? _selectedContent;
  List<NMarker> _searchedMarkers = [];
  List<NMarker> _filteredMarkers = [];
  List<NMarker> _clusterMarkers = [];
  List<Map<String, dynamic>> _currentContentList = [];
  List<Map<String, dynamic>> _contentList = [];

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isDataLoaded) {
      _loadData();
      _isDataLoaded = true;
    }
  }

  // IssueProvider에서 데이터 로드
  void _loadData() {
    final issueProvider = Provider.of<IssueProvider>(context, listen: false);

    issueProvider.fetchRecentIssues().then((_) {
      setState(() {
        _contentList = issueProvider.issues
            .where((issue) => issue.status != '상황종료')
            .map((issue) {
              return {
                "id": issue.issueId,
                "title": issue.title,
                "category": issue.category,
                "description": issue.description ?? "내용이 없습니다.",
                "latitude": issue.latitude,
                "longitude": issue.longitude,
                "view": 0,
                "verified": issue.verified,
              };
            }).toList();
      });

      _addContentMarkers();
      // dev.log("_contentList updated: $_contentList", name: "MapScreen");
    }).catchError((error) {
      dev.log("Error loading issues: $error", name: "MapScreen");
    });
  }

  // 위치 권한 요청
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
        _currentLocation = NLatLng(position.latitude, position.longitude);
        // _currentLocation = defaultLocation;
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
            zoom: defaultZoomLevel,
          ),
        ),
      );
      _addCurrentLocationMarker();
      _addContentMarkers();
      _calculateDistances();
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
    _markers.clear();

    for (var content in _contentList) {
      final NLatLng location = NLatLng(content['latitude'], content['longitude']);
      final int view = content['view'] ?? 10;

      double markerSize = 20 + sqrt(view);

      final marker = NMarker(
        id: '${content['id']}',
        position: location,
        icon: await NOverlayImage.fromWidget(
          context: context,
          size: Size(markerSize, markerSize),
          widget: _buildDefaultMarker(),
        ),
        anchor: NPoint(0.5, 0.5),
      );

      marker.setOnTapListener((NMarker tappedMarker) {
        setState(() {
          _selectedContent = content;
          _isDetailView = true;
        });

        Future.delayed(const Duration(milliseconds: 50), () {
          _draggableController.animateTo(
            maxHeightRatio,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ).then((_) {
            dev.log("DraggableScrollableSheet expanded by marker id: ${tappedMarker.info.id}.", name: "NMarker");
          }).catchError((error) {
            dev.log("Failed to animate DraggableScrollableSheet: $error", name: "NMarker");
          });
        });

        return true;
      });

      _markers.add(marker);
      _searchedMarkers.add(marker);
      _filteredMarkers.add(marker);
      controller.addOverlay(marker);
    }

    _applyClustering(_zoomLevel);
  }

  // 현재 위치에서 각 마커까지의 거리 정보 추가
  void _calculateDistances() {
    for (var content in _contentList) {
      final NLatLng location = NLatLng(content['latitude'], content['longitude']);
      double distance = _calculateDistance(_currentLocation!, location);
      content['distance'] = distance;
    }

    // 거리 기준으로 오름차순 정렬
    _contentList.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    setState(() {
      _currentContentList = List.from(_contentList);
    });
  }

  // 현재 위치와의 거리 계산 (단위: 킬로미터)
  double _calculateDistance(NLatLng start, NLatLng end) {
    const earthRadius = 6371; // 지구 반경 (km)

    double dLat = _degreesToRadians(end.latitude - start.latitude);
    double dLon = _degreesToRadians(end.longitude - start.longitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c; // 거리(km) 반환
  }

  // 각도를 라디안으로 변환
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // 필터
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

      _updateMarkers();
    });
  }

  // 필터에 따른 마커 업데이트
  void _updateMarkers() async {
    final controller = await mapControllerCompleter.future;
    final position = await controller.getCameraPosition();
    final currentZoomLevel = position.zoom;

    _currentContentList.clear();
    _filteredMarkers.clear();

    for (var marker in _searchedMarkers) {
      final matchingContent = _contentList.firstWhere((content) => content['title'] == marker.info.id);
      final isVisible = _selectedFilters.contains('ALL') || _selectedFilters.contains(matchingContent['category']);
      marker.setIsVisible(isVisible);

      if (isVisible) {
        _currentContentList.add(matchingContent);
        _filteredMarkers.add(marker);
      }
    }

    _applyClustering(currentZoomLevel);

    setState(() {});
  }

  // 검색
  void _performSearch() {
    setState(() {
      _isSearching = true;
      _searchFocusNode.unfocus();
      _searchKeyword = _searchController.text.toLowerCase().trim();

      _currentContentList = _contentList.where((content) {
        final title = content['title']?.toLowerCase() ?? '';
        final category = content['category']?.toLowerCase() ?? '';
        final description = content['description']?.toLowerCase() ?? '';

        return title.contains(_searchKeyword) ||
            category.contains(_searchKeyword) ||
            description.contains(_searchKeyword);
      }).toList();

      // dev.log("Current content list: $_currentContentList", name: 'Search');

      _updateMarkersForSearch();
    });
  }

  // 검색 초기화
  void _initSearch() {
    setState(() {
      _searchController.clear();
      _searchKeyword = '';
      _isSearching = false;

      _currentContentList = List.from(_contentList);
      _updateMarkersForSearch();
    });
  }

  // 검색에 따른 마커 업데이트
  void _updateMarkersForSearch() async {
    for (var marker in _markers) {
      marker.setIsVisible(false);
    }

    _searchedMarkers.clear();
    for (var content in _currentContentList) {
      final matchingMarkers = _markers.where(
              (marker) => marker.info.id == content['title']
      ).toList();

      _searchedMarkers.addAll(matchingMarkers);
    }
    _updateMarkers();
  }

  // 지도 방향 정렬
  void _resetMapRotation() async {
    final NaverMapController controller = await mapControllerCompleter.future;
    NCameraPosition cameraPosition = await controller.getCameraPosition();
    NLatLng center = cameraPosition.target;
    double zoomLevel = cameraPosition.zoom;

    controller.updateCamera(
      NCameraUpdate.fromCameraPosition(
        NCameraPosition(
          target: center,
          bearing: 0.0,
          zoom: zoomLevel,
        ),
      ),
    );
    setState(() {
      _mapRotation = 0.0;
    });
  }

  // 클러스터링
  void _applyClustering(double zoomLevel) async {
    final NaverMapController controller = await mapControllerCompleter.future;
    double clusterDistance = _getClusterDistance(zoomLevel);
    List<Cluster> clusters = _createClusters(clusterDistance);

    dev.log("current zoom level: $zoomLevel", name: "_applyClustering");

    // 기존 클러스터 마커 삭제
    for (var clusterMarker in _clusterMarkers) {
      controller.deleteOverlay(clusterMarker.info);
    }
    _clusterMarkers.clear();

    // 줌 레벨 14 이상 시 클러스터링 해제
    // if (zoomLevel >= 14) {
    //   for (var marker in _filteredMarkers) {
    //     marker.setIsVisible(true);
    //   }
    //   return;
    // }

    // 기본 마커 비활성화
    for (var marker in _filteredMarkers) {
      marker.setIsVisible(false);
    }

    // 클러스터링 적용
    for (var cluster in clusters) {
      if (cluster.markers.length == 1) {
        cluster.markers.first.setIsVisible(true);
      } else {
        final clusterCenter = cluster.position;
        double clusterSize = 40 + sqrt(cluster.markers.length) * 10;

        final clusterMarker = NMarker(
          id: 'cluster_${clusterCenter.latitude}_${clusterCenter.longitude}',
          position: clusterCenter,
          icon: await NOverlayImage.fromWidget(
            context: context,
            size: Size(clusterSize, clusterSize),
            widget: _buildClusterMarker(cluster.markers.length, clusterSize),
          ),
          anchor: NPoint(0.5, 0.5),
        );

        // 클릭 리스너
        clusterMarker.setOnTapListener((NMarker tappedMarker) async {
          final controller = await mapControllerCompleter.future;

          final adjustedPosition = NLatLng(
            cluster.position.latitude + (0.004 * (15 - zoomLevel)),
            cluster.position.longitude,
          );

          await controller.updateCamera(
            NCameraUpdate.fromCameraPosition(
              NCameraPosition(
                target: adjustedPosition,
                zoom: zoomLevel,
              ),
            ),
          );

          final NPoint screenPosition = await controller.latLngToScreenLocation(cluster.position);
          final Offset offsetPosition = Offset(screenPosition.x.toDouble(), screenPosition.y.toDouble());
          _showClusterInfoOverlay(cluster, offsetPosition, clusterSize);

          return true;
        });

        _clusterMarkers.add(clusterMarker);
        controller.addOverlay(clusterMarker);
      }
    }
  }

  // 클러스터 거리 계산
  double _getClusterDistance(double zoomLevel) {
    if (zoomLevel <= 10) return 4.0;
    if (zoomLevel <= 12) return 2.0;
    if (zoomLevel <= 13) return 0.6;
    if (zoomLevel < 14) return 0.25;
    return 0.05;
  }

  // 클러스터 생성
  List<Cluster> _createClusters(double clusterDistance) {
    List<Cluster> clusters = [];
    for (var marker in _filteredMarkers) {
      bool isClustered = false;
      for (var cluster in clusters) {
        if (_calculateDistance(cluster.position, marker.position) < clusterDistance) {
          cluster.markers.add(marker);
          isClustered = true;
          break;
        }
      }

      if (!isClustered) {
        clusters.add(Cluster(marker.position, [marker]));
      }
    }
    return clusters;
  }

  // 클러스터 마커 정보창
  void _showClusterInfoOverlay(Cluster cluster, Offset position, double clusterSize) {
    // 기존 정보창이 열려 있으면 닫기
    _closeClusterInfoOverlay();

    // 새로운 OverlayEntry 생성
    _clusterInfoOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeClusterInfoOverlay,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          Positioned(
            left: position.dx - 125,
            top: position.dy - (cluster.markers.length > 2 ? 150 : 80),
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {}, // 정보창 클릭 시 닫히지 않도록
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 정보창 본체
                    Container(
                      width: 250,
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 210,
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.fromLTRB(0, 4, 0, 4),
                              shrinkWrap: true,
                              itemCount: cluster.markers.length,
                              itemBuilder: (context, index) {
                                final content = _contentList.firstWhere(
                                      (c) => '${c['id']}' == cluster.markers[index].info.id,
                                );
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.fromLTRB(8, 0.5, 8, 0.5),
                                    dense: true,
                                    title: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            content['title'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (content['verified'] == true)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 6.0),
                                            child: Image.asset(
                                              'assets/images/verification_mark_simple.png',
                                              height: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text("분류: ${content['category']}"),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                    onTap: () {
                                      _closeClusterInfoOverlay();

                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        setState(() {
                                          _selectedContent = content;
                                          _isDetailView = true;
                                        });

                                        Future.delayed(const Duration(milliseconds: 50), () {
                                          _draggableController.animateTo(
                                            maxHeightRatio,
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          ).then((_) {
                                            dev.log("DraggableScrollableSheet expanded.", name: "NMarker");
                                          }).catchError((error) {
                                            dev.log("Failed to animate DraggableScrollableSheet: $error", name: "NMarker");
                                          });
                                        });
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 정보창 삼각형 부분
                    ClipPath(
                      clipper: TriangleClipper(),
                      child: Container(
                        color: Colors.white,
                        height: 10,
                        width: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Overlay에 추가
    Overlay.of(context).insert(_clusterInfoOverlayEntry!);
  }

  // 클러스터 마커 정보창 닫기
  void _closeClusterInfoOverlay() {
    if (_clusterInfoOverlayEntry != null) {
      _clusterInfoOverlayEntry!.remove();
      _clusterInfoOverlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    extraHeight = 158.0;
    minHeightRatio = 40 / screenHeight;
    maxHeightRatio = (screenHeight - extraHeight) / screenHeight;

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
            onCameraChange: (reason, animated) async {
              final NaverMapController controller = await mapControllerCompleter.future;
              final position = await controller.getCameraPosition();

              if (position != null) {
                // dev.log("_mapRotation: ${position.bearing}", name: "onCameraChange")
                setState(() {
                  _mapRotation = position.bearing;
                });
              }
            },
            onCameraIdle: () async {
              final position = await (await mapControllerCompleter.future).getCameraPosition();
              if (position != null) {
                if (position.zoom != _zoomLevel) {
                  _zoomLevel = position.zoom;
                  _applyClustering(position.zoom);
                }
              }
            },
          ),
          // 지도 옵션 버튼
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 나침반
                  GestureDetector(
                    onTap: _resetMapRotation,
                    child: Transform.rotate(
                      angle: -_mapRotation * (pi / 180),
                      child: Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4.0,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/compass_icon.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          )
                        // Icon(Icons.explore, color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 현재 위치 추적
                  GestureDetector(
                    onTap: _moveToCurrentLocation,
                    child: Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4.0,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Icon(Icons.my_location, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              // 검색창
              _buildSearchBar(),
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
          // 목록 시트
          DraggableScrollableSheet(
            controller: _draggableController,
            initialChildSize: minHeightRatio,
            minChildSize: minHeightRatio,
            maxChildSize: maxHeightRatio,
            snap: true,
            builder: (context, scrollController) {
              return NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  if (notification.extent == maxHeightRatio && !_isExpanded) {
                    setState(() {
                      _isExpanded = true;
                    });
                  } else if (notification.extent == minHeightRatio && _isExpanded) {
                    setState(() {
                      _isExpanded = false;
                    });
                  }
                  return true;
                },
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Container(
                    height: screenHeight - extraHeight - 163, // 106 (수정)
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
                              _draggableController.animateTo(
                                maxHeightRatio,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              setState(() {
                                _isExpanded = true;
                              });
                            } else if (details.delta.dy > 0 && _isExpanded) {
                              _draggableController.animateTo(
                                minHeightRatio,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              setState(() {
                                _isExpanded = false;
                              });
                            }
                          },
                          child: Container(
                            height: 30.9,
                            child: Center(
                              child: Container(
                                height: 5,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
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

  // 클러스터 마커 빌더
  Widget _buildClusterMarker(int count, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$count',  // 클러스터 내 마커 수 표시
          style: TextStyle(
            color: Colors.white,
            fontSize: size / 3,  // 마커 크기에 맞춰 텍스트 크기 조정
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 검색창 빌더
  Widget _buildSearchBar() {
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
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            prefix: const SizedBox(width: 20),
            hintText: '검색어를 입력해주세요',
            suffixIcon: IconButton(
              icon: Icon(
                _isSearching ? Icons.clear : Icons.search,
                color: Colors.grey,
              ),
              onPressed: _isSearching ? _initSearch : _performSearch,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: (value) {
            if (value.isEmpty) _initSearch();
          },
          onSubmitted: (value) => _performSearch(),
        ),
      ),
    );
  }

  // 콘텐츠 목록 빌더
  Widget _buildContentList(ScrollController scrollController) {
    return ListView.builder(
      controller: scrollController,
      itemCount: _currentContentList.length,
      itemBuilder: (context, index) {
        final content = _currentContentList[index];
        double distance = content['distance'] ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),

              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      content['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis, // 밑줄임 표시
                    ),
                  ),
                  // 검증 마크
                  if (content['verified'] == true)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Image.asset(
                        'assets/images/verification_mark_simple.png',
                        height: 18,
                      ),
                    ),
                ],
              ),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("분류: ${content['category']}"),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        "${distance.toStringAsFixed(1)} km",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
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
    NLatLng? contentLocation = NLatLng(_selectedContent!['latitude'], _selectedContent!['longitude']);
    bool isVerified = _selectedContent?['verified'] ?? false;
    bool isWithin1km = contentLocation != null && _currentLocation != null
        ? _calculateDistance(_currentLocation!, contentLocation) <= 1
        : false;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                child: const Icon(Icons.arrow_back, size: 30, color: Colors.black),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _selectedContent?['title'] ?? '사고 제목',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 검증 마크
                    if (isVerified)
                      Image.asset(
                        'assets/images/verification_mark.png',
                        height: 24,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 사진 또는 영상
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => LiveStreamWatchScreen()),
              );
            },
            child: Container(
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

          // 라이브 버튼
          Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: isWithin1km ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => LiveStreamStartScreen()),
                  );
                } : null, // 1km 이내일 때만 활성화, 그렇지 않으면 비활성화
                icon: const Icon(Icons.live_tv, color: Colors.white),
                label: const Text(
                  'Go Live',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
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

// 필터 칩 클래스
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

// 사용자 위치 마커 클래스
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

// 클러스터 클래스
class Cluster {
  final NLatLng position;
  final List<NMarker> markers;

  Cluster(this.position, this.markers);
}

// 삼각형 모양을 그리기 위한 클리퍼
class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}