import 'package:flutter/material.dart';
import '../models/place.dart';
import '../../services/database_service.dart';
import '../../models/activity.dart';
import '../../models/trip.dart';

class DaySelectorBottomSheetWidget extends StatelessWidget {
  final Place place;

  // 🔥 ใช้ Trip จริง ไม่ mock
  final Trip trip;

  const DaySelectorBottomSheetWidget({
    super.key,
    required this.place,
    required this.trip,
  });

  /// คำนวณจำนวนวันจาก startDate → endDate (รวมวันแรก)
  int get totalDays {
  final start = DateTime.parse(trip.startDate);
  final end = DateTime.parse(trip.endDate);
  return end.difference(start).inDays + 1;
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              place.name,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // ===== DAY LIST (อิง Trip จริง ไม่ mock) =====
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

  // =========================
  // INSERT ACTIVITY จริง
  // =========================
  Future<void> _addActivity(BuildContext context, int dayNumber) async {
    final db = DatabaseService();

    final activity = Activity(
      id: null,
      tripId: trip.id,
      dayNumber: dayNumber,
      title: place.name,
      location: trip.destination,
      time: '',
    );

    await db.insertActivity(activity);

    if (!context.mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${place.name} added to Day $dayNumber',
        ),
      ),
    );
  }
}