import 'package:flutter/material.dart';

class WeatherForecastCard extends StatelessWidget {
  const WeatherForecastCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          /// Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.wb_sunny_outlined, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Weather Forecast',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// Forecast Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _WeatherDay(
                day: 'Sat',
                icon: Icons.wb_sunny,
                high: 18,
                low: 12,
                rain: 10,
              ),
              _WeatherDay(
                day: 'Sun',
                icon: Icons.cloud,
                high: 16,
                low: 11,
                rain: 20,
              ),
              _WeatherDay(
                day: 'Mon',
                icon: Icons.water_drop,
                high: 14,
                low: 10,
                rain: 80,
              ),
              _WeatherDay(
                day: 'Tue',
                icon: Icons.cloud,
                high: 15,
                low: 9,
                rain: 30,
              ),
            ],
          ),
        ],
      ),
    );
  }
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
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Icon(icon, color: Colors.blue, size: 26),
        const SizedBox(height: 6),
        Text(
          '$high°',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          '$low°',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.water_drop, size: 12, color: Colors.blue),
            const SizedBox(width: 2),
            Text(
              '$rain%',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
