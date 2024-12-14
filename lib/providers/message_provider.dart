import 'dart:developer';

import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/api_service.dart';

class MessageProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Message> _messages = [];

  List<Message> get messages => _messages;

  Future<void> fetchRecentMessages() async {
    log("fetchRecentMessages", name: "MessageProvider");
    try {
      _messages = await _apiService.fetchRecentMessages();

      // 가져온 데이터 로그 출력
      for (var message in _messages) {
        log('Fetched Message: ${message.toJson()}', name: 'MessageProvider');
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching recent messages: $e");
    }
  }
}
