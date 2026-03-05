import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeatherForecastCard extends StatefulWidget {
  final double? lat;
  final double? lon;

  const WeatherForecastCard({super.key, required this.lat, required this.lon});

  @override
  State<WeatherForecastCard> createState() => _WeatherForecastCardState();
}

class _WeatherForecastCardState extends State<WeatherForecastCard> {
  late final Dio _dio;
  bool _isLoading = true;
  String? _error;
  DateTime? _updatedAt;
  List<_ForecastDay> _forecast = [];

  @override
  void initState() {
    super.initState();
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.open-meteo.com/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    _loadForecast();
  }

  Future<void> _loadForecast() async {
    final lat = widget.lat;
    final lon = widget.lon;

    if (lat == null || lon == null) {
      setState(() {
        _isLoading = false;
        _error = 'No coordinates for weather forecast';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      developer.log('Request forecast lat=$lat lon=$lon', name: 'OpenMeteo');

      final response = await _dio.get(
        '/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'timezone': 'auto',
          'forecast_days': 4,
          'daily':
              'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final daily = data['daily'] as Map<String, dynamic>?;
      if (daily == null) {
        throw Exception('Missing daily weather data');
      }

      final times = (daily['time'] as List).cast<String>();
      final maxTemps = (daily['temperature_2m_max'] as List)
          .map((e) => (e as num).round())
          .toList();
      final minTemps = (daily['temperature_2m_min'] as List)
          .map((e) => (e as num).round())
          .toList();
      final rainProb = (daily['precipitation_probability_max'] as List)
          .map((e) => (e as num).round())
          .toList();
      final weatherCodes = (daily['weather_code'] as List)
          .map((e) => (e as num).toInt())
          .toList();

      final length = [
        times.length,
        maxTemps.length,
        minTemps.length,
        rainProb.length,
        weatherCodes.length,
      ].reduce((a, b) => a < b ? a : b);

      final forecast = List.generate(length, (index) {
        final date = DateTime.tryParse(times[index]);
        final dayLabel = date != null ? DateFormat('E').format(date) : '-';

        return _ForecastDay(
          day: dayLabel,
          high: maxTemps[index],
          low: minTemps[index],
          rainChance: rainProb[index],
          weatherCode: weatherCodes[index],
        );
      });

      if (!mounted) return;
      setState(() {
        _forecast = forecast;
        _updatedAt = DateTime.now();
      });
    } catch (e, st) {
      developer.log(
        'Forecast request failed: $e',
        name: 'OpenMeteo',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load weather forecast';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.wb_sunny_outlined, color: Color(0xFF2F80ED)),
                  SizedBox(width: 8),
                  Text(
                    'Weather Forecast',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              if (_updatedAt != null)
                Text(
                  'Updated ${DateFormat('HH:mm').format(_updatedAt!)}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _forecast
                  .map(
                    (day) => _WeatherDay(
                      day: day.day,
                      icon: _iconForWeatherCode(day.weatherCode),
                      high: day.high,
                      low: day.low,
                      rain: day.rainChance,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  IconData _iconForWeatherCode(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code == 1 || code == 2) return Icons.wb_cloudy;
    if (code == 3) return Icons.cloud;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 67) return Icons.grain;
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 80 && code <= 82) return Icons.umbrella;
    if (code >= 95) return Icons.thunderstorm;
    return Icons.cloud;
  }
}

class _ForecastDay {
  final String day;
  final int high;
  final int low;
  final int rainChance;
  final int weatherCode;

  const _ForecastDay({
    required this.day,
    required this.high,
    required this.low,
    required this.rainChance,
    required this.weatherCode,
  });
}

class _WeatherDay extends StatelessWidget {
  final String day;
  final IconData icon;
  final int high;
  final int low;
  final int rain;

  const _WeatherDay({
    required this.day,
    required this.icon,
    required this.high,
    required this.low,
    required this.rain,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          day,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Icon(icon, color: const Color(0xFF2F80ED), size: 26),
        const SizedBox(height: 6),
        Text(
          '$high°',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text('$low°', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.water_drop, size: 12, color: Color(0xFF2F80ED)),
            const SizedBox(width: 2),
            Text(
              '$rain%',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }
}
