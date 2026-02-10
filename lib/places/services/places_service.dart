import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/place.dart';
import '../../services/location_service.dart';

class PlacesService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.geoapify.com/v2',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<List<Place>> searchPlaces({
    required String query,
    double? lat,
    double? lon,
  }) async {
    final apiKey = dotenv.env['GEOAPIFY_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Geoapify API key missing');
    }

    double finalLat;
    double finalLon;

    // 🔥 DEFAULT = ใช้ตำแหน่งปัจจุบัน
    if (lat != null && lon != null) {
      finalLat = lat;
      finalLon = lon;
    } else {
      final position = await LocationService.getCurrentLocation();
      finalLat = position.latitude;
      finalLon = position.longitude;
    }

    final params = <String, dynamic>{
      'categories': 'tourism.attraction',
      'limit': 20,
      'apiKey': apiKey,
      // 🔥 บังคับ spatial control ตามสเปก
      'filter': 'circle:$finalLon,$finalLat,10000', // 10 km
      'bias': 'proximity:$finalLon,$finalLat',
    };

    // name เป็น optional → ใส่เฉพาะตอนมี query
    if (query.trim().isNotEmpty) {
      params['name'] = query.trim();
    }

    final response = await _dio.get(
      '/places',
      queryParameters: params,
    );

    final features = response.data['features'] as List;
    return features.map((e) => Place.fromGeoapify(e)).toList();
  }
}
