import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/health_unit.dart';
import '../models/hospital.dart';
import '../services/api/api_client.dart';
import '../services/api/hospital_api_service.dart';
import '../services/supabase_service.dart';

class DirectoryController extends ChangeNotifier {
  final _api = HospitalApiService.instance;

  List<HealthUnit> localUnits = [];
  List<Hospital> hospitals = [];
  List<String> placeSuggestions = []; 
  bool isLoading = false;
  bool isLoadingSuggestions = false; 
  String? error;
  String locationLabel = 'Search a city or tap "Near me"';
  
 
  double? userLat;
  double? userLon;

  Future<void> loadLocalUnits() async {
    try {
      final raw = await SupabaseService.instance.getHealthUnits();
      localUnits = raw.map(HealthUnit.fromJson).toList();
    } catch (_) {
      localUnits = [];
    }
    notifyListeners();
  }

 
  Future<void> loadPlaceSuggestions(String query) async {
    if (query.trim().length < 2) {
      placeSuggestions = [];
      notifyListeners();
      return;
    }
    
    isLoadingSuggestions = true;
    notifyListeners();
    
    placeSuggestions = await _api.suggestPlaces(query);
    
    isLoadingSuggestions = false;
    notifyListeners();
  }

  void clearSuggestions() {
    placeSuggestions = [];
    notifyListeners();
  }

  Future<void> searchByCity(String city) async {
    if (city.trim().isEmpty) return;
    isLoading = true;
    error = null;
    locationLabel = city;
    placeSuggestions = []; 
    notifyListeners();
    try {
      final coords = await _api.geocode(city);
      userLat = coords[0]; 
      userLon = coords[1];
      await _fetchHospitals(coords[0], coords[1]);
    } on ApiException catch (e) {
      error = e.message;
      hospitals = [];
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> searchNearMe() async {
    isLoading = true;
    error = null;
    locationLabel = 'Locating…';
    notifyListeners();
    try {
      final pos = await _currentPosition();
      userLat = pos.latitude;
      userLon = pos.longitude;
      locationLabel = 'Near ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      await _fetchHospitals(pos.latitude, pos.longitude);
    } on ApiException catch (e) {
      error = e.message;
      hospitals = [];
    } catch (e) {
      error = 'Could not get your location. Try searching a city instead.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchHospitals(double lat, double lon) async {
    final elements = await _api.fetchNearby(lat, lon);
   
    hospitals = elements
        .map((e) => Hospital.fromOverpass(e, userLat: userLat, userLon: userLon))
        .toList();
    
 
    hospitals.sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
    
    if (hospitals.isEmpty) {
      error = 'No hospitals or clinics found in this area.';
    }
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw ApiException('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw ApiException('Location permission denied.');
    }
    return Geolocator.getCurrentPosition();
  }
}