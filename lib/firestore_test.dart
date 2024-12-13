import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveStreamWatchScreen extends StatefulWidget {
  final String? id;

  const LiveStreamWatchScreen({Key? key, this.id}) : super(key: key);

  @override
  _LiveStreamWatchScreenState createState() => _LiveStreamWatchScreenState();
}

class _LiveStreamWatchScreenState extends State<LiveStreamWatchScreen> {
  // Firestore에서 데이터를 가져오는 함수
  Future<DocumentSnapshot> getServiceURLByIssueId(int issueId) async {
    try {
      // ServiceURL 컬렉션에서 issueId가 일치하는 문서를 가져옵니다.
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ServiceURL')
          .where('issueId', isEqualTo: issueId)  // issueId로 필터링
          .limit(1)  // 첫 번째 문서만 가져오기
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first;  // 첫 번째 문서를 반환
      } else {
        throw Exception('No document found with the given issueId');
      }
    } catch (e) {
      print("Error fetching service URL: $e");
      rethrow;  // 에러를 상위로 던짐
    }
  }

  // ServiceURL 컬렉션의 모든 문서를 실시간으로 가져오는 Stream
  Stream<QuerySnapshot> getAllServiceURLs() {
    return FirebaseFirestore.instance
        .collection('ServiceURL')  // ServiceURL 컬렉션
        .snapshots();  // 실시간으로 문서들을 가져옵니다
  }

  // Future 함수로 데이터를 가져오는 예시
  void fetchServiceURL() async {
    try {
      int issueId = 123;  // 예시 issueId
      DocumentSnapshot document = await getServiceURLByIssueId(issueId);

      print('Fetched document: ${document['liveUrl']}');
    } catch (e) {
      print("Error fetching service URL: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchServiceURL();  // 화면 초기화 시 데이터를 가져오는 함수 호출
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live Stream Watch')),
      body: StreamBuilder<QuerySnapshot>(
        stream: getAllServiceURLs(),  // ServiceURL 컬렉션의 모든 문서를 실시간으로 가져옴
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());  // 데이터 로딩 중
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No data available"));  // 데이터가 없으면 표시
          }

          // 모든 문서를 처리하고 로그에 출력하기
          var serviceURLs = snapshot.data!.docs;
          for (var serviceURL in serviceURLs) {
            var createdAt = serviceURL['createdAt'];
            var isLive = serviceURL['isLive'];
            var issueId = serviceURL['issueId'];
            var liveUrl = serviceURL['liveUrl'];
            var thumbnailUrl = serviceURL['thumbnailUrl'];

            print('Issue ID: $issueId');
            print('Created At: $createdAt');
            print('Is Live: $isLive');
            print('Live URL: $liveUrl');
            print('Thumbnail URL: $thumbnailUrl');
            print('--------------------------------------');
          }

          return ListView.builder(
            itemCount: serviceURLs.length,
            itemBuilder: (context, index) {
              var serviceURL = serviceURLs[index];
              var issueId = serviceURL['issueId'];
              var thumbnailUrl = serviceURL['thumbnailUrl'];

              return ListTile(
                title: Text('Issue ID: $issueId'),
                subtitle: Text('Thumbnail: $thumbnailUrl'),
                trailing: Icon(Icons.remove_red_eye),
              );
            },
          );
        },
      ),
    );
  }
}
