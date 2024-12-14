import 'dart:developer' as dev;
import 'dart:convert';

import 'package:alog/models/issue.dart';
import 'package:alog/models/message.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8080/api';

  // REST API: 이슈 생성(put Issue data to db)
  Future<bool> createIssue(Issue issue) async {
    final url = Uri.parse('$baseUrl/issues/create');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(issue.toJson());
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return true;
    } else {
      dev.log('Failed to submit issue: ${response.statusCode}, ${response.body}', name: 'ApiService');
      return false;
    }
  }

  // REST API: 최근 이슈 가져오기(get Issue data from db)
  Future<List<Issue>> fetchRecentIssues() async {
    final url = Uri.parse('$baseUrl/issues/recent');
    final response = await http.get(url);

    dev.log("fetchRecentIssues", name: "ApiService");

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes); // 한글 decode
      List jsonResponse = json.decode(decodedBody);
      return jsonResponse.map((data) {
        // Issue 객체로 변환
        final issue = Issue.fromJson(data);

        return issue;
        // return Issue.fromJson(data);
      }).toList();
    } else {
      dev.log('Failed to fetch recent issues: ${response.statusCode}, ${response.body}', name: 'ApiService');
      throw Exception('Failed to load recent issues');
    }
  }

  // REST API: 최근 메시지 가져오기 (get Message data from db)
  Future<List<Message>> fetchRecentMessages() async {
    final url = Uri.parse('$baseUrl/messages/recent');
    final response = await http.get(url);

    dev.log("fetchRecentMessages", name: "ApiService");

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes); // 한글 decode
      List jsonResponse = json.decode(decodedBody);
      return jsonResponse.map((data) {
        // Message 객체로 변환
        final message = Message.fromJson(data);

        dev.log("fetchRecentMessages: $message", name: "ApiService");

        return message;
      }).toList();
    } else {
      dev.log('Failed to fetch recent messages: ${response.statusCode}, ${response.body}', name: 'ApiService');
      throw Exception('Failed to load recent messages');
    }
  }
}
