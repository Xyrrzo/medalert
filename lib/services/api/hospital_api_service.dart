import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class HospitalApiService {
  HospitalApiService._();
  static final HospitalApiService instance = HospitalApiService._();

  
  static String get _nominatimBase => 
      dotenv.env['NOMINATIM_BASE_URL'] ?? 'meoww';
  
  static String get _overpassBase => 
      dotenv.env['OVERPASS_BASE_URL'] ?? 'meoww';
  
  static const int _radiusMeters = 8000;
  static const int _limit = 30;

  static const Map<String, String> _headers = {
    'User-Agent': 'MedAlertApp/1.0 (community health app)',
  };

  Future<List<String>> suggestPlaces(String query, {int limit = 5}) async {
    if (query.trim().length < 2) return [];
    try {
      final q = Uri.encodeComponent(query.trim());
      final data = await ApiClient.instance.getJson(
        '$_nominatimBase/search?q=$q&format=json&limit=$limit&featuretype=city&addressdetails=1',
        headers: _headers,
      ) as List<dynamic>;
      
      return data
          .map((item) {
            final address = item['address'] as Map<String, dynamic>?;
            final city = address?['city'] ?? address?['town'] ?? address?['village'] ?? item['display_name'];
            final state = address?['state'] ?? '';
            return state.isNotEmpty ? '$city, $state' : city.toString();
          })
          .toSet()
          .toList();
    } catch (e) {
      print('GEOCODE SUGGEST ERROR: $e');
      return [];
    }
  }

  Future<List<double>> geocode(String place) async {
    final q = Uri.encodeComponent(place);
    final data = await ApiClient.instance.getJson(
      '$_nominatimBase/search?q=$q&format=json&limit=1',
      headers: _headers,
    ) as List<dynamic>;
    if (data.isEmpty) throw ApiException('Place not found: "$place"');
    return [double.parse(data[0]['lat']), double.parse(data[0]['lon'])];
  }

  Future<List<Map<String, dynamic>>> fetchNearby(double lat, double lon) async {
    final query = '''
[out:json][timeout:25];
(
  node["amenity"~"hospital|clinic|doctors|pharmacy"](around:$_radiusMeters,$lat,$lon);
  way["amenity"~"hospital|clinic"](around:$_radiusMeters,$lat,$lon);
  relation["amenity"~"hospital|clinic"](around:$_radiusMeters,$lat,$lon);
);
out center $_limit;
''';
    final data = await ApiClient.instance.getJson(
      '$_overpassBase?data=${Uri.encodeComponent(query)}',
      headers: _headers,
    );
    final elements = (data['elements'] as List<dynamic>? ?? []);
    return elements
        .where((e) => e['tags']?['name'] != null)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double degree) => degree * pi / 180;
}