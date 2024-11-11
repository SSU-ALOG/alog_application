import 'dart:developer' as dev;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/issue.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8080/api';


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
}
