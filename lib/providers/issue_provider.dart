import 'dart:developer';

import 'package:flutter/material.dart';
import '../models/issue.dart';
import '../services/api_service.dart';

// 데이터 사용시 아래와 같이 작성
// final issues = Provider.of<IssueProvider>(context).issues;

class IssueProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Issue> _issues = [];

  List<Issue> get issues => _issues;

  Future<void> fetchRecentIssues() async {
    try {
      _issues = await _apiService.fetchRecentIssues();

      // 가져온 데이터 로그 출력
      for (var issue in _issues) {
        log('Fetched Issue: ${issue.toJson()}', name: 'IssueProvider');
      }

      notifyListeners(); // 데이터 변경 알림
    } catch (e) {
      debugPrint("Error fetching recent issues: $e");
    }
  }
}
