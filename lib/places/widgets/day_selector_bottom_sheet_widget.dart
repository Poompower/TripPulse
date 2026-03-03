import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/activity.dart';
import '../../models/trip.dart';
import '../../services/database_service.dart';
import '../models/place.dart';

class DaySelectorBottomSheetWidget extends StatelessWidget {
  final Place place;
  final Trip trip;

  const DaySelectorBottomSheetWidget({
    super.key,
    required this.place,
    required this.trip,
  });

  DateTime _parseTripDate(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateFormat('MMM dd, yyyy').parseStrict(value);
    }
  }

  // Inclusive days from trip start to trip end.
  int get totalDays {
    final start = _parseTripDate(trip.startDate);
    final end = _parseTripDate(trip.endDate);
    final days = end.difference(start).inDays + 1;
    return days > 0 ? days : 1;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add to itinerary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(place.name, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            for (int day = 1; day <= totalDays; day++)
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text('Day $day'),
                onTap: () async {
                  await _addActivity(context, day);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Insert activity into database.
  Future<void> _addActivity(BuildContext context, int dayNumber) async {
    final db = DatabaseService();

    final activity = Activity(
      id: null,
      tripId: trip.id,
      dayNumber: dayNumber,
      title: place.name,
      location: trip.destination,
      time: '',
      imageUrl: place.imageUrl,
      category: place.category,
    );

    await db.insertActivity(activity);

    if (!context.mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${place.name} added to Day $dayNumber')),
    );
  }
}
