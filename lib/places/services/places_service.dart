import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/place.dart';
import '../../services/location_service.dart';

typedef DestinationSuggestion = ({
  String displayName,
  String city,
  String country,
  String countryCode,
  double lat,
  double lon,
});

/// ==========================================================
/// PlacesService
/// - Geoapify Places API v2
/// - Always fetch broad dataset
/// - Flutter handles filtering
/// ==========================================================
class PlacesService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.geoapify.com/v2',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
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
  /// 🔎 Search Places (NO server-side category filter)
  /// Flutter will filter locally
  /// ==========================================================
  Future<List<Place>> searchPlaces({
    String? query,
    double? lat,
    double? lon,
  }) async {
    double finalLat;
    double finalLon;

    // Use provided location or current location
    if (lat != null && lon != null) {
      finalLat = lat;
      finalLon = lon;
    } else {
      final position = await LocationService.getCurrentLocation();
      finalLat = position.latitude;
      finalLon = position.longitude;
    }

    final params = <String, dynamic>{
      'apiKey': _apiKey,
      'limit': 50,
      'categories': 'tourism,entertainment,catering,leisure',
      'filter': 'circle:$finalLon,$finalLat,5000',
      'bias': 'proximity:$finalLon,$finalLat',
    };

    if (query != null && query.trim().isNotEmpty) {
      params['name'] = query.trim();
    }

    dev.log('---- API CALL ----');
    dev.log('Lat/Lon: $finalLat / $finalLon');
    dev.log('Query: ${query ?? ""}');
    dev.log('Params: $params');

    try {
      final response = await _dio.get('/places', queryParameters: params);

      dev.log('STATUS: ${response.statusCode}');
      dev.log('RESULT COUNT: ${response.data['features']?.length ?? 0}');

      final features = response.data['features'] as List?;
      if (features == null || features.isEmpty) {
        return [];
      }

      return features
          .map((e) => Place.fromGeoapify(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      dev.log('SEARCH ERROR: $e');
      dev.log('STACK: $stack');
      rethrow;
    }
  }

  /// ==========================================================
  /// 🔍 Autocomplete suggestions
  /// ==========================================================
  Future<List<({String name, double lat, double lon})>> searchPlaceSuggestions(
    String query,
  ) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _dio.get(
        'https://api.geoapify.com/v1/geocode/autocomplete',
        queryParameters: {'text': query.trim(), 'limit': 5, 'apiKey': _apiKey},
      );

      final features = response.data['features'] as List?;
      if (features == null || features.isEmpty) return [];

      return features.map((e) {
        final props = e['properties'];
        final geometry = e['geometry'];

        return (
          name: props['formatted'] as String,
          lat: (geometry['coordinates'][1] as num).toDouble(),
          lon: (geometry['coordinates'][0] as num).toDouble(),
        );
      }).toList();
    } catch (e, stack) {
      dev.log('AUTOCOMPLETE ERROR: $e');
      dev.log('STACK: $stack');
      rethrow;
    }
  }

  Future<List<DestinationSuggestion>> searchCityCountrySuggestions(
    String query,
  ) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _dio.get(
        'https://api.geoapify.com/v1/geocode/autocomplete',
        queryParameters: {
          'text': query.trim(),
          'type': 'city',
          'limit': 8,
          'apiKey': _apiKey,
        },
      );

      final features = response.data['features'] as List?;
      if (features == null || features.isEmpty) return [];

      return features.map((e) {
        final props = e['properties'] as Map<String, dynamic>;
        final geometry = e['geometry'] as Map<String, dynamic>;
        final coordinates = geometry['coordinates'] as List;

        final city =
            (props['city'] ??
                    props['county'] ??
                    props['state'] ??
                    props['formatted'] ??
                    '')
                .toString();
        final country = (props['country'] ?? '').toString();
        final countryCode = (props['country_code'] ?? '')
            .toString()
            .toUpperCase();
        final displayName = city.isNotEmpty && country.isNotEmpty
            ? '$city, $country'
            : city;

        return (
          displayName: displayName,
          city: city,
          country: country,
          countryCode: countryCode,
          lat: (coordinates[1] as num).toDouble(),
          lon: (coordinates[0] as num).toDouble(),
        );
      }).toList();
    } catch (e, stack) {
      dev.log('DESTINATION AUTOCOMPLETE ERROR: $e');
      dev.log('STACK: $stack');
      rethrow;
    }
  }
}
