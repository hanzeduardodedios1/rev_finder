import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  // Hugging Face URL
  //final String baseUrl = 'https://hanweirdo-rev-finder-api.hf.space';
  final String baseUrl = 'https://rev-finder-api-ju8zi.ondigitalocean.app';
  
  Future<dynamic> fetchData(String endpoint) async {
    // URL Construction
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      // Make Request
      final response = await http.get(url);
      developer.log(
        'Backend status: ${response.statusCode}',
        name: 'ApiService',
      );
      developer.log(
        'Raw body: ${response.body}',
        name: 'ApiService',
      );

      if (response.statusCode == 200) {
        // Successful API response, return JSON data
        try {
          return jsonDecode(response.body);
        } catch (e) {
          developer.log(
            'JSON parse error: $e',
            name: 'ApiService',
            error: e,
          );
          rethrow;
        }
      } else if (response.statusCode == 404) {
        throw Exception("Resource not found.");
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      // Handle any network or connection errors
      throw Exception("Connection Failed: $e");
    }
  }

  /// POST JSON with Supabase JWT from [Supabase.instance.client.auth.currentSession].
  Future<http.Response> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 120),
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    if (token == null || token.isEmpty) {
      throw Exception('User not authenticated');
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    return http
        .post(url, headers: headers, body: jsonEncode(body))
        .timeout(timeout);
  }
}