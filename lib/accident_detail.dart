import 'package:flutter/material.dart';
import 'models/issue.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'models/short_video.dart';
import 'services/api_service.dart';

class DetailScreen extends StatefulWidget {
  final Issue issue;

  const DetailScreen({Key? key, required this.issue}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // late Future<List<ShortVideo>> _videos; // video data 가져올 future
  // late PageController _pageController; // pageview controller

  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();

    // _videos = ApiService().fetchShortVideos(widget.issue.issueId!); // API 호출
    // _pageController = PageController();
    // 테스트 환경에서는 동영상을 사용하지 않고 빈 화면
    _videoController = VideoPlayerController.asset(
      'assets/videos/snow.mp4', // 오브젝트 스토리지 URL로 교체
    )..initialize().then((_) {
        setState(() {});
        _videoController.setLooping(true); // 반복 재생
        _videoController.play(); // 재생
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    // _pageController.dispose();
    super.dispose();
  }

  String _formatDate(String isoString) {
    final dateTime = DateTime.parse(isoString);
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: FutureBuilder<List<ShortVideo>>(
      //   future: _videos,
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return Center(child: CircularProgressIndicator());
      //     } else if (snapshot.hasError) {
      //       return Center(child: Text('오류가 발생했습니다. : ${snapshot.error}'));
      //     }
      //     else if (!snapshot.hasData || snapshot.data!.isEmpty) {
      //       // short_video 데이터가 없을 경우 안내 문구 표시
      //       return Center(
      //         child: Text(
      //           "해당하는 재난 영상이 없습니다. 🥵",
      //           style: TextStyle(color: Colors.white, fontSize: 18),
      //         ),
      //       );
      //     }
      //
      //     final videos = snapshot.data!;
      //
      //     return Stack(
      //       children: [
      //         // Background videos with PageView
      //         Positioned.fill(
      //           child: PageView.builder(
      //             controller: _pageController,
      //             itemCount: videos.length,
      //             scrollDirection: Axis.vertical,
      //             itemBuilder: (context, index) {
      //               final video = videos[index];
      //               return VideoPlayerWidget(videoUrl: video.link);
      //             },
      //           ),
      //         ),

      body: Stack(
        children: [
          Container(
            color: Colors.black, // 화면 전체 검정색 배경
          ),
          // Background video
          Positioned.fill(
            // child: Container(
            //   color: Colors.black, // 테스트 환경에서 검은 배경
            // ),

            child: widget.issue.issueId == 777
                ? (_videoController.value.isInitialized
                    ? VideoPlayer(_videoController)
                    : Container(
                        color: Colors.black, // 초기 로딩 중일 때 검은 배경
                      ))
                : Center(
                    child: Container(
                      color: Colors.black, // 배경 검정색
                      child: const Text(
                        "해당하는 재난 영상이 없습니다. 🥵",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
          ),

          // Left-top: Back button
          Positioned(
            top: 16.0,
            left: 10.0,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // title, description, and category
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
              mainAxisAlignment: MainAxisAlignment.end, // 아래로 배치
              children: [
                Spacer(), // push content to the bottom

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        // status
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: widget.issue.status == "진행중"
                                ? Color(0xFFFFB37C)
                                : widget.issue.status == "긴급"
                                    ? Color(0xFFFF6969)
                                    : Color(0xFF3AC0A0),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            widget.issue.status,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.0),
                        if (widget.issue.verified)
                          Positioned(
                            top: 16.0,
                            right: 16.0,
                            child: Image.asset(
                              'assets/images/verification_mark.png',
                              width: 80,
                              height: 40,
                            ),
                          ),
                      ]),
                      SizedBox(height: 8.0),

                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.issue.title,
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 5, // 최대 5줄까지 허용
                              overflow: TextOverflow.ellipsis, // 초과 시 ...표시
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.0),

                      Row(
                        children: [
                          Text(
                            widget.issue.category,
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 8.0),
                          Text(
                            _formatDate(widget.issue.date.toIso8601String()),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.0),

                      // addr
                      Text(
                        widget.issue.addr,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      SizedBox(height: 16.0),

                      Row(children: [
                        Flexible(
                          child: Text(
                            widget.issue.description ?? "none",
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 16,
                            ),
                            maxLines: 5, // 최대 5줄까지 허용
                            overflow: TextOverflow.ellipsis, // 초과 시 ...표시
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        // );
        // },
      ),
    );
  }
}

// class VideoPlayerWidget extends StatefulWidget {
//   final String videoUrl;
//
//   const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);
//
//   @override
//   _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
// }
//
// class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
//   late VideoPlayerController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.network(widget.videoUrl)
//       ..initialize().then((_) {
//         setState(() {});
//         _controller.setLooping(true);
//         _controller.play();
//       });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return _controller.value.isInitialized
//         ? VideoPlayer(_controller)
//         : Center(child: CircularProgressIndicator());
//   }
// }
