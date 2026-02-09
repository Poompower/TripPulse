import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import '../models/activity.dart'; // อย่าลืมสร้าง model นี้
import '../widgets/custom_bottom_bar.dart';
import '../widgets/weather_forecast_card.dart';
import '../services/database_service.dart';
import 'edit_trip_screen.dart';
import 'add_activity_screen.dart';
import 'activity_detail_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Trip _trip;
  List<Activity> _activities = []; // สมมติว่าดึงข้อมูลมาจาก DB
  StreamSubscription<QuerySnapshot>? _activitiesSub;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    // โหลด activities เริ่มต้นและตั้ง listener แบบ real-time
    try {
      _activitiesSub = FirebaseFirestore.instance
          .collection('activities')
          .where('tripId', isEqualTo: _trip.id.toString())
          .orderBy('dayNumber')
          .snapshots()
              .listen((snapshot) {
            print('📶 activities snapshot: ${snapshot.docs.length} docs for trip ${_trip.id}');
            final list = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Activity(
            id: doc.id,
            tripId: data['tripId'],
            dayNumber: data['dayNumber'],
            title: data['title'],
            location: data['location'],
            time: data['time'],
          );
        }).toList();

        setState(() {
          _activities = list;
        });
      });
    } catch (e) {
      // ignore listener errors for now
    }
  }

  @override
  void dispose() {
    _activitiesSub?.cancel();
    super.dispose();
  }

  // ฟังก์ชันคำนวณจำนวนวันทั้งหมดของทริป
  int _calculateTotalDays() {
    try {
      DateFormat format = DateFormat('MMM dd, yyyy');
      DateTime start = format.parse(_trip.startDate);
      DateTime end = format.parse(_trip.endDate);
      return end.difference(start).inDays + 1;
    } catch (e) {
      return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalDays = _calculateTotalDays();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_trip.title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditTripScreen(trip: _trip)),
              );
              if (result == true) {
                // Logic สำหรับ Refresh ข้อมูล
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Cover Image & Trip Info
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    image: DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=1000&auto=format&fit=crop'),
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
                          const Icon(Icons.location_on, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(_trip.destination, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('${_trip.startDate} - ${_trip.endDate} ($totalDays Days)',
                              style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: WeatherForecastCard()),

          // Itinerary Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Itinerary',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // สร้าง Day List อัตโนมัติ
          SliverList(
            key: ValueKey(_activities.length),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                int dayNumber = index + 1;
                // กรองกิจกรรมของวันนั้นๆ
                List<Activity> dayActivities = _activities.where((a) => a.dayNumber == dayNumber).toList();

                return _buildDaySection(dayNumber, dayActivities);
              },
              childCount: totalDays,
            ),
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
        onPressed: () {
          // Logic สำหรับเปิดแผนที่รวมทุกจุด
        },
        icon: const Icon(Icons.map),
        label: const Text('View Full Map'),
        backgroundColor: Colors.black,
      ),
    );
  }

  // Widget สำหรับแต่ละวัน
  Widget _buildDaySection(int dayNumber, List<Activity> activities) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text('Day $dayNumber', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
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

                if (result == true) {
                  // Firestore listener updates the UI automatically; show quick feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Activity added')),
                  );
                }
              },
            ),
          ),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 16),
              child: Text('No activities planned yet', style: TextStyle(color: Colors.grey, fontSize: 13)),
            )
          else
            ...activities.map((activity) => _buildActivityItem(activity)).toList(),
        ],
      ),
    );
  }

  // Widget สำหรับรายการสถานที่ในแต่ละวัน
  Widget _buildActivityItem(Activity activity) {
    return ListTile(
      leading: const Icon(Icons.circle, size: 12, color: Colors.blue),
      title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: activity.location != null ? Text(activity.location!) : null,
      trailing: Text(activity.time ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}