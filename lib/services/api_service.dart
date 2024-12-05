import 'dart:developer' as dev;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/issue.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8080/api';

  // API call method: put Issue data to db
  Future<bool> createIssue(Issue issue) async {
    final url = Uri.parse('$baseUrl/issues/create');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(issue.toJson());

    dev.log('${issue}', name: 'ApiService');

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return true;
    } else {
      dev.log('Failed to submit issue: ${response.statusCode}, ${response.body}', name: 'ApiService');
      return false;
    }
  }

  // API call method: get Issue data from db
  Future<List<Issue>> fetchRecentIssues() async {
    final url = Uri.parse('$baseUrl/issues/recent');
    dev.log('Fetching recent issues from $url', name: 'ApiService');

    final response = await http.get(url);
    // dev.log('Response body: ${response.body}', name: 'fetchRecentIssues');

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes); // 한글 decode
      List jsonResponse = json.decode(decodedBody);
      // dev.log('Decoded JSON Response: $jsonResponse', name: 'fetchRecentIssues');
      return jsonResponse.map((data) {
        // log로 확인할 데이터 출력
        // dev.log('Mapping data: $data', name: 'fetchRecentIssues');

        // Issue 객체로 변환
        final issue = Issue.fromJson(data);

        // 디버깅용 로그 출력
        dev.log('Parsed Issue: ${issue.toJson()}', name: 'fetchRecentIssues');

        return issue;
        // return Issue.fromJson(data);
      }).toList();
    } else {
      dev.log('Failed to fetch recent issues: ${response.statusCode}, ${response.body}', name: 'ApiService');
      throw Exception('Failed to load recent issues');
    }
  }
}
