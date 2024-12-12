import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/issue.dart';
import '../providers/issue_provider.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  NotificationService() {
    // 로컬 알림 초기화
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 알림 클릭 이벤트 처리
        final payload = response.payload;
        if (payload != null) {
          _handleNotificationClick(payload);
        }
      },
    );

    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("포그라운드 메시지 수신: ${message.messageId}", name: "NotificationService");
      handleIncomingMessage(message);
    });
  }

  void _handleNotificationClick(String payload) {
    // 알림 클릭 이벤트 처리 로직
    print('알림 클릭됨, 데이터: $payload');

  }

  void handleIncomingMessage(RemoteMessage message) async {
    try {
      final data = message.data;
      final newIssue = Issue(
        issueId: int.tryParse(message.data['issueId'] ?? '0') ?? 0,
        title: message.data['title'] ?? '제목 없음',
        category: message.data['category'] ?? '카테고리 없음',
        description: message.data['description'] ?? '',
        latitude: double.tryParse(message.data['latitude'] ?? '0.0') ?? 0.0,
        longitude: double.tryParse(message.data['longitude'] ?? '0.0') ?? 0.0,
        status: message.data['status'] ?? '진행중',
        verified: message.data['verified'] == 'true',
        date: DateTime.parse(message.data['date']),
        addr: message.data['addr'] ?? '주소 없음',
      );
      final context = navigatorKey.currentContext;
      final issueProvider = Provider.of<IssueProvider>(context!, listen: false);
      issueProvider.addIssue(newIssue);

      final String notificationTitle = '[${newIssue.addr}] ${newIssue.category} 알림! 📢';
      final String notificationBody = newIssue.title;

      // 위치 조건 확인
      final bool shouldNotify = await _checkLocationCondition(
        double.parse(data['latitude'] ?? '0.0'),
        double.parse(data['longitude'] ?? '0.0'),
      );

      if (shouldNotify) {
        // 로컬 알림 전송
        _sendLocalNotification(notificationTitle, notificationBody);
      } else {
        log('위치 조건을 만족하지 않아 알림을 전송하지 않음.', name: "NotificationService");
      }
    } catch (e) {
      log('알림 처리 중 오류 발생: $e', name: "NotificationService");
    }
  }

  Future<bool> _checkLocationCondition(double issueLat, double issueLon) async {
    try {
      Position userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      log('사용자 위치: ${userPosition.latitude}, ${userPosition.longitude}', name: "NotificationService");
      log('이슈 위치: $issueLat, $issueLon', name: "NotificationService");

      double distanceInMeters = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        issueLat,
        issueLon,
      );

      return distanceInMeters <= 1000; // 1km 이내 조건
    } catch (e) {
      log('위치 조건 확인 중 오류 발생: $e', name: "NotificationService");
      return false;
    }
  }

  void _sendLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'high_importance_channel',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iOSDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _notificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );

    log('로컬 알림 전송 완료: $title - $body', name: "NotificationService");
  }
}
