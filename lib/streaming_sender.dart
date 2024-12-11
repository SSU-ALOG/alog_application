import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'main.dart';

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:rtmp_broadcaster/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// signiture 생성 함수
String generateSignature(String secretKey, String method, String uri, String timestamp, String accessKey) {
  var message = "$method $uri\n$timestamp\n$accessKey";
  var key = utf8.encode(secretKey);
  var bytes = utf8.encode(message);

  var hmacSha256 = Hmac(sha256, key); // HMAC-SHA256 해시 알고리즘 사용
  var digest = hmacSha256.convert(bytes);
  return base64.encode(digest.bytes);
}

// 화질 세트 목록 조회
Future<void> getQualitySet() async {
  String accessKey = dotenv.env['ACCESS_KEY_ID'] ?? '';
  String secretKey = dotenv.env['SECRET_KEY'] ?? '';
  String method = 'GET';
  String uri = '/api/v2/qualitySets?genType=CUSTOM&type=default';
  String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

  // 서명(Signature) 생성
  String signature = generateSignature(secretKey, method, uri, timestamp, accessKey);

  // 요청 헤더 설정
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-ncp-apigw-timestamp': timestamp,
    'x-ncp-iam-access-key': accessKey,
    'x-ncp-apigw-signature-v2': signature,
    'x-ncp-region_code': 'KR',
  };

  String host = 'livestation.apigw.ntruss.com';
  // 쿼리 파라미터 설정
  Map<String, String> queryParams = {
    'genType': 'CUSTOM',
    'type': 'default',
  };

  // 요청 URL 생성
  //final url = Uri.https(host, uri, queryParams);
  final url = Uri.https(host, '/api/v2/qualitySets', {'genType': 'CUSTOM', 'type': 'default'});

  // GET 요청 보내기
  final response = await http.get(url, headers: headers);

  if (response.statusCode == 200) {
    print("Quality Set data: ${response.body}");
  } else {
    print("Failed to retrieve quality set: ${response.statusCode}");
    print("Error details: ${response.body}");
  }
}

// CDN 리스트의 ProfilesID를 가져오기
Future<void> listProfiles() async {
  String accessKey = dotenv.env['ACCESS_KEY_ID'] ?? '';
  String secretKey = dotenv.env['SECRET_KEY'] ?? '';
  String uri = '/api/v1/profiles';
  String method = "GET";
  String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

  // 시그니처 생성
  String signature = generateSignature(secretKey, method, uri, timestamp, accessKey);

  // 요청 헤더 설정
  final headers = {
    'Content-Type': 'application/json',
    'x-ncp-apigw-timestamp': timestamp,
    'x-ncp-iam-access-key': accessKey,
    'x-ncp-apigw-signature-v2': signature,
  };

  String host = 'edge.apigw.ntruss.com';
  final url = Uri.https(host, uri);

  try {
    // GET 요청 보내기
    final response = await http.get(url, headers: headers);

    // 응답 처리
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print("프로필 목록 조회 성공: $responseData");
    } else {
      print("프로필 목록 조회 실패: ${response.statusCode}");
      print("에러 메시지: ${response.body}");
    }
  } catch (e) {
    print("요청 중 오류 발생: $e");
  }
}

// global edge의 cdnInstanceNo 알아내기
Future<void> listGlobalEdges() async {

  String profileId = "2389";

  String accessKey = dotenv.env['ACCESS_KEY_ID'] ?? '';
  String secretKey = dotenv.env['SECRET_KEY'] ?? '';
  String uri = '/api/v1/profiles/$profileId/cdn-edges';
  String method = "GET";
  String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

  // 시그니처 생성
  String signature = generateSignature(secretKey, method, uri, timestamp, accessKey);

  // 요청 헤더 설정
  final headers = {
    'Content-Type': 'application/json',
    'x-ncp-apigw-timestamp': timestamp,
    'x-ncp-iam-access-key': accessKey,
    'x-ncp-apigw-signature-v2': signature,
  };

  String host = 'edge.apigw.ntruss.com';
  final url = Uri.https(host, uri);

  try {
    // GET 요청 보내기
    final response = await http.get(url, headers: headers);

    // 응답 처리
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print("Global Edge 목록 조회 성공: $responseData");
    } else {
      print("Global Edge 목록 조회 실패: ${response.statusCode}");
      print("에러 메시지: ${response.body}");
    }
  } catch (e) {
    print("요청 중 오류 발생: $e");
  }
}

