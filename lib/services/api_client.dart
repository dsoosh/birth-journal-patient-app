import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/auth.dart';
import '../models/event.dart';
import '../models/sync.dart';

class ApiClient {
  final String baseUrl;
  String? _token;

  ApiClient({required this.baseUrl});

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<JoinResponse> joinCase(String joinCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cases/join'),
      headers: _headers,
      body: jsonEncode({'join_code': joinCode}),
    );

    if (response.statusCode == 200) {
      return JoinResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Join failed: ${response.statusCode}');
  }

  Future<InitiateResponse> initiateCase() async {
    final response = await http.post(
      Uri.parse('$baseUrl/cases/initiate'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return InitiateResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Initiate failed: ${response.statusCode}');
  }

  Future<CaseStatus> getCaseStatus(String caseId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/cases/$caseId/status'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return CaseStatus.fromJson(jsonDecode(response.body));
    }
    throw Exception('Status check failed: ${response.statusCode}');
  }

  Future<SyncResponse> syncEvents(SyncRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events/sync'),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return SyncResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Sync failed: ${response.statusCode}');
  }

  Future<List<EventEnvelope>> listEvents({
    required String caseId,
    String? cursor,
    int limit = 50,
  }) async {
    final query = <String, String>{'limit': limit.toString()};
    if (cursor != null) query['cursor'] = cursor;
    final uri = Uri.parse('$baseUrl/cases/$caseId/events')
        .replace(queryParameters: query);

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final events = (data['events'] as List)
          .map((e) => EventEnvelope.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return events;
    }
    throw Exception('Events fetch failed: ${response.statusCode}');
  }
}
