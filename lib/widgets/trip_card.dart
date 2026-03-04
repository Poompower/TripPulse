import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/trip.dart';
import '../services/open_meteo_service.dart';

class TripCard extends StatefulWidget {
  final Trip trip;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;

  const TripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.onToggleFavorite,
  });

  @override
  State<TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<TripCard> {
  static final OpenMeteoService _weatherService = OpenMeteoService();

  late Future<CurrentWeather?> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _weatherFuture = _loadWeather();
  }

  @override
  void didUpdateWidget(covariant TripCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trip.id != widget.trip.id ||
        oldWidget.trip.lat != widget.trip.lat ||
        oldWidget.trip.lon != widget.trip.lon) {
      _weatherFuture = _loadWeather();
    }
  }

  Future<CurrentWeather?> _loadWeather() async {
    final lat = widget.trip.lat;
    final lon = widget.trip.lon;
    if (lat == null || lon == null) return null;

    try {
      return await _weatherService.fetchCurrentWeather(lat: lat, lon: lon);
    } catch (_) {
      return null;
    }
  }

  String get _tripDuration {
    try {
      final formatter = DateFormat('MMM dd, yyyy');
      final start = formatter.parse(widget.trip.startDate);
      final end = formatter.parse(widget.trip.endDate);
      final days = end.difference(start).inDays + 1;
      return '$days days';
    } catch (_) {
      return '0 days';
    }
  }

  String get _mockImage {
    final lower = widget.trip.destination.toLowerCase();
    if (lower.contains('tokyo') || lower.contains('japan')) {
      return 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?q=80&w=1200&auto=format&fit=crop';
    }
    if (lower.contains('paris') || lower.contains('france')) {
      return 'https://images.unsplash.com/photo-1431274172761-fca41d930114?q=80&w=1200&auto=format&fit=crop';
    }
    return 'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?q=80&w=1200&auto=format&fit=crop';
  }

  String get _budgetText {
    final formatted = NumberFormat('#,##0').format(widget.trip.budget);
    return '\$$formatted ${widget.trip.currency}';
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

  Widget _buildWeatherBadge() {
    return FutureBuilder<CurrentWeather?>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        final weather = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting &&
            weather == null) {
          return const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF2563EB),
            ),
          );
        }

        return Row(
          children: [
            Icon(
              weather == null
                  ? Icons.help_outline
                  : _iconForWeatherCode(weather.weatherCode),
              size: 16,
              color: const Color(0xFF2563EB),
            ),
            const SizedBox(width: 4),
            Text(
              weather == null ? '--' : '${weather.temperatureC} C',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    _mockImage,
                    height: 155,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: _buildWeatherBadge(),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: widget.onToggleFavorite,
                      icon: Icon(
                        widget.trip.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: const Color(0xFFEF4444),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.trip.title,
                    style: const TextStyle(
                      fontSize: 35 / 1.7,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.trip.destination,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${widget.trip.startDate} - ${widget.trip.endDate}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EEFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _tripDuration,
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _budgetText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
