import 'package:flutter/material.dart';
import 'models/issue.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';

class DetailScreen extends StatefulWidget {
  final Issue issue;

  const DetailScreen({Key? key, required this.issue}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  String _formatDate(String isoString) {
    final dateTime = DateTime.parse(isoString);
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background video
          Positioned.fill(
            // child: Container(
            //   color: Colors.black, // 테스트 환경에서 검은 배경
            // ),

            child: _videoController.value.isInitialized
                ? VideoPlayer(_videoController)
                : Container(
                    color: Colors.black, // 초기 로딩 중일 때 검은 배경
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

          // // Right-top: verified
          // if (widget.issue.verified)
          //   Positioned(
          //     top: 16.0,
          //     right: 16.0,
          //     child: Image.asset(
          //       'assets/images/verification_mark.png',
          //       width: 80,
          //       height: 40,
          //     ),
          //   ),

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

                      Row(
                        children: [
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
                    ] ),
                      SizedBox(height: 8.0),

                      Text(
                        widget.issue.title,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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

                      Text(
                        widget.issue.description ?? "none",
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
