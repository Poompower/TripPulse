import 'dart:developer' as developer;

import 'package:dio/dio.dart';

class CurrentWeather {
  final int temperatureC;
  final int weatherCode;

  const CurrentWeather({required this.temperatureC, required this.weatherCode});
}

class OpenMeteoService {
  OpenMeteoService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.open-meteo.com/v1',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  final Dio _dio;
  final Map<String, _CachedWeather> _memoryCache = {};
  static const Duration _cacheTtl = Duration(minutes: 15);

  Future<CurrentWeather> fetchCurrentWeather({
    required double lat,
    required double lon,
  }) async {
    final key = '${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}';
    final now = DateTime.now();
    final cached = _memoryCache[key];

    if (cached != null && now.difference(cached.cachedAt) < _cacheTtl) {
      developer.log('Cache hit key=$key', name: 'OpenMeteoCurrent');
      return cached.weather;
    }

    developer.log('Request start lat=$lat lon=$lon', name: 'OpenMeteoCurrent');
    final response = await _dio.get(
      '/forecast',
      queryParameters: {
        'latitude': lat,
        'longitude': lon,
        'current': 'temperature_2m,weather_code',
        'timezone': 'auto',
      },
    );

    final data = response.data as Map<String, dynamic>;
    final current = data['current'] as Map<String, dynamic>?;
    if (current == null) {
      throw Exception('Missing current weather in Open-Meteo response');
    }

    final temperature = (current['temperature_2m'] as num?)?.round();
    final weatherCode = (current['weather_code'] as num?)?.toInt();
    if (temperature == null || weatherCode == null) {
      throw Exception('Invalid current weather payload');
    }

    final weather = CurrentWeather(
      temperatureC: temperature,
      weatherCode: weatherCode,
    );
    _memoryCache[key] = _CachedWeather(weather: weather, cachedAt: now);
    developer.log(
      'Request success key=$key temp=${weather.temperatureC} code=${weather.weatherCode}',
      name: 'OpenMeteoCurrent',
    );
    return weather;
  }
}

class _CachedWeather {
  final CurrentWeather weather;
  final DateTime cachedAt;

  const _CachedWeather({required this.weather, required this.cachedAt});
}
