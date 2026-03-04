import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/activity.dart';
import '../models/trip.dart';
import '../widgets/custom_bottom_bar.dart';
import '../widgets/weather_forecast_card.dart';
import 'add_activity_screen.dart';
import 'activity_detail_screen.dart';
import 'edit_trip_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Trip _trip;
  List<Activity> _activities = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _activitiesSub;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _listenActivities();
  }

  void _listenActivities() {
    if (_trip.id == null) return;

    _activitiesSub = FirebaseFirestore.instance
        .collection('trips')
        .doc(_trip.id.toString())
        .collection('activities')
        .orderBy('dayNumber')
        .snapshots()
        .listen((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            return Activity(
              id: doc.id,
              tripId: _trip.id.toString(),
              dayNumber: (data['dayNumber'] as num?)?.toInt() ?? 1,
              title: (data['title'] ?? '').toString(),
              location: data['location']?.toString(),
              time: data['time']?.toString(),
              imageUrl: data['imageUrl']?.toString(),
              category: data['category']?.toString(),
            );
          }).toList();

          if (!mounted) return;
          setState(() => _activities = list);
        });
  }

  @override
  void dispose() {
    _activitiesSub?.cancel();
    super.dispose();
  }

  DateTime _parseTripDate(String value) {
    try {
      return DateFormat('MMM dd, yyyy').parse(value);
    } catch (_) {
      return DateTime.parse(value);
    }
  }

  int _calculateTotalDays() {
    try {
      final start = _parseTripDate(_trip.startDate);
      final end = _parseTripDate(_trip.endDate);
      final days = end.difference(start).inDays + 1;
      return days > 0 ? days : 1;
    } catch (_) {
      return 1;
    }
  }

  DateTime _dateForDay(int dayNumber) {
    final start = _parseTripDate(_trip.startDate);
    return start.add(Duration(days: dayNumber - 1));
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = _calculateTotalDays();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _trip.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTripScreen(trip: _trip),
                ),
              );
              if (result == true) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=1000&auto=format&fit=crop',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 20,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _trip.destination,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_trip.startDate} - ${_trip.endDate} ($totalDays Days)',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
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
          SliverToBoxAdapter(
            child: WeatherForecastCard(lat: _trip.lat, lon: _trip.lon),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Itinerary',
                style: TextStyle(
                  fontSize: 28 / 1.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final dayNumber = index + 1;
              final dayActivities = _activities
                  .where((a) => a.dayNumber == dayNumber)
                  .toList();
              return _buildDaySection(dayNumber, dayActivities);
            }, childCount: totalDays),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 0,
        onTap: (index) {
          if (index != 0) CustomBottomBar.navigateToIndex(context, index);
        },
        variant: BottomBarVariant.material3,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.map),
        label: const Text('View on Map'),
        backgroundColor: const Color(0xFF2F80ED),
      ),
    );
  }

  Widget _buildDaySection(int dayNumber, List<Activity> activities) {
    final date = _dateForDay(dayNumber);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$dayNumber',
                  style: const TextStyle(
                    color: Color(0xFF2F80ED),
                    fontWeight: FontWeight.bold,
                    fontSize: 22 / 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE').format(date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      DateFormat('M/d/yyyy').format(date),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F7F0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place, color: Color(0xFF27AE60), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${activities.length}',
                      style: const TextStyle(
                        color: Color(0xFF27AE60),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFF2F80ED),
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddActivityScreen(
                        tripId: _trip.id,
                        dayNumber: dayNumber,
                      ),
                    ),
                  );

                  if (!mounted) return;
                  if (result == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Activity added')),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                'No places planned yet',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            )
          else
            ...activities.map(_buildActivityItem),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Activity activity) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailScreen(activity: activity),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: activity.imageUrl != null && activity.imageUrl!.isNotEmpty
                  ? Image.network(
                      activity.imageUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _activityPlaceholder(),
                    )
                  : _activityPlaceholder(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      activity.category ??
                          (activity.location?.isNotEmpty == true
                              ? activity.location!
                              : 'Place'),
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _activityPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.grey.shade200,
      child: const Icon(Icons.place, size: 22, color: Colors.grey),
    );
  }
}