// 채널 생성
Future<String?> createChannel() async {
  String accessKey = dotenv.env['ACCESS_KEY_ID'] ?? '';  // .env 파일에서 가져옴
  String secretKey = dotenv.env['SECRET_KEY'] ?? '';  // .env 파일에서 가져옴
  String method = 'POST';
  String uri = '/api/v2/channels';
  String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

  // 서명 생성 (예시 함수)
  String signature = generateSignature(secretKey, method, uri, timestamp, accessKey);

  // 요청 헤더 설정
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-ncp-iam-access-key': accessKey,
    'x-ncp-apigw-timestamp': timestamp,
    'x-ncp-apigw-signature-v2': signature,
    'x-ncp-region_code': 'KR',
  };

  // 채널 생성 요청 바디
  Map<String, dynamic> body = {
    // cdn 미생성
    "channelName" : "testchannel5",
    "cdn" : {
      "createCdn" : false,
      "cdnType": "GLOBAL_EDGE",
      "cdnDomain": "pendecky6003.edge.naverncp.com",
      "profileId": 2389,
      "cdnInstanceNo": 6003
    },
    "qualitySetId" : 4329, // 4329
    "useDvr" : true,
    "immediateOnAir" : true,
    "timemachineMin" : 360,
    "envType" : "DEV",
    "outputProtocol" : "HLS",
    "record": {
      "type": "AUTO_UPLOAD",
      "format": "MP4",
      "bucketName": "alog-streaming",
      "filePath": "/livestation",
      "accessControl": "PRIVATE"
    },
    "isStreamFailOver": true,
    "drmEnabledYn": false,
    /*
    // cdn 생성
    "channelName" : "testchannel1",
    "cdn" : {
      "createCdn":true,
      "cdnType":"GLOBAL_EDGE",
      "profileId" : 2389,
      "regionType" : "KOREA"
    },
    "qualitySetId" : 4329, // 4329
    "useDvr" : true,
    "immediateOnAir" : true,
    "timemachineMin" : 360,
    "envType" : "DEV",
    "outputProtocol" : "HLS",
    "record": {
      "type": "AUTO_UPLOAD",
      "format": "MP4",
      "bucketName": "alog-streaming",
      "filePath": "/livestation",
      "accessControl": "PRIVATE"
    },
    "isStreamFailOver": true,
    "drmEnabledYn": false,
    */
  };

  // HTTP 요청
  try {
    var url = Uri.https('livestation.apigw.ntruss.com', '/api/v2/channels');
    var response = await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);

      // 전체 응답 데이터 출력
      //debugPrint('전체 응답 데이터: ${responseData.toString()}');

      // content 내부에서 channelId 찾기
      if (responseData.containsKey('content') && responseData['content'].containsKey('channelId')) {
        String channelId = responseData['content']['channelId'];
        debugPrint('채널 생성 성공 - channelId: $channelId');
        return channelId;
      } else {
        debugPrint('응답에 channelId가 없습니다.');
        return '채널 생성 성공 (하지만 channelId 없음)';
      }
    } else {
      debugPrint('채널 생성 실패: 상태 코드 ${response.statusCode}');
      debugPrint('응답 메시지: ${response.body}');
      return '채널 생성 실패';
    }
  } catch (e) {
    debugPrint('예외 발생: $e');
    return '채널 생성 중 예외 발생';
  }
}

Future<String?> getStreamKey(String? channelId) async {
  // Naver Cloud API 인증 정보
  String accessKey = dotenv.env['ACCESS_KEY_ID'] ?? ''; // .env 파일에서 가져옴
  String secretKey = dotenv.env['SECRET_KEY'] ?? ''; // .env 파일에서 가져옴
  String method = 'GET';
  String uri = '/api/v2/channels/$channelId';
  String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

  // 서명 생성 (예시 함수)
  String signature = generateSignature(secretKey, method, uri, timestamp, accessKey);

  // 요청 헤더 설정
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-ncp-iam-access-key': accessKey,
    'x-ncp-apigw-timestamp': timestamp,
    'x-ncp-apigw-signature-v2': signature,
    'x-ncp-region_code': 'KR',
  };

  // HTTP 요청
  try {
    var url = Uri.https('livestation.apigw.ntruss.com', '/api/v2/channels/$channelId');
    var response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);

      // 전체 응답 데이터 출력
      debugPrint('채널 정보 전체 응답 데이터: ${responseData.toString()}');

      // content 내부에서 streamKey 찾기
      if (responseData.containsKey('content') && responseData['content'].containsKey('streamKey')) {
        String streamKey = responseData['content']['streamKey'];
        debugPrint('채널 정보 조회 성공 - streamKey: $streamKey');
        return streamKey;
      } else {
        debugPrint('응답에 streamKey가 없습니다.');
        return null;
      }
    } else {
      debugPrint('채널 정보 조회 실패: 상태 코드 ${response.statusCode}');
      debugPrint('응답 메시지: ${response.body}');
      return null;
    }
  } catch (e) {
    debugPrint('예외 발생: $e');
    return null;
  }
}

