import 'dart:convert';

import 'package:alog/models/issue.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'notification_service.dart';

class WebSocketService {
  StompClient? stompClient;

  final String wsUrl = dotenv.env['WS_URL'] ?? 'ws://10.0.2.2:8080/ws';

  void initStompClient() {
    stompClient = StompClient(
      config: StompConfig(
        url: wsUrl, // WebSocket 서버 URL
        onConnect: onConnect,
        onWebSocketError: (dynamic error) =>
            print('WebSocketService: $error'),
      ),
    );
    stompClient?.activate();
    print('WebSocketService: 클라이언트 활성화');
  }

  void onConnect(StompFrame frame) {
    print('WebSocketService: 연결 성공');
    stompClient?.subscribe(
      destination: '/topic/newData', // 서버에서 브로드캐스트하는 경로
      callback: (StompFrame frame) {
        if (frame.body != null) {
          processReceivedData(frame.body!);
        }
      },
    );
  }

  void processReceivedData(String data) {
    print("WebSocketService: 데이터 수신: ${data}");
    try {
      final Map<String, dynamic> jsonData = jsonDecode(data);
      final issue = Issue.fromJson(jsonData); // JSON 데이터를 Issue 객체로 변환
      NotificationService().handleIncomingIssue(issue); // NotificationService에 전달
    } catch (e) {
      print('WebSocketService: Error processing received data: $e');
    }
  }

  void dispose() {
    stompClient?.deactivate();
    print('WebSocketService: 연결 종료');
  }
}
