import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import '../models/activity.dart';

class DatabaseService {
  // สร้าง Instance ของ Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collections
  final String _collection = 'trips';
  final String _activitiesCollection = 'activities';

  // =========================
  // 1. เพิ่มข้อมูลทริปใหม่ (Create)
  // =========================
  Future<void> insertTrip(Trip trip) async {
    final docRef = trip.id == null
        ? _db.collection(_collection).doc()
        : _db.collection(_collection).doc(trip.id.toString());

    // ใช้ merge เพื่อไม่ให้ field เก่าหาย
    await docRef.set(trip.toMap(), SetOptions(merge: true));
  }

  // =========================
  // 2. ดึงข้อมูลทริปทั้งหมด (Read)
  // =========================
  Future<List<Trip>> trips() async {
    final querySnapshot = await _db.collection(_collection).get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return Trip(
        id: doc.id, // Firestore doc.id เป็น String อยู่แล้ว
        title: data['title'],
        destination: data['destination'],
        startDate: data['startDate'],
        endDate: data['endDate'],
        currency: data['currency'],
        budget: (data['budget'] as num).toDouble(),
      );
    }).toList();
  }

  // =========================
  // 3. ลบข้อมูล (Delete)
  // =========================
  Future<void> deleteTrip(dynamic id) async {
    // ลบ trip หลัก
    await _db.collection(_collection).doc(id.toString()).delete();

    // ลบ activities ใต้ trip นี้ทั้งหมด
    final activitiesSnapshot = await _db
        .collection(_collection)
        .doc(id.toString())
        .collection(_activitiesCollection)
        .get();

    for (final doc in activitiesSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // =========================
  // 4. เพิ่มหรือแก้ไข Activity
  // =========================
  Future<void> insertActivity(Activity activity) async {
    final tripId = activity.tripId.toString();

    final docRef = activity.id == null
        ? _db
            .collection(_collection)
            .doc(tripId)
            .collection(_activitiesCollection)
            .doc()
        : _db
            .collection(_collection)
            .doc(tripId)
            .collection(_activitiesCollection)
            .doc(activity.id.toString());

    await docRef.set(activity.toMap(), SetOptions(merge: true));
  }

  // =========================
  // 5. ดึงข้อมูล Activities ตามวัน
  // =========================
  Future<List<Activity>> getActivitiesByDay(
    dynamic tripId,
    int dayNumber,
  ) async {
    final querySnapshot = await _db
        .collection(_collection)
        .doc(tripId.toString())
        .collection(_activitiesCollection)
        .where('dayNumber', isEqualTo: dayNumber)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return Activity(
        id: doc.id,
        tripId: tripId.toString(),
        dayNumber: data['dayNumber'],
        title: data['title'],
        location: data['location'],
        time: data['time'],
      );
    }).toList();
  }

  // =========================
  // 6. ดึงข้อมูล Activities ทั้งหมดของทริป
  // =========================
  Future<List<Activity>> getActivitiesByTrip(dynamic tripId) async {
    final querySnapshot = await _db
        .collection(_collection)
        .doc(tripId.toString())
        .collection(_activitiesCollection)
        .orderBy('dayNumber')
        .get();

    print(
      '📦 Activities loaded: ${querySnapshot.docs.length} activities for trip $tripId',
    );

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      print('📌 Activity: ${data['title']} on Day ${data['dayNumber']}');

      return Activity(
        id: doc.id,
        tripId: tripId.toString(),
        dayNumber: data['dayNumber'],
        title: data['title'],
        location: data['location'],
        time: data['time'],
      );
    }).toList();
  }

  // =========================
  // 7. ลบ Activity
  // =========================
  Future<void> deleteActivity(dynamic tripId, dynamic activityId) async {
    await _db
        .collection(_collection)
        .doc(tripId.toString())
        .collection(_activitiesCollection)
        .doc(activityId.toString())
        .delete();
  }
}
