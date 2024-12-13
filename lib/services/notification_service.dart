import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        log('알림 클릭 response: ${response.payload}', name: "NotificationService");

        // 알림 클릭 이벤트 처리
        if (response.payload != null) {
          _handleNotificationClick(response.payload!);
        } else {
          log('Payload가 null입니다.', name: "NotificationService");
        }
      },
    );
  }

  void _handleNotificationClick(String issueId) {
    final context = navigatorKey.currentContext;

    clickedIssueId = issueId;

    Navigator.pushAndRemoveUntil(
      context!,
      MaterialPageRoute(
        builder: (context) => AppScreen(),
      ),
          (route) => false, // 이전 모든 화면 제거
    );
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

      // 위치 조건 확인
      final bool shouldNotify = await _checkLocationCondition(
        double.parse(data['latitude'] ?? '0.0'),
        double.parse(data['longitude'] ?? '0.0'),
      );

      if (shouldNotify) {
        // 로컬 알림 전송
        _sendLocalNotification(newIssue);
      } else {
        log('위치 조건을 만족하지 않아 알림을 전송하지 않음.', name: "NotificationService");
      }

      // 데이터 추가
      issueProvider.addIssue(newIssue);
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

  void _sendLocalNotification(Issue issue) async {
    final String title = '[${issue.addr}] ${issue.category} 알림! 📢';
    final String body = issue.title;

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
      payload: '${issue.issueId}',
    );

    log('로컬 알림 전송 완료: $title - $body', name: "NotificationService");
  }
}
