import 'package:alog/models/issue.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  NotificationService() {
    // 초기화
    final initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    _notificationsPlugin.initialize(initializationSettings);

    // FCM 메시지 수신 핸들러 등록
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleIncomingMessage(message);
    });
  }

  Future<void> _handleIncomingMessage(RemoteMessage message) async {
    try {
      // FCM 데이터 파싱
      final data = message.data;
      final issue = Issue(
        issueId: null,
        title: data['title'] ?? '제목 없음',
        category: data['category'] ?? '기타',
        description: null,
        latitude: double.parse(data['latitude']),
        longitude: double.parse(data['longitude']),
        date: DateTime.now(),
        status: '진행중',
        verified: false,
        addr: data['addr'] ?? '주소 없음',
      );

      // 위치 조건 확인
      final bool shouldNotify = await _checkCondition(issue);
      if (shouldNotify) {
        _sendNotification(
          '[${issue.addr}] ${issue.category} 알림! 📢',
          '${issue.title}',
        );
      }
    } catch (e) {
      print('NotificationService: 메시지 처리 중 오류 발생 - $e');
    }
  }

  Future<bool> _checkCondition(Issue issue) async {
    try {
      Position userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double distanceInMeters = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        issue.latitude,
        issue.longitude,
      );

      if (distanceInMeters <= 1000) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('NotificationService: $e');
      return false;
    }
  }

  void _sendNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iOSDetails = DarwinNotificationDetails();
    const notificationDetails =
    NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await _notificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );

    print('NotificationService: 알림 전송 완료($title - $body)');
  }
}
