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

// signiture 생성 함수
String generateSignature(String secretKey, String method, String uri, String timestamp, String accessKey) {
  var message = "$method $uri\n$timestamp\n$accessKey";
  var key = utf8.encode(secretKey);
  var bytes = utf8.encode(message);

  var hmacSha256 = Hmac(sha256, key); // HMAC-SHA256 해시 알고리즘 사용
  var digest = hmacSha256.convert(bytes);
  return base64.encode(digest.bytes);
}

Future<void> getQualitySet() async {
  String accessKey = dotenv.env['ACCESS_KEY_ID'] ?? '';
  String secretKey = dotenv.env['SECRET_KEY'] ?? '';
  String method = 'GET';
  String uri = '/api/v2/qualitySets';
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
  // 요청 URL 생성 (genType과 channelType을 쿼리 파라미터로 추가)
  final url = Uri.https(host, uri);

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
  String uri = '/cdn/v2/getGlobalCdnInstanceList';
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

  String host = 'ncloud.apigw.gov-ntruss.com';
  final url = Uri.https(host, uri);

  try {
    // GET 요청 보내기
    final response = await http.get(url, headers: headers);

    // 응답 처리
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print("Global CDN 인스턴스 목록 조회 성공: $responseData");
    } else {
      print("Global CDN 인스턴스 목록 조회 실패: ${response.statusCode}");
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
    "channelName" : "testchannel",
    "cdn" : {
      "createCdn" : false,
      "cdnType": "GLOBAL_EDGE",
      "cdnDomain": "wsarscro4796.edge.naverncp.com",
      "profileId": 2389,
      "cdnInstanceNo": 4796
    },
    "qualitySetId" : 8,
    "useDvr" : false,
    "immediateOnAir" : true,
    //"timemachineMin" : 360,
    "envType" : "DEV",
    "outputProtocol" : "HLS",
    "record": {
      "type": "AUTO_UPLOAD",
      "format": "MP4",
      "bucketName": "alog-streaming",
      "filePath": "/livestation",
      "accessControl": "PRIVATE"
    },
    "isStreamFailOver": false,
    "drmEnabledYn": false,
    // "drm": {
    //   "siteId": "drm-20231115142326-nHyNw",
    //   "contentId": "my-Test-Multidrm"
    // }
  };

  var response = await http.post(
    Uri.parse('https://livestation.apigw.ntruss.com' + uri),
    headers: headers,
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    var responseBody = jsonDecode(response.body);
    String channelId = responseBody['channelId'];
    print('채널 생성 성공: $channelId');
    return channelId;  // 생성된 채널 ID 반환
  } else {
    print('채널 생성 실패: ${response.statusCode}');
    print('Error details: ${response.body}');  // 서버 응답 내용 출력
    return null;
  }
}

// Naver Live Streaming API 요청
Future<void> startLiveStream(String channelId) async {
  String accessKey = dotenv.env['ACCESS_KEY_ID'] ?? '';  // .env 파일에서 가져옴
  String secretKey = dotenv.env['SECRET_KEY'] ?? '';  // .env 파일에서 가져옴
  String method = 'POST';
  String uri = '/live-station/v1/channels/$channelId/start';  // 채널 ID에 따라 방송 시작
  String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

  // 서명 생성
  String signature = generateSignature(secretKey, method, uri, timestamp, accessKey);

  // 요청 헤더 설정
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-ncp-iam-access-key': accessKey,
    'x-ncp-apigw-timestamp': timestamp,
    'x-ncp-apigw-signature-v2': signature,
  };

  var response = await http.post(
    Uri.parse('https://api.ncloud.com' + uri),
    headers: headers,
  );

  if (response.statusCode == 200) {
    print('방송 시작 성공');
  } else {
    print('방송 시작 실패: ${response.statusCode}');
  }
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

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double chatHeight = screenHeight / 3; // 채팅 영역 높이 설정

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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
            child: Row(
              children: [
                Icon(Icons.remove_red_eye, color: Colors.grey),
                SizedBox(width: 5),
                Text(
                  '1245',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: enableCamera
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
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: chatHeight,
            child: Container(
              color: Colors.transparent, // 완전 투명 배경 설정
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
                              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 6), // 내부 여백 줄이기
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
                                setState(() {
                                  messages.insert(0, {
                                    'user': 'USER${messages.length + 1}',
                                    'message': _commentController.text,
                                  });
                                  _commentController.clear();
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
          ),
          Positioned(
            right: 10,
            top: 70,
            child: Column(
              children: [
                IconButton(
                  icon: Icon(isStreaming ? Icons.stop : Icons.wifi_tethering),
                  onPressed: () {
                    //getQualitySet();
                    //listProfiles();
                    //createChannel();
                    //isStreaming ? onStopStreamingButtonPressed() : onVideoStreamingButtonPressed();
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
          ),
        ],
      ),
    );
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
  void onStopStreamingButtonPressed() {
    stopVideoStreaming().then((_) {
      if (mounted) setState(() {});
      print('Video not streaming to: $url');
    });
  }

  // URL을 입력할 수 있는 AlertDialog를 표시하고, 사용자가 입력한 URL을 반환
  Future<String> _getUrl() async {
    // Open up a dialog for the url
    String result = _textFieldController.text;

    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Url to Stream to'),
            content: TextField(
              controller: _textFieldController,
              decoration: InputDecoration(hintText: "Url to Stream to"),
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
    await stopVideoStreaming();
    if (controller == null) {
      return null;
    }
    if (!isControllerInitialized) {
      print('Error: select a camera first.');
      return null;
    }

    if (controller?.value.isStreamingVideoRtmp ?? false) {
      return null;
    }

    // Open up a dialog for the url
    String myUrl = await _getUrl();

    try {
      url = myUrl;
      await controller!.startVideoStreaming(url!);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return url;
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
