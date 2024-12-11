import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveStreamWatchScreen extends StatefulWidget {
  @override
  _LiveStreamWatchScreenState createState() => _LiveStreamWatchScreenState();
}

class _LiveStreamWatchScreenState extends State<LiveStreamWatchScreen> {
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, String>> messages = []; // 채팅 메시지 리스트

  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    // 시청자가 입장할 때 호출
    userJoined('alog화이팅', 'ls-20241203212555-vXxrx');
  }

  Future<void> _initializePlayer() async {
    const String liveStreamUrl =
        'https://github.com/SSU-ALOG/alog_application/raw/refs/heads/master/%EB%B0%A9%EC%86%A1%20%EC%8B%9C%EC%B2%AD%20%ED%99%94%EB%A9%B4%20%EC%9E%90%EB%A3%8C.mp4';
    _videoPlayerController = VideoPlayerController.network(liveStreamUrl);
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      autoPlay: true,
      looping: true,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            '스트리밍을 불러올 수 없습니다.\n$errorMessage',
            style: const TextStyle(color: Colors.red),
          ),
        );
      },
    );

    setState(() {});
  }

  @override
  void dispose() {
    // 시청자가 퇴장할 때 호출
    userLeft('alog화이팅', 'ls-20241203212555-vXxrx');
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double chatHeight = screenHeight / 3;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Positioned.fill(child: _buildVideoPlayer()), // 전체 화면 비디오 플레이어
          _buildChatSection(chatHeight), // 하단 채팅 섹션
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

  // 비디오 플레이어 섹션 분리
  Widget _buildVideoPlayer() {
    return _chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized
        ? Chewie(controller: _chewieController!)
        : const Center(
      child: Text(
        '스트리밍을 불러올 수 없습니다. URL을 확인하세요.',
        style: TextStyle(color: Colors.red),
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
                          hintStyle: TextStyle(color: Colors.black),
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
                          String messageText = _commentController.text;
                          String userId = 'alog화이팅';  // 이 값은 실제 사용자 ID로 변경
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
}


// 사용자가 방송 입장 시, Firestore에 시청자 정보를 추가
Future<void> userJoined(String userId, String channelId) async {
  try {
    await FirebaseFirestore.instance.collection('Viewers').add({
      'userId': userId,
      'channelId': channelId,
      'createdAt': FieldValue.serverTimestamp(),  // 서버 타임스탬프
    });
    print("User joined channel: $channelId");
  } catch (e) {
    print("Error adding user: $e");
  }
}

// 사용자가 방송 퇴장 시, 해당 시청자 정보를 Firestore에서 삭제u
Future<void> userLeft(String userId, String channelId) async {
  try {
    // `Viewers` 컬렉션에서 해당 유저의 문서 삭제
    var querySnapshot = await FirebaseFirestore.instance
        .collection('Viewers')
        .where('userId', isEqualTo: userId)
        .where('channelId', isEqualTo: channelId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      var documentId = querySnapshot.docs.first.id;
      await FirebaseFirestore.instance.collection('Viewers').doc(documentId).delete();
      print("User left channel: $channelId");
    }
  } catch (e) {
    print("Error removing user: $e");
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




