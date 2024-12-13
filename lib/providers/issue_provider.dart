import 'dart:developer';

import 'package:flutter/material.dart';
import '../models/issue.dart';
import '../services/api_service.dart';

class IssueProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Issue> _issues = [];

  List<Issue> get issues => _issues;

  Future<void> fetchRecentIssues() async {

    log("fetchRecentIssues", name: "IssueProvider");
    try {
      _issues = await _apiService.fetchRecentIssues();

      // 가져온 데이터 로그 출력
      for (var issue in _issues) {
        log('Fetched Issue: ${issue.toJson()}', name: 'IssueProvider');
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching recent issues: $e");
    }
  }

  void addIssue(Issue newIssue) {
    _issues.add(newIssue);

    log('Added Issue: ${newIssue.toJson()}', name: 'IssueProvider');

    notifyListeners();
  }
}
