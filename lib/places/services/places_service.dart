import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/place.dart';
import '../../services/location_service.dart';

/// PlacesService
/// - Geoapify Places API only
/// - Search attractions by radius (default 5000m)
/// - UI-agnostic
class PlacesService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.geoapify.com/v2',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  String get _apiKey {
    final key = dotenv.env['GEOAPIFY_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('Geoapify API key missing');
    }
    return key;
  }

  /// ==========================================================
  /// Search attractions by location
  ///
  /// - lat/lon: center point (optional)
  ///   - if null -> use current location
  /// - query: attraction name (optional)
  /// - categories: Geoapify categories (optional)
  /// - radius: fixed at 5000 meters
  /// ==========================================================
  Future<List<Place>> searchPlaces({
    String? query,
    double? lat,
    double? lon,
    List<String>? categories,
  }) async {
    double finalLat;
    double finalLon;

    // 🔥 DEFAULT: ใช้ตำแหน่งปัจจุบัน
    if (lat != null && lon != null) {
      finalLat = lat;
      finalLon = lon;
    } else {
      final position = await LocationService.getCurrentLocation();
      finalLat = position.latitude;
      finalLon = position.longitude;
    }

    final Map<String, dynamic> params = {
      'apiKey': _apiKey,
      'limit': 20,

      // spatial control (ตาม spec)
      'filter': 'circle:$finalLon,$finalLat,5000',
      'bias': 'proximity:$finalLon,$finalLat',
    };

    // 🔍 search by attraction name (optional)
    if (query != null && query.trim().isNotEmpty) {
      params['name'] = query.trim();
    }

    // 🏷 category filter
    if (categories != null && categories.isNotEmpty) {
      params['categories'] = categories.join(',');
    } else {
      // default attractions
      params['categories'] = 'tourism.attraction';
    }

    final response = await _dio.get(
      '/places',
      queryParameters: params,
    );

    final features = response.data['features'] as List?;
    if (features == null || features.isEmpty) {
      return [];
    }

    return features
        .map(
          (e) => Place.fromGeoapify(e as Map<String, dynamic>),
        )
        .toList();
  }
  /// ==========================================================
  /// Geocode place name -> lat/lon
  /// Example: "Tokyo, Japan"
  /// ==========================================================
    Future<({double lat, double lon})> geocodePlace(String query) async {
      final response = await _dio.get(
        'https://api.geoapify.com/v1/geocode/search', // ✅ v1 เท่านั้น
        queryParameters: {
          'text': query,
          'format': 'json', // ✅ สำคัญมาก
          'limit': 1,
          'apiKey': _apiKey,
        },
      );

      final results = response.data['results'] as List?;
      if (results == null || results.isEmpty) {
        throw Exception('Place not found');
      }

      return (
        lat: (results.first['lat'] as num).toDouble(),
        lon: (results.first['lon'] as num).toDouble(),
      );
    }
}