// 채널 삭제
Future<bool> deleteChannel(String? channelId) async {
  String accessKey = dotenv.env['ACCESS_KEY_ID'] ?? '';  // .env 파일에서 가져옴
  String secretKey = dotenv.env['SECRET_KEY'] ?? '';     // .env 파일에서 가져옴
  String method = 'DELETE';
  String uri = '/api/v2/channels/$channelId';
  String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

  // 서명 생성 (예시 함수)
  String signature = generateSignature(secretKey, method, uri, timestamp, accessKey);

  // 요청 헤더 설정
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-ncp-iam-access-key': accessKey,
    'x-ncp-apigw-timestamp': timestamp,
    'x-ncp-apigw-signature-v2': signature,
    'x-ncp-region_code': 'KR',
  };

  try {
    var url = Uri.https('livestation.apigw.ntruss.com', uri);
    var response = await http.delete(url, headers: headers);

    if (response.statusCode == 200) {
      debugPrint('채널 삭제 성공: $channelId');
      return true; // 성공적으로 삭제
    } else {
      debugPrint('채널 삭제 실패: 상태 코드 ${response.statusCode}');
      debugPrint('응답 메시지: ${response.body}');
      return false; // 삭제 실패
    }
  } catch (e) {
    debugPrint('채널 삭제 중 예외 발생: $e');
    return false; // 삭제 실패
  }
}

// 방송 상태 정보 조회
Future<Map<String, dynamic>?> getChannelInfo(String? channelId) async {
  String accessKey = dotenv.env['ACCESS_KEY_ID'] ?? ''; // .env 파일에서 가져옴
  String secretKey = dotenv.env['SECRET_KEY'] ?? ''; // .env 파일에서 가져옴
  String method = 'GET';
  String uri = '/api/v2/vod/channels/$channelId';
  String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

  // 서명 생성 (서명 생성 함수는 별도로 구현)
  String signature = generateSignature(secretKey, method, uri, timestamp, accessKey);

  // 요청 헤더 설정
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-ncp-iam-access-key': accessKey,
    'x-ncp-apigw-timestamp': timestamp,
    'x-ncp-apigw-signature-v2': signature,
    'x-ncp-region_code': 'KR',
  };

  try {
    // API 요청 URL 생성
    var url = Uri.https('livestation.apigw.ntruss.com', uri);
    var response = await http.get(url, headers: headers);

    debugPrint("Request URL: $url");
    // 응답 처리
    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      return responseData;  // 채널 정보 응답 반환
    } else {
      print('VOD 채널 정보 조회 실패: 상태 코드 ${response.statusCode}');
      print('응답 메시지: ${response.body}');
      return null;
    }
  } catch (e) {
    print('VOD 채널 정보 조회 중 예외 발생: $e');
    return null;
  }
}

// ServiceUrl 추출
Future<String?> getServiceUrl(String? channelId) async {
  String accessKey = dotenv.env['ACCESS_KEY_ID'] ?? '';  // .env 파일에서 가져옴
  String secretKey = dotenv.env['SECRET_KEY'] ?? '';     // .env 파일에서 가져옴
  String method = 'GET';
  String uri = '/api/v2/channels/$channelId/serviceUrls?serviceUrlType=GENERAL';
  String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

  // 서명 생성
  String signature = generateSignature(secretKey, method, uri, timestamp, accessKey);

  // 요청 헤더 설정
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-ncp-iam-access-key': accessKey,
    'x-ncp-apigw-timestamp': timestamp,
    'x-ncp-apigw-signature-v2': signature,
    'x-ncp-region_code': 'KR',
  };

  String define = '/api/v2/channels/$channelId/serviceUrls';
  // VOD 타입 파라미터
  Map<String, dynamic> queryParams = {
    'serviceUrlType': 'GENERAL',
  };

  try {
    // 요청 URL 설정
    var url = Uri.https('livestation.apigw.ntruss.com', define, queryParams);
    var response = await http.get(url, headers: headers);

    // 디버깅 로그
    debugPrint("Request URL: $url");
    debugPrint("Response status: ${response.statusCode}");
    debugPrint("Response body: ${response.body}");

    if (response.statusCode == 200) {
      // 응답에서 "name": "720p-16-9"에 해당하는 URL만 추출
      var responseData = jsonDecode(response.body);
      // debugPrint('전체 응답 데이터: $responseData');
      var contentList = responseData['content'] as List;

      // "name": "720p-16-9"에 해당하는 URL을 찾음
      for (var item in contentList) {
        if (item['name'] == '720p-9-16') {
          String ServiceUrl = item['url'];
          debugPrint('Service URL: $ServiceUrl');
          return ServiceUrl;  // "720p-16-9"에 해당하는 URL 반환
        }
      }
      debugPrint('720p-9-16 URL을 찾을 수 없습니다.');
      return null;
    } else {
      debugPrint('서비스 URL 요청 실패: 상태 코드 ${response.statusCode}');
      return null;
    }
  } catch (e) {
    debugPrint('서비스 URL 요청 중 예외 발생: $e');
    return null;
  }
}

