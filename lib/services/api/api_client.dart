import 'dart:convert';
import 'package:http/http.dart' as http;


class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _client = http.Client();
  static const Duration timeout = Duration(seconds: 20);

  
  static const Map<String, String> _defaultHeaders = {
    'User-Agent': 'MedAlertApp/1.0 (Flutter; Android/iOS)',
    'Accept': 'application/json',
  };


  Future<dynamic> getJson(String url, {Map<String, String>? headers}) async {
    try {
      final response = await _client
          .get(Uri.parse(url), headers: {..._defaultHeaders, ...?headers})
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw ApiException('Server error (${response.statusCode})');
      }
      return jsonDecode(response.body);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('No internet connection or request timed out.');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}