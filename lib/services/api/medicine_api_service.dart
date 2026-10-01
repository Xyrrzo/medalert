import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class MedicineApiService {
  MedicineApiService._();
  static final MedicineApiService instance = MedicineApiService._();

  
  static String get _base => 
      dotenv.env['FDA_BASE_URL'] ?? 'meoww';

  Future<List<String>> suggest(String query, {int limit = 8}) async {
    if (query.trim().length < 3) return [];
    try {
      final key = dotenv.env['FDA_API_KEY'];
      final keyParam = (key != null && key.length == 40 && !key.contains('YOUR'))
          ? '&api_key=$key'
          : '';
      
      final search = Uri.encodeComponent('openfda.brand_name:$query*');
      final url = '$_base?search=$search&limit=$limit$keyParam';
      print('FDA REQUEST: $url');
      
      final data = await ApiClient.instance.getJson(url);
      final results = (data['results'] as List<dynamic>? ?? []);
      final names = <String>{};
      for (final r in results) {
        final brands = r['openfda']?['brand_name'] as List<dynamic>?;
        if (brands != null) names.addAll(brands.map((b) => b.toString()));
      }
      return names.take(limit).toList();
    } on ApiException catch (e) {
      print('FDA ERROR: ${e.message}');
      return [];
    } catch (e) {
      print('FDA UNEXPECTED: $e');
      return [];
    }
  }
}