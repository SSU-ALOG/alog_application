import 'package:flutter/material.dart';

class LiveStreamWatchScreen extends StatefulWidget {
  @override
  _LiveStreamWatchScreenState createState() => _LiveStreamWatchScreenState();
}

class _LiveStreamWatchScreenState extends State<LiveStreamWatchScreen> {
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, String>> messages = []; // 유저 이름과 메시지를 담는 리스트

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
                  child: Container(
                    color: Colors.grey[200], // 백그라운드 영역
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 채팅 메시지 리스트
                        Container(
                          height: chatHeight,  // 화면의 3분의 1로 채팅 영역 제한
                          child: ListView.builder(
                            reverse: true, // 메시지가 아래에서 위로 쌓임
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
                                      color: Colors.white.withOpacity(0.5),  // 불투명도 80%로 설정
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 유저 이름 (말풍선 첫 번째 줄)
                                        Text(
                                          messages[index]['user']!,  // 유저 이름
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.grey,  // 유저 이름은 회색으로 스타일링
                                          ),
                                        ),
                                        SizedBox(height: 0),  // 유저 이름과 메시지 사이에 간격 추가
                                        // 메시지 내용 (말풍선 두 번째 줄)
                                        Text(
                                          messages[index]['message']!,  // 메시지 내용
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black,  // 메시지는 검은색
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
                        SizedBox(height: 0),
                        // 댓글 입력창
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,  // 투명 배경
                              border: Border.all(
                                color: Colors.white,  // 흰색 테두리
                                width: 2,  // 테두리 두께
                              ),
                              borderRadius: BorderRadius.circular(20),  // 둥근 테두리
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _commentController,
                                    decoration: InputDecoration(
                                      hintText: 'Comment',  // 플레이스홀더 텍스트
                                      hintStyle: TextStyle(color: Colors.white),  // 플레이스홀더는 흰색으로 설정
                                      border: InputBorder.none,  // 기본 테두리 제거
                                      contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                                    ),
                                    style: TextStyle(color: Colors.black),  // 실제 입력되는 글씨는 검정색으로 설정
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.send, color: Colors.white),  // 흰색 전송 버튼
                                  onPressed: () {
                                    // 메시지 전송 로직
                                    if (_commentController.text.isNotEmpty) {
                                      setState(() {
                                        messages.insert(0, {
                                          'user': 'USER${messages.length + 1}', // 유저 이름 설정
                                          'message': _commentController.text,  // 메시지 내용 설정
                                        });
                                        _commentController.clear();  // 입력 후 클리어
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 0),
                      ],
                    ),
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
