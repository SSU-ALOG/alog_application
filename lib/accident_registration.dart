import 'dart:developer' as dev;

import 'package:alog/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// import 'incident.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'models/issue.dart';

const List<String> disasterCategories = [
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

class AccidentRegistScreen extends StatefulWidget {
  const AccidentRegistScreen({Key? key}) : super(key: key);

  @override
  _AccidentRegistScreenState createState() => _AccidentRegistScreenState();
}

class _AccidentRegistScreenState extends State<AccidentRegistScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory = '기타';
  NLatLng? _currentLocation;
  List<String> curLocationAddr = [];
  final ApiService apiService = ApiService();
  final NLatLng defaultLocation = const NLatLng(37.4960895, 126.957504); //  후에 수정
  String repArea = '';


  // save data to db
  Future<void> _submitIssue() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치를 가져올 수 없습니다.')),
      );
      return;
    }

    final issue = Issue.fromUserInput(
      title: _titleController.text,
      category: _selectedCategory ?? '기타',
      description: _descriptionController.text,
      latitude: _currentLocation!.latitude,
      longitude: _currentLocation!.longitude,
      addr: repArea,
    );

    dev.log('issue: ${issue.toJson()}', name: '_submitIssue');

    final success = await apiService.createIssue(issue);

    dev.log('success: ${success}', name:'_submitIssue');

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('사고가 성공적으로 등록되었습니다.')));
      // Navigator.pop(context); // 홈 화면으로 돌아가기
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('등록 실패')));
    }
  }

  // get a current location
  Future<void> _setCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        // dev.log("Current Location status: $position", name: "_setCurrentLocation");
        _currentLocation = NLatLng(position.latitude, position.longitude);
        // _currentLocation = defaultLocation;
      });
    } catch (e) {
      setState(() {
        _currentLocation = defaultLocation;
      });
    }
  }

  // coordinate -> address
  Future<String?> fetchReverseGeocode(double latitude, double longitude) async {
    final url = Uri.parse(
        "https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc");

    final headers = {
      "x-ncp-apigw-api-key-id": dotenv.env['NCP_MAP_API_KEY_ID'] ?? '',
      "x-ncp-apigw-api-key": dotenv.env['NCP_MAP_API_KEY'] ?? '',
    };

    final queryParams = {
      "coords": "$longitude,$latitude",
      "output": "json",
      "orders": "legalcode,admcode,addr,roadaddr"
    };

    final response = await http.get(url.replace(queryParameters: queryParams),
        headers: headers);

    if (response.statusCode == 200) {
      // 요청 처리 성공
      final curAddr = jsonDecode(response.body);
      // print("Reverse Geocode Data: $curAddr");
      var area1 = curAddr['results'][1]['region']['area1']['name'];
      var area2 = curAddr['results'][1]['region']['area2']['name'];
      var area3 = curAddr['results'][1]['region']['area3']['name'];
      var area4 = curAddr['results'][1]['region']['area4']['name'];

      repArea= '$area1 $area2 $area3';
      print("repArea: " + repArea);

      // API 호출 결과를 TextField에 반영
      setState(() {
        // _locationController.text = location;
        curLocationAddr = [area1, area2, area3, area4];
        // print(curLocationAddr);
        _locationController.text =
            curLocationAddr.join(' '); // 요소 사이에 공백을 넣어 결합
      });
      return area1;
    } else {
      print("Failed to fetch data: ${response.statusCode}");
    }
  }

  // total
  Future<void> _fetchLocation() async {
    // 현재 위치 가져오고 coord -> addr 변환 함수 호출
    await _setCurrentLocation();
    if (_currentLocation != null) {
      await fetchReverseGeocode(
          _currentLocation!.latitude, _currentLocation!.longitude);
    } else {
      // currentLocation 가져오기 실패
      print("Failed to get a location.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: const Text(
              '사고 등록',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사고 제목
            const Text(
              '사고 제목',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13.0),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 분류
            const Text(
              '분류',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: disasterCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13.0), // 둥근 모서리 설정
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 위치
            const Text(
              '위치',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              readOnly: true, // 사용자가 직접 수정 불가
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13.0),
                ),
                hintText: '위치 가져오기',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    // 위치 가져오는 api
                    await _fetchLocation();
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 상세 내용
            const Text(
              '상세 내용',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13.0),
                ),
                hintText: 'Tell us everything.',
              ),
            ),
            const SizedBox(height: 20),

            // 등록 버튼
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85, // 화면 너비의 80%로 설정
                child: ElevatedButton(
                  onPressed: () async {
                    // 등록 기능
                    await _submitIssue();

                    // 홈화면 전환
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6969),
                    padding: const EdgeInsets.symmetric(vertical: 15), // 세로 padding만 설정
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    '등록',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // backgroundColor: Colors.white,
      // bottomNavigation Bar는 main.dart
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