// 썸네일 추출
Future<String?> getThumbnailUrl(String? channelId) async {
  String accessKey = dotenv.env['ACCESS_KEY_ID'] ?? '';  // .env 파일에서 가져옴
  String secretKey = dotenv.env['SECRET_KEY'] ?? '';     // .env 파일에서 가져옴
  String method = 'GET';
  String uri = '/api/v2/channels/$channelId/serviceUrls?serviceUrlType=THUMBNAIL';
  String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

  // 서명 생성
  String signature = generateSignature(secretKey, method, uri, timestamp, accessKey);

  // 요청 헤더 설정
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-ncp-iam-access-key': accessKey,
    'x-ncp-apigw-timestamp': timestamp,
    'x-ncp-apigw-signature-v2': signature,
    'x-ncp-region_code': 'KR',
  };

  String define = '/api/v2/channels/$channelId/serviceUrls';
  // VOD 타입 파라미터
  Map<String, dynamic> queryParams = {
    'serviceUrlType': 'THUMBNAIL',
  };

  try {
    // 요청 URL 설정
    var url = Uri.https('livestation.apigw.ntruss.com', define, queryParams);
    var response = await http.get(url, headers: headers);

    // 디버깅 로그
    debugPrint("Request URL: $url");
    debugPrint("Response status: ${response.statusCode}");
    debugPrint("Response body: ${response.body}");

    if (response.statusCode == 200) {
      // 응답에서 "content" 리스트 추출
      var responseData = jsonDecode(response.body);
      var contentList = responseData['content'] as List;

      // 첫 번째 항목의 URL을 가져옴
      if (contentList.isNotEmpty) {
        String thumbnailUrl = contentList[0]['url'];  // 첫 번째 항목의 URL
        debugPrint('Thumbnail URL: $thumbnailUrl');
        return thumbnailUrl;  // 첫 번째 URL 반환
      } else {
        debugPrint('content 리스트가 비어 있습니다.');
        return null;
      }
    } else {
      debugPrint('썸네일 URL 요청 실패: 상태 코드 ${response.statusCode}');
      return null;
    }
  } catch (e) {
    debugPrint('썸네일 URL 요청 중 예외 발생: $e');
    return null;
  }
}

