import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Hugging Face URL
  //final String baseUrl = 'https://hanweirdo-rev-finder-api.hf.space';
  final String baseUrl = 'http://127.0.0.1:8000';
  
  Future<dynamic> fetchData(String endpoint) async {
    // URL Construction
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      // Make Request
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Successful API response, return JSON data
        return jsonDecode(response.body);
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
}