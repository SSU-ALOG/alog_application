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

// signiture 생성 함수
String generateSignature(String secretKey, String method, String uri, String timestamp, String accessKey) {
  var message = "$method $uri\n$timestamp\n$accessKey";
  var key = utf8.encode(secretKey);
  var bytes = utf8.encode(message);

  var hmacSha256 = Hmac(sha256, key); // HMAC-SHA256 해시 알고리즘 사용
  var digest = hmacSha256.convert(bytes);
  return base64.encode(digest.bytes);
}

// 채널 생성
Future<String?> createChannel() async {
  String accessKey = dotenv.env['ACCESS_KEY_ID'] ?? '';  // .env 파일에서 가져옴
  String secretKey = dotenv.env['SECRET_KEY'] ?? '';  // .env 파일에서 가져옴
  String method = 'POST';
  String uri = '/live-station/v1/channels';
  String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

  // 서명 생성 (예시 함수)
  String signature = generateSignature(secretKey, method, uri, timestamp, accessKey);

  // 요청 헤더 설정
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-ncp-iam-access-key': accessKey,
    'x-ncp-apigw-timestamp': timestamp,
    'x-ncp-apigw-signature-v2': signature,
  };

  // 채널 생성 요청 바디
  Map<String, dynamic> body = {
    'channelName': name,
    'useDvr': true,
    'useTimeShift': false,
    'useLowLatency': true,
    'serviceType': 'LIVE',
    'contentType': 'VOD',
    'video': {
      'protocol': 'HLS',
      'resolution': '1920x1080',
      'bitrate': '3000'
    }
  };

  var response = await http.post(
    Uri.parse('https://api.ncloud.com' + uri),
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
    // 화면의 3분의 1 높이를 계산하기 위해 MediaQuery 사용
    double screenHeight = MediaQuery.of(context).size.height;
    double chatHeight = screenHeight / 3;  // 채팅 영역을 화면의 3분의 1로 제한

    return Scaffold(
      resizeToAvoidBottomInset: true,  // 키보드가 올라올 때 화면을 자동으로 조정
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            // 뒤로 가기 로직
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
            child: Column(
              children: [
                Expanded(
                  child: enableCamera
                      ? Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(
                        color: Colors.grey, // 사용자가 정의한 색상
                        width: 3.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: Center(
                        child: _cameraPreviewWidget(), // 카메라 프리뷰 위젯
                      ),
                    ),
                  )
                      : Container(
                    color: Colors.white, // 초기화 중 흰색 배경
                    child: Center(
                      child: enableCamera
                          ? CircularProgressIndicator() // 카메라 초기화 중
                          : Text("Camera is off"), // 카메라 비활성화 상태
                    ),
                  ),
                ),
                // 채팅 및 다른 UI 요소
                Container(
                  height: chatHeight,  // 채팅 영역을 화면의 3분의 1로 제한
                  child: ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 10.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.all(10),
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
                            style: TextStyle(color: Colors.black),
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
          Positioned(
            right: 10,
            top: 10,
            child: Column(
              children: [
                IconButton(
                  icon: Icon(isStreaming ? Icons.stop : Icons.wifi_tethering),
                  onPressed: () {
                    isStreaming ? onStopStreamingButtonPressed() : onVideoStreamingButtonPressed();
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

      // 카메라를 새로 선택하는 대신, 마이크 상태만 업데이트
      await onNewCameraSelected(controller!.description); // 현재 카메라에 대한 설정을 다시 적용
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

  // 새로운 카메라를 선택하고, 선택된 카메라에 대한 초기화와 상태 변화를 UI에 반영
  Future<void> onNewCameraSelected(CameraDescription? cameraDescription) async {
    if (cameraDescription == null) return;

    if (controller != null) {
      await stopVideoStreaming();
      await controller?.dispose();
    }

    controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: enableAudio,
      androidUseOpenGL: useOpenGL,
    );

    controller!.addListener(() async {
      if (mounted) setState(() {});

      if (controller != null) {
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
            print(e);
          }
        }
      }
    });

    try {
      await controller!.initialize();
    } on CameraException catch (e) {
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