// Firestore 데이터 추가 -  방송 시작 시 입력
Future<void> addBroadcast(String issueId, String liveUrl, String thumbnailUrl) async {
  try {
    await FirebaseFirestore.instance.collection('ServiceURL').add({
      'issueId': issueId,
      'liveUrl': liveUrl,
      'thumbnailUrl': thumbnailUrl,
      'isLive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('방송 정보가 Firestore에 추가되었습니다.');
  } catch (e) {
    print('Firestore에 데이터를 추가하는 중 오류가 발생했습니다: $e');
  }
}

// Firestore - 방송 종료 시 방송여부 FALSE로 변경
Future<void> endBroadcast(String documentId) async {
  await FirebaseFirestore.instance.collection('ServiceURL').doc(documentId).update({
    'isLive': false,
  });
}


// Declare the camera descriptions globally
List<CameraDescription> cameras = [];

class LiveStreamStartScreen extends StatefulWidget {
  @override
  _LiveStreamStartScreenState createState() => _LiveStreamStartScreenState();
}

void logError(String code, String message) => print('Error: $code\nError Message: $message');

class _LiveStreamStartScreenState extends State<LiveStreamStartScreen> with WidgetsBindingObserver {
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, String>> messages = []; // 유저 이름과 메시지를 담는 리스트

  CameraController? controller;
  String? url;
  VideoPlayerController? videoController;
  VoidCallback? videoPlayerListener;
  bool enableAudio = true;
  bool enableCamera = true; // 카메라가 활성화되었는지를 나타내는 변수
  bool useOpenGL = true;
  TextEditingController _textFieldController = TextEditingController(text: "rtmp://rtmp-ls2-k1.video.media.ntruss.com:8080/relay");

  bool isVisible = true;

  String? channelId;

 // bool get isControllerInitialized => controller?.value.isInitialized ?? false;
  bool get isStreaming => controller?.value.isStreamingVideoRtmp ?? false;
  bool get isStreamingVideoRtmp => controller?.value.isStreamingVideoRtmp ?? false;
  bool get isRecordingVideo => controller?.value.isRecordingVideo ?? false;

  bool _isControllerInitialized = false;
  bool get isControllerInitialized => controller?.value.isInitialized ?? _isControllerInitialized;
  set isControllerInitialized(bool value) {
    setState(() {
      _isControllerInitialized = value;
    });
  }


  @override
  void initState() {
    super.initState();
    initializeCamera();  // 카메라 초기화를 initState에서 호출
    WidgetsBinding.instance.addObserver(this);
  }

  void initializeCamera() async {
    final cameras = await availableCameras();
    controller = CameraController(
      cameras[0], // 첫 번째 카메라 선택
      ResolutionPreset.high,
      enableAudio: true, // 오디오 활성화
    );
    await controller!.initialize();
    setState(() {
      isControllerInitialized = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (controller == null || !isControllerInitialized) {
      return;
    }
    if (state == AppLifecycleState.paused) {
      isVisible = false;
      if (isStreaming) {
        await pauseVideoStreaming();
      }
    } else if (state == AppLifecycleState.resumed) {
      isVisible = true;
      if (controller != null) {
        if (isStreaming) {
          await resumeVideoStreaming();
        } else {
          onNewCameraSelected(controller!.description);
        }
      }
    }
  }

  // 앱이 백->포그라운드로 돌아왔을 때 스트리밍 재개
  Future<void> resumeVideoStreaming() async {
    if (!isStreaming) {
      return null;
    }

    try {
      await controller!.resumeVideoStreaming();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 위젯 분리
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double chatHeight = screenHeight / 3;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Positioned.fill(child: _buildCameraPreview()),
          _buildChatSection(chatHeight),
          _buildActionButtons(),
        ],
      ),
    );
  }

  // AppBar 분리
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: Text(
        '사고 제목',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          // Chatting 컬렉션을 실시간으로 구독하여, 채팅을 화면에 표시
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Viewers')
                .where('channelId', isEqualTo: 'ls-20241203212555-vXxrx')  // 특정 채널에 대한 시청자 정보
                .snapshots(),  // 실시간으로 데이터 스트림을 받아옵니다.
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Row(
                  children: [
                    Icon(Icons.remove_red_eye, color: Colors.grey),
                    SizedBox(width: 5),
                    Text(
                      '0',  // 데이터를 아직 못 받았을 때는 0으로 표시
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                );
              }

              // 실시간으로 시청자 수를 받아와서 표시합니다.
              int viewerCount = snapshot.data!.docs.length;

              return Row(
                children: [
                  Icon(Icons.remove_red_eye, color: Colors.grey),
                  SizedBox(width: 5),
                  Text(
                    '$viewerCount',  // 시청자 수 표시
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // 카메라 화면 분리
  Widget _buildCameraPreview() {
    return enableCamera
        ? Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: Colors.grey,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Center(
          child: _cameraPreviewWidget(),
        ),
      ),
    )
        : Container(
      color: Colors.white,
      child: Center(
        child: enableCamera
            ? CircularProgressIndicator()
            : Text("Camera is off"),
      ),
    );
  }

  // 채팅 영역 분리
  Widget _buildChatSection(double chatHeight) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: chatHeight,
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 10.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                        margin: EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              messages[index]['user']!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              messages[index]['message']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Comment',
                          hintStyle: TextStyle(color: Colors.white),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        if (_commentController.text.isNotEmpty) {
                          String messageText = _commentController.text;
                          String userId = 'user123';  // 이 값은 실제 사용자 ID로 변경
                          String channelId = 'ls-20241203212555-vXxrx';  // 해당 방송의 채널 ID

                          // sendMessage 함수 호출
                          sendMessage(userId, channelId, messageText);

                          setState(() {
                            messages.insert(0, {
                              'user': userId,
                              'message': messageText,
                            });
                            _commentController.clear();  // 메시지 전송 후 입력 필드 비우기
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 방송 시작 시 documentId 받아오기
  String? documentId;  // documentId를 로컬 변수로 저장

  Future<void> _startBroadcast(String issueId, String liveUrl, String thumbnailUrl) async {
    try {
      // Firestore에 방송 정보 저장
      var docRef = await FirebaseFirestore.instance.collection('ServiceURL').add({
        'issueId': issueId,         // Firestore에 issueId 저장
        'liveUrl': liveUrl,        // 방송 URL
        'thumbnailUrl': thumbnailUrl, // 썸네일 URL
        'isLive': true,             // 방송 상태는 true
        'createdAt': FieldValue.serverTimestamp(),  // 생성 시간
      });

      // 문서의 고유 ID를 로컬에 저장 (documentId)
      documentId = docRef.id;

      print("Broadcast started, documentId: ${docRef.id}");
    } catch (e) {
      print("Error starting broadcast: $e");
    }
  }

  // 방송 종료 시, firestore의 isLive가 true -> false로 변동
  Future<void> stopBroadcast() async {
    try {
      if (documentId != null) {
        // documentId를 사용하여 Firestore에서 isLive를 false로 업데이트
        await FirebaseFirestore.instance
            .collection('ServiceURL')
            .doc(documentId)  // 로컬에 저장된 documentId로 문서 찾기
            .update({
          'isLive': false,  // 방송 종료 시 isLive를 false로 설정
        });

        print("Broadcast stopped, isLive set to false.");
      } else {
        print("Error: documentId is null.");
      }
    } catch (e) {
      print("Error stopping broadcast: $e");
    }
  }

  // 오른쪽 액션 버튼 분리
  Widget _buildActionButtons() {
    return Positioned(
      right: 10,
      top: 70,
      child: Column(
        children: [
          IconButton(
            icon: Icon(isStreaming ? Icons.stop : Icons.wifi_tethering,
              color: isStreaming ? Colors.red : Colors.grey,),
            onPressed: () async {
              //getQualitySet();
              //listProfiles();
              //listGlobalEdges();
              //requestGlobalCdnPurge();
              //await getVodChannelInfo('ls-20241203210109-tUNel');

              if (isStreaming) {
                // 스트리밍 종료 팝업
                bool shouldStop = await _showStopStreamingDialog(context);
                if (shouldStop) {
                  await stopVideoStreaming();

                  //await Future.delayed(Duration(seconds: 5)); // 5초 대기
                  //deleteChannel(channelId);
                  await stopBroadcast();  // 방송 종료 시 stopBroadcast 호출
                  setState(() {}); // 상태 갱신
                }
              } else {
                // 스트리밍 시작
                //String? finalUrl = await startVideoStreaming(); // startVideoStreaming 호출
                String? channelId = await startVideoStreaming();

                //await Future.delayed(Duration(seconds: 5));

                if (channelId != null) {
                  setState(() {});
                  // 방송 정보를 Firestore에 저장
                  //await Future.delayed(Duration(seconds: 10));
                  //debugPrint("************************************ Channel ID: $channelId ************************************ ");

                  //await getVodChannelInfo(channelId);
                  String ServiceUrl = await getServiceUrl(channelId) ?? ''; // 송출 url 조회
                  String thumbnailUrl = await getThumbnailUrl(channelId) ?? ''; // 썸네일 URL 조회
                  String? issueId = '1';
                  await _startBroadcast(issueId, ServiceUrl, thumbnailUrl);  // 방송 시작 후 documentId 업데이트

                  debugPrint("Streaming started with URL: $ServiceUrl");
                } else {
                  debugPrint("Failed to start streaming.");
                }
              }
            },
          ),
          SizedBox(height: 10),
          IconButton(
            icon: Icon(enableAudio ? Icons.mic : Icons.mic_off, size: 30),
            onPressed: toggleMic,
          ),
          SizedBox(height: 10),
          IconButton(
            icon: Icon(enableCamera ? Icons.videocam : Icons.videocam_off, size: 30),
            onPressed: toggleCamera,
          ),
          SizedBox(height: 10),
          IconButton(
            icon: Icon(Icons.switch_camera, size: 30),
            onPressed: switchCamera,
          ),
        ],
      ),
    );
  }

  // 방송 종료 여부 팝업
  Future<bool> _showStopStreamingDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('방송 종료'),
          content: Text('방송을 종료하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // "아니오" 선택
              },
              child: Text('아니오'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // "예" 선택
              },
              child: Text('예'),
            ),
          ],
        );
      },
    ) ?? false; // null 방지
  }

  // 카메라 초기화 후 미리보기
  Widget _cameraPreviewWidget() {
    //double aspectRatio = 3 / 4; // 원하는 비율로 설정

    if (controller == null || !isControllerInitialized) {
      return const Text(
        'Loading the camera',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: controller!.value.aspectRatio,
      //aspectRatio: aspectRatio,
      child: CameraPreview(controller!),
    );
  }

  // 마이크 on/off
  void toggleMic() async {
    //enableAudio = !enableAudio; // 마이크 상태 토글
    // 카메라 상태는 유지하고, 마이크 상태만 변경
    if (controller != null) {
      // 현재 상태에 따라 처리
      if (enableAudio) {
        setState(() {
          enableAudio = false;
        });
        print("Mic turned off");
      } else {
        setState(() {
          enableAudio = true;
        });
        print("Mic turned on");
      }

      // 권한 요청
      //await requestPermissions();

      // 카메라를 새로 선택하는 대신, 마이크 상태만 업데이트
      //await onNewCameraSelected(controller!.description); // 현재 카메라에 대한 설정을 다시 적용
    }
  }

  Future<void> getCameras() async {
    cameras = await availableCameras(); // 카메라 리스트 가져오기
  }

  // 카메라 on/off
  void toggleCamera() async {
    await getCameras(); // 카메라 리스트 업데이트

    if (enableCamera) {
      await controller?.dispose();
      setState(() {
        enableCamera = false;
      });
      print('Camera turned off');
    } else {
      if (cameras.isNotEmpty) {
        await onNewCameraSelected(cameras.first);
        setState(() {
          enableCamera = true;
        });
        print('Camera turned on');
      } else {
        print('No available cameras');
      }
    }
  }

  // 카메라 전/후면 전환
  void switchCamera() async {
    if (controller == null || cameras.isEmpty) {
      print('No camera available');
      return;
    }

    final currentCameraIndex = cameras.indexOf(controller!.description);
    final newCameraIndex = (currentCameraIndex + 1) % cameras.length;

    // 새 카메라 선택 (await 사용 가능)
    await onNewCameraSelected(cameras[newCameraIndex]);

    setState(() {});
    print('Switched to ${cameras[newCameraIndex].lensDirection == CameraLensDirection.front ? 'front' : 'back'} camera');
  }



  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> requestPermissions() async {
    // 카메라 권한 요청
    if (!await Permission.camera.request().isGranted) {
      print('Camera permission not granted');
      return;
    }

    // 마이크 권한 요청 (오디오 활성화 시 필요)
    if (enableAudio && !await Permission.microphone.request().isGranted) {
      print('Microphone permission not granted');
      return;
    }
  }

  // 새로운 카메라를 선택하고, 선택된 카메라에 대한 초기화와 상태 변화를 UI에 반영
  Future<void> onNewCameraSelected(CameraDescription? cameraDescription) async {
    if (cameraDescription == null) return;
    print('11111');

    if (controller != null) {
      await stopVideoStreaming();
      await controller?.dispose();
      print('22222');
    }

    controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: enableAudio,
      androidUseOpenGL: useOpenGL,
    );

    print('33333');

    controller!.addListener(() async {
      if (mounted) setState(() {});

      print('44444');

      if (controller != null) {
        print('55555');
        if (controller!.value.hasError) {
          print('Camera error ${controller!.value.errorDescription}');
          await stopVideoStreaming();
        } else {
          try {
            final Map<dynamic, dynamic> event = controller!.value.event as Map<dynamic, dynamic>;
            print('Event $event');
            final String eventType = event['eventType'] as String;
            if (isVisible && isStreaming && eventType == 'rtmp_retry') {
              print('BadName received, endpoint in use.');
              await stopVideoStreaming();
            }
          } catch (e) {
            print('66666');
            print(e);
          }
        }
      }
    });

    try {
      await controller!.initialize();
      print('카메라 초기화 완료');
    }
    on CameraException catch (e) {
      print('Camera initialization failed: $e');
      print('Error details: ${e.description}');
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }

  }

  // 스트리밍 시작
  void onVideoStreamingButtonPressed() {
    startVideoStreaming().then((String? url) {
      if (mounted) setState(() {});
      print('Streaming video to $url');
      WakelockPlus.enable();
    });
  }

// 스트리밍 종료
  Future<void> onStopStreamingButtonPressed() async {
    await stopVideoStreaming(); // 스트리밍 중지 대기
    if (mounted) {
      setState(() {});
    }
    debugPrint('Video not streaming to: $url');
  }

  // URL을 입력할 수 있는 AlertDialog를 표시하고, 사용자가 입력한 URL을 반환
    Future<String> _getUrl(String streamKey) async {
      // 기본 URL
      String baseUrl = "rtmp://rtmp-ls2-k1.video.media.ntruss.com:8080/relay";
      // 완성된 URL
      String result = "$baseUrl/$streamKey";


      return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Url to Stream to'),
            content: TextField(
              controller: _textFieldController..text = result,
              decoration: InputDecoration(hintText: "방송 시작"),
              onChanged: (String str) => result = str,
            ),
            actions: <Widget>[
              TextButton(
                child: new Text(MaterialLocalizations.of(context).cancelButtonLabel),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
                onPressed: () {
                  Navigator.pop(context, result);
                },
              )
            ],
          );
        });
  }

  //먼저 이전 스트리밍 세션을 중지하고, 카메라가 초기화되었는지 확인한 후, 사용자로부터 스트리밍할 URL을 입력받음
  // 입력받은 URL을 사용하여 controller!.startVideoStreaming(url!)을 통해 실시간으로 영상을 스트리밍
  Future<String?> startVideoStreaming() async {
    // 기존 스트리밍 중지
    await stopVideoStreaming();

    // 카메라 컨트롤러가 초기화되었는지 확인
    if (controller == null) {
      debugPrint('Error: Camera controller is not initialized.');
      return null;
    }

    if (!isControllerInitialized) {
      debugPrint('Error: Camera is not selected or initialized.');
      return null;
    }

    // 이미 스트리밍 중인지 확인
    if (controller?.value.isStreamingVideoRtmp ?? false) {
      debugPrint('Warning: Already streaming.');
      return null;
    }

    // RTMP URL 생성
    String myUrl;
    try {
      // URL 생성 (AlertDialog 호출)
      channelId = await createChannel(); // 채널 생성
      if (channelId == null) {
        debugPrint('Error: Failed to create a channel.');
        return null;
      }

      // 채널 정보를 사용하여 스트림 키 가져오기
      String? streamKey = await getStreamKey(channelId);
      if (streamKey == null) {
        debugPrint('Error: Failed to fetch stream key for channel: $channelId');
        return null;
      }

      // 스트림 키를 사용하여 RTMP URL 생성
      myUrl = await _getUrl(streamKey);
      debugPrint('Generated streaming URL: $myUrl');
    } catch (e) {
      debugPrint('Error generating RTMP URL: $e');
      return null;
    }

    // 스트리밍 시작
    try {
      url = myUrl; // URL 저장

      // 비디오 스트리밍 시작
      await controller!.startVideoStreaming(
        url!,
        bitrate: 1200000, // 권장 비트레이트 설정
      );

      debugPrint('Video streaming started successfully at URL: $url');
    } on CameraException catch (e) {
      debugPrint('Error starting video streaming: ${e.description}');
      _showCameraException(e); // 에러 처리
      return null;
    }

    // 성공적으로 시작된 송출 URL 반환
    //return url;
    return channelId;
  }

  Future<void> stopVideoStreaming() async {
    if (controller == null || !isControllerInitialized) {
      return;
    }
    if (!isStreamingVideoRtmp) {
      return;
    }

    try {
      await controller!.stopVideoStreaming();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  Future<void> pauseVideoStreaming() async {
    if (!isStreamingVideoRtmp) {
      return null;
    }

    try {
      await controller!.pauseVideoStreaming();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description ?? "No description found");
    print('Error: ${e.code}\n${e.description ?? "No description found"}');
  }
}

// 채팅 메시지를 Firestore에 전송하고 실시간으로 받아옴
Future<void> sendMessage(String userId, String channelId, String messageText) async {
  try {
    await FirebaseFirestore.instance.collection('Chatting').add({
      'userId': userId,
      'channelId': channelId,
      'text': messageText,
      'createdAt': FieldValue.serverTimestamp(),  // 메시지 전송 시간
    });
    print("Message sent");
  } catch (e) {
    print("Error sending message: $e");
  }
}
