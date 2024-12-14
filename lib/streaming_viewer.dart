import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'services/user_data.dart'; // UserData 클래스가 정의된 파일

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:developer';

FirebaseFirestore streamingFirestore = FirebaseFirestore.instanceFor(app: Firebase.app('streamingApp'));

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
    return streamingFirestore
        .collection('ServiceUrl')
        .where('issueId', isEqualTo: issueId)
        .where('isLive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'liveUrl': data['liveUrl'],
        'channelId': data['channelId'],
        'isLive': data['isLive'], // isLive 상태도 포함
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

    return WillPopScope(
      onWillPop: () async {
        // 뒤로가기 버튼을 눌렀을 때 userLeft 호출
        if (currentChannelId != null) {
          userLeft(userId ?? 'defaultUserId', widget.id ?? 0, currentChannelId ?? '');
        }
        return true; // 뒤로 가기 동작을 허용
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(currentChannelId),
        body: StreamBuilder<List<Map<String, dynamic>>>(  // StreamBuilder로 방송 정보 받기
          stream: liveUrlsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('현재 라이브 방송이 없습니다.'));
            }

            final liveUrls = snapshot.data!;

            // 첫 번째 방송에서 채널 ID가 설정되었을 때 자동으로 시청자 수를 반영
            if (currentChannelId == null && liveUrls.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  currentChannelId = liveUrls[0]['channelId']; // 첫 번째 방송의 channelId 설정
                });

                // 시청자가 입장했을 때 호출 (첫 번째 방송에 대한 사용자 입장)
                userJoined(userId ?? 'defaultUserId', widget.id ?? 0, liveUrls[0]['channelId']);
              });
            }

            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: liveUrls.length,
              onPageChanged: (index) {
                // 현재 방송을 나가기 전 userLeft 호출
                if (currentChannelId != null) {
                  userLeft(userId ?? 'defaultUserId', widget.id ?? 0, currentChannelId ?? '');
                }

                setState(() {
                  currentPageIndex = index;
                  currentChannelId = liveUrls[index]['channelId']; // 현재 화면의 channelId 업데이트
                });

                // 시청자가 입장했을 때 호출
                userJoined(userId ?? 'defaultUserId', widget.id ?? 0, liveUrls[index]['channelId']);
              },
              itemBuilder: (context, index) {
                final liveUrl = liveUrls[index]['liveUrl'];
                final channelId = liveUrls[index]['channelId'];
                final isLive = liveUrls[index]['isLive'];

                return Stack(
                  children: [
                    // 방송 종료 여부
                    if (!isLive)
                      _buildLiveEndMessage(),

                    // 비디오 플레이어 렌더링
                    Positioned.fill(
                      child: _buildVideoPlayer(liveUrl, channelId),
                    ),

                    // 채팅 영역
                    _buildChatSection(chatHeight, channelId),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }


  // 방송 종료 메시지 위젯
  Widget _buildLiveEndMessage() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black.withOpacity(0.5),
          child: const Text(
            '방송이 종료되었습니다. 11',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String? channelId) {
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
          child: channelId == null
              ? Row(
            children: [
              Icon(Icons.remove_red_eye, color: Colors.grey),
              SizedBox(width: 5),
              Text(
                '0',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          )
              : StreamBuilder<QuerySnapshot>(
            stream: streamingFirestore
                .collection('Viewers')
                .where('channelId', isEqualTo: channelId)
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


  Widget _buildVideoPlayer(String liveUrl, String channelId) {
    return VideoPlayerWidget(liveUrl: liveUrl, channelId: channelId);
  }

  Widget _buildChatSection(double chatHeight, String? channelId) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: chatHeight,
      child: Column(
        children: [
          // 기본적으로 채팅 영역을 먼저 표시
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: streamingFirestore
                  .collection('Chatting')
                  .where('channelId', isEqualTo: channelId)
                  .orderBy('createdAt', descending: true) // 타임스탬프 기준 내림차순 정렬
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  //return const SizedBox.shrink(); // 아무것도 표시하지 않음
                  log('No chat messages available'); // 로그 찍기
                  return Container();  // 아무것도 리턴하지 않음
                }

                // 채팅 메시지들 가져오기
                final chatMessages = snapshot.data!.docs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .toList();

                return ListView.builder(
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
                );
              },
            ),
          ),

          // 메시지 입력 필드
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

                        _commentController.clear();  // 메시지 전송 후 입력창 비우기
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
  }



  Future<void> userJoined(String userId, int issueId, String channelId) async {
    try {
      // 각 파라미터 값 로그로 출력
      log("****************************** userJoined 호출 ******************************");
      log("userId: $userId");
      log("issueId: $issueId");
      log("channelId: $channelId");
      log("************************************************************");

      await streamingFirestore.collection('Viewers').add({
        'userId': userId,
        'issueId': issueId,
        'channelId' : channelId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      log("User joined channel: $channelId");
    } catch (e) {
      log("Error adding user: $e");
    }
  }

  Future<void> userLeft(String userId, int issueId, String channelId) async {
    try {
      print('&&&&&&&&&&&&&&&&&&&&&&& user left 호출 &&&&&&&&&&&&&&&&&&&&&&&');
      log("userId: $userId");
      log("issueId: $issueId");
      log("channelId: $channelId");
      log("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&");
      var querySnapshot = await streamingFirestore
          .collection('Viewers')
          .where('userId', isEqualTo: userId)
          .where('issueId', isEqualTo: issueId)
          .where('channelId', isEqualTo: channelId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var documentId = querySnapshot.docs.first.id;
        await streamingFirestore.collection('Viewers').doc(documentId).delete();
        log("User left channel: $channelId");
      }
    } catch (e) {
      log("Error removing user: $e");
    }
  }

  Future<void> sendMessage(String userId, String channelId, String messageText) async {
    try {
      await streamingFirestore.collection('Chatting').add({
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

  // 사용 예시
  // int viewerCount = await fetchViewerCount(issueId);
  // print('Viewer count for issueId $issueId: $viewerCount');
}

class VideoPlayerWidget extends StatefulWidget {
  final String liveUrl;
  final String channelId;

  const VideoPlayerWidget({Key? key, required this.liveUrl, required this.channelId}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isPlaying = true;  // 방송이 재생 중인지 여부
  bool _isRemovingViewers = false; // 시청자 삭제 작업 여부 확인

  //FirebaseFirestore streamingFirestore = FirebaseFirestore.instanceFor(app: Firebase.app('streamingApp'));

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
              '방송이 종료되었습니다. 새로고침 해주세요.', // 스트리밍 url이 유효하지 않은 경우 (방송 종료)
              style: const TextStyle(color: Colors.red),
            ),
          );
        },
      );
      setState(() {});
    } catch (e) {
      setState(() {
        _isPlaying = false;  // 스트리밍 오류 발생 시 비디오 정지 상태
      });
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // if the stream has been stopped, dispose of the player
    if (widget.liveUrl != oldWidget.liveUrl) {
      _disposePlayer();  // URL이 변경되면 비디오 플레이어를 정리
      _initializePlayer(); // 새로운 URL로 비디오 초기화
    }
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  // 비디오 플레이어 정리 함수
  void _disposePlayer() {
    if (_chewieController != null) {
      _chewieController!.dispose();
    }
    if (_videoPlayerController != null) {
      _videoPlayerController.dispose();
    }
  }

  // 방송 종료 시 시청자 삭제 함수 호출
  // Future<void> _removeViewersAndDisplayMessage() async {
  //   if (!_isRemovingViewers) {
  //     setState(() {
  //       _isRemovingViewers = true; // 시청자 삭제 작업 진행 중
  //     });
  //
  //     // 시청자 삭제 함수 호출
  //     await removeViewers(widget.channelId);
  //
  //     // 삭제가 완료된 후 메시지 표시
  //     setState(() {
  //       _isPlaying = false; // 방송이 종료되었음을 표시
  //     });
  //   }
  // }
  //
  // Future<void> removeViewers(String channelId) async {
  //   try {
  //     log("@@@@@@@@@@@@@@@@@@@@@@@@@ removeViewers 호출 @@@@@@@@@@@@@@@@@@@@@@@@@@@@");
  //     // 해당 channelId를 가진 모든 시청자 삭제
  //     QuerySnapshot snapshot = await streamingFirestore
  //         .collection('Viewers')
  //         .where('channelId', isEqualTo: channelId)
  //         .get();
  //
  //     for (var doc in snapshot.docs) {
  //       await streamingFirestore.collection('Viewers').doc(doc.id).delete();
  //       log("Removed viewer from channel: $channelId");
  //     }
  //   } catch (e) {
  //     log("Error removing viewers: $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    if (!_isPlaying) {
      // 방송이 종료되었으면 removeViewers() 호출 후 메시지 표시
      //_removeViewersAndDisplayMessage();

      return Center(
        child: Text(
          '방송이 종료되었습니다.',
          style: TextStyle(color: Colors.red, fontSize: 18),
        ),
      );
    }

    return _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
        ? Chewie(controller: _chewieController!)
        : const Center(child: CircularProgressIndicator());
  }
}

// 시청자수 반환 (마커 크기 조절시 사용)
Future<int> fetchViewerCount(int issueId) async {
  try {
    // Viewers 컬렉션에서 issueId가 일치하는 문서 가져오기
    QuerySnapshot querySnapshot = await streamingFirestore
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

