import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Hugging Face URL
  final String baseUrl = 'https://hanweirdo-rev-finder-api.hf.space';
  
  Future<dynamic> fetchData(String endpoint) async {
    // 1. Build URL
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      // 2. Make Request
      final response = await http.get(url);

      // 3. Handle Responses
      if (response.statusCode == 200) {
        // Successfully fetched data, return the decoded JSON payload
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception("Resource not found.");
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      // 4. Handle Network/Connection Errors
      throw Exception("Connection Failed: $e");
    }
  }
}