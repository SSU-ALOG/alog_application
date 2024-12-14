import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'services/user_data.dart'; // UserData 클래스가 정의된 파일

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:developer';

class LiveStreamWatchScreen extends StatefulWidget {
  // 상세보기 창의 이슈번호와 제목을 받아옴
  final int? id;
  final String? title;

  const LiveStreamWatchScreen({
    Key? key,
    this.id,
    this.title,
  }) : super(key: key);


  @override
  _LiveStreamWatchScreenState createState() => _LiveStreamWatchScreenState();
}

class _LiveStreamWatchScreenState extends State<LiveStreamWatchScreen> {
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, String>> messages = []; // 채팅 메시지 리스트

  late PageController _pageController;
  late Stream<List<Map<String, dynamic>>> liveUrlsStream;
  int currentPageIndex = 0;
  String? currentChannelId;

  String? userId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    liveUrlsStream = _fetchLiveUrls(widget.id);

    userId = Provider.of<UserData>(context, listen: false).name; // 로그인된 유저 이름 가져오기
    userJoined(userId ?? 'defaultUserId', widget.id ?? 0); // 시청자가 입장할 때 호출
  }

  Stream<List<Map<String, dynamic>>> _fetchLiveUrls(int? issueId) {
    return FirebaseFirestore.instance
        .collection('ServiceUrl')
        .where('issueId', isEqualTo: issueId)
        .where('isLive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'liveUrl': data['liveUrl'],
        'channelId': data['channelId'],
      };
    }).toList());
  }

  @override
  void dispose() {
    userLeft(userId ?? 'defaultUserId', widget.id ?? 0); // 시청자가 퇴장할 때 호출
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double chatHeight = screenHeight / 3;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: liveUrlsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('현재 라이브 방송이 없습니다.'));
          }

          final liveUrls = snapshot.data!;

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: liveUrls.length,
            onPageChanged: (index) {
              setState(() {
                currentPageIndex = index;
                currentChannelId = liveUrls[index]['channelId']; // 현재 화면의 channelId 업데이트
              });
            },
            itemBuilder: (context, index) {
              final liveUrl = liveUrls[index]['liveUrl'];
              final channelId = liveUrls[index]['channelId'];
              return Stack(
                children: [
                  Positioned.fill(
                    child: _buildVideoPlayer(liveUrl),
                  ),
                  _buildChatSection(chatHeight, channelId),
                ],
              );
            },
          );
        },
      ),
    );
  }

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
        widget.title ?? '사고 제목',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Viewers')
                .where('issueId', isEqualTo: widget.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Row(
                  children: [
                    Icon(Icons.remove_red_eye, color: Colors.grey),
                    SizedBox(width: 5),
                    Text(
                      '0',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                );
              }

              int viewerCount = snapshot.data!.docs.length;

              return Row(
                children: [
                  Icon(Icons.remove_red_eye, color: Colors.grey),
                  SizedBox(width: 5),
                  Text(
                    '$viewerCount',
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

  Widget _buildVideoPlayer(String liveUrl) {
    return VideoPlayerWidget(liveUrl: liveUrl);
  }

  Widget _buildChatSection(double chatHeight, String? channelId) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: chatHeight,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Chatting')
            .where('channelId', isEqualTo: channelId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatMessages = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

          return Container(
            color: Colors.transparent,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final message = chatMessages[index];
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
                                  message['userId'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  message['text'] ?? '',
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
                              String currentUserId = userId ?? 'defaultUser';

                              sendMessage(currentUserId, channelId ?? '', messageText);

                              setState(() {
                                messages.insert(0, {
                                  'user': currentUserId,
                                  'message': messageText,
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
          );
        },
      ),
    );
  }

  Future<void> userJoined(String userId, int issueId) async {
    try {
      await FirebaseFirestore.instance.collection('Viewers').add({
        'userId': userId,
        'issueId': issueId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      log("User joined issue: $issueId");
    } catch (e) {
      log("Error adding user: $e");
    }
  }

  Future<void> userLeft(String userId, int issueId) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('Viewers')
          .where('userId', isEqualTo: userId)
          .where('issueId', isEqualTo: issueId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var documentId = querySnapshot.docs.first.id;
        await FirebaseFirestore.instance.collection('Viewers').doc(documentId).delete();
        log("User left issue: $issueId");
      }
    } catch (e) {
      log("Error removing user: $e");
    }
  }
}

Future<void> sendMessage(String userId, String channelId, String messageText) async {
  try {
    await FirebaseFirestore.instance.collection('Chatting').add({
      'userId': userId,
      'channelId': channelId,
      'text': messageText,
      'createdAt': FieldValue.serverTimestamp(),
    });
    log("Message sent to channel: $channelId");
  } catch (e) {
    log("Error sending message: $e");
  }
}


// 시청자수 반환 (마커 크기 조절시 사용)
Future<int> fetchViewerCount(String issueId) async {
  try {
    // Firestore instance 가져오기
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Viewers 컬렉션에서 issueId가 일치하는 문서 가져오기
    QuerySnapshot querySnapshot = await firestore
        .collection('Viewers')
        .where('issueId', isEqualTo: issueId)
        .get();

    // 문서 개수 반환
    return querySnapshot.docs.length;
  } catch (e) {
    // 에러 처리
    print('Error fetching viewer count: $e');
    return 0; // 에러 발생 시 0 반환
  }

  // 사용 예시
  // int viewerCount = await fetchViewerCount(issueId);
  // print('Viewer count for issueId $issueId: $viewerCount');
}

class VideoPlayerWidget extends StatefulWidget {
  final String liveUrl;

  const VideoPlayerWidget({Key? key, required this.liveUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.network(widget.liveUrl);

    try {
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
    } catch (e) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
}



