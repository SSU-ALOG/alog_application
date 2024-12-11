import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';

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

    _notificationsPlugin.initialize(settings);

    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("포그라운드 메시지 수신: ${message.messageId}");
      handleIncomingMessage(message);
    });
  }

  void handleIncomingMessage(RemoteMessage message) async {
    try {
      final data = message.data;

      // 알림 제목과 내용 생성
      final String addr = data['addr'] ?? '주소 없음';
      final String category = data['category'] ?? '카테고리 없음';
      final String title = data['title'] ?? '제목 없음';

      final String notificationTitle = '[$addr] $category 알림! 📢';
      final String notificationBody = title;

      // 위치 조건 확인
      final bool shouldNotify = await _checkLocationCondition(
        double.parse(data['latitude'] ?? '0.0'),
        double.parse(data['longitude'] ?? '0.0'),
      );

      if (shouldNotify) {
        // 로컬 알림 전송
        _sendLocalNotification(notificationTitle, notificationBody);
      } else {
        print('위치 조건을 만족하지 않아 알림을 전송하지 않음.');
      }
    } catch (e) {
      print('알림 처리 중 오류 발생: $e');
    }
  }

  Future<bool> _checkLocationCondition(double issueLat, double issueLon) async {
    try {
      Position userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('사용자 위치: ${userPosition.latitude}, ${userPosition.longitude}');
      print('이슈 위치: $issueLat, $issueLon');

      double distanceInMeters = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        issueLat,
        issueLon,
      );

      return distanceInMeters <= 1000; // 1km 이내 조건
    } catch (e) {
      print('위치 조건 확인 중 오류 발생: $e');
      return false;
    }
  }

  void _sendLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
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

    print('로컬 알림 전송 완료: $title - $body');
  }
}
