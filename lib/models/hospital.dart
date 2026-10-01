import '../services/api/hospital_api_service.dart'; 

class Hospital {
  final String name;
  final String address;
  final double lat;
  final double lon;
  final String type;
  final String? phone;
  final String? hours;
  final double? distanceKm;

  Hospital({
    required this.name,
    required this.address,
    required this.lat,
    required this.lon,
    required this.type,
    this.phone,
    this.hours,
    this.distanceKm,
  });

  factory Hospital.fromOverpass(Map<String, dynamic> e, {double? userLat, double? userLon}) {
    final tags = (e['tags'] ?? {}) as Map<String, dynamic>;
    double lat = e['lat'] ?? e['center']?['lat'] ?? 0.0;
    double lon = e['lon'] ?? e['center']?['lon'] ?? 0.0;

    final addrParts = [
      tags['addr:street'],
      tags['addr:city'],
    ].where((p) => p != null).join(', ');

    double? distance;
    if (userLat != null && userLon != null) {
      distance = HospitalApiService.calculateDistance(userLat, userLon, lat, lon);
    }

    return Hospital(
      name: tags['name'] ?? 'Unnamed facility',
      address: addrParts.isEmpty ? 'Address not available' : addrParts,
      lat: lat,
      lon: lon,
      type: tags['amenity'] ?? 'hospital',
      phone: tags['phone'] ?? tags['contact:phone'],
      hours: tags['opening_hours'],
      distanceKm: distance,
    );
  }

  String get distanceLabel {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) return '${(distanceKm! * 1000).round()} m away';
    return '${distanceKm!.toStringAsFixed(1)} km away';
  }
}