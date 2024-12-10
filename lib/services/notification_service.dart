import 'package:alog/models/issue.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  }

  void handleIncomingIssue(Issue issue) async {
    final bool shouldNotify = await _checkCondition(issue);
    if (shouldNotify) {
      _sendNotification(
        '[${issue.addr}] ${issue.category} 알림! 📢',
        '${issue.title}',
      );
    }
  }

  Future<bool> _checkCondition(Issue issue) async {
    try {
      // 사용자 현재 위치 가져오기
      Position userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 거리 계산 (미터 단위)
      double distanceInMeters = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        issue.latitude,
        issue.longitude,
      );

      // 1km 이내인지 확인
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
      0, // 알림 ID
      title, // 알림 제목
      body, // 알림 내용
      notificationDetails, // 알림 설정
    );

    print('NotificationService: 알림 전송 완료($title - $body)');
  }
}
