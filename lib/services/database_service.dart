import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import '../models/activity.dart';
import 'dart:io';
import 'dart:convert';

class DatabaseService {
  // สร้าง Instance ของ Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collections
  final String _collection = 'trips';
  final String _activitiesCollection = 'activities';

  // 1. เพิ่มข้อมูลทริปใหม่ (Create)
  Future<void> insertTrip(Trip trip) async {
    final docRef = trip.id == null
        ? _db.collection(_collection).doc()
        : _db.collection(_collection).doc(trip.id.toString());

    await docRef.set(trip.toMap());
  }

  // 2. ดึงข้อมูลทริปทั้งหมด (Read)
  Future<List<Trip>> trips() async {
    final querySnapshot = await _db.collection(_collection).get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return Trip(
        id: doc.id as dynamic,
        title: data['title'],
        destination: data['destination'],
        startDate: data['startDate'],
        endDate: data['endDate'],
        currency: data['currency'],
        budget: (data['budget'] as num).toDouble(),
      );
    }).toList();
  }

  // 3. ลบข้อมูล (Delete)
  Future<void> deleteTrip(dynamic id) async {
    await _db.collection(_collection).doc(id.toString()).delete();
  }

  // 4. เพิ่มหรือแก้ไข Activity
  Future<void> insertActivity(Activity activity) async {
    final docRef = activity.id == null
        ? _db.collection(_activitiesCollection).doc()
        : _db.collection(_activitiesCollection).doc(activity.id.toString());

    // Ensure tripId is stored as String to match queries
    final map = activity.toMap();
    map['tripId'] = activity.tripId.toString();

    await docRef.set(map);
  }

  // 5. ดึงข้อมูล Activities ตามวัน
  Future<List<Activity>> getActivitiesByDay(dynamic tripId, int dayNumber) async {
    final querySnapshot = await _db
        .collection(_activitiesCollection)
        .where('tripId', isEqualTo: tripId.toString())
        .where('dayNumber', isEqualTo: dayNumber)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return Activity(
        id: doc.id,
        tripId: data['tripId'],
        dayNumber: data['dayNumber'],
        title: data['title'],
        location: data['location'],
        time: data['time'],
      );
    }).toList();
  }

  // 6. ดึงข้อมูล Activities ทั้งหมดของทริป
  Future<List<Activity>> getActivitiesByTrip(dynamic tripId) async {
    final querySnapshot = await _db
        .collection(_activitiesCollection)
        .where('tripId', isEqualTo: tripId.toString())
        .orderBy('dayNumber')
        .get();

    print('📦 Activities loaded: ${querySnapshot.docs.length} activities for trip $tripId');

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      print('📌 Activity: ${data['title']} on Day ${data['dayNumber']}');
      return Activity(
        id: doc.id,
        tripId: data['tripId'],
        dayNumber: data['dayNumber'],
        title: data['title'],
        location: data['location'],
        time: data['time'],
      );
    }).toList();
  }

  // 7. ลบ Activity
  Future<void> deleteActivity(dynamic id) async {
    await _db.collection(_activitiesCollection).doc(id.toString()).delete();
  }
  // เพิ่มส่วนนี้เข้าไปในไฟล์ lib/services/database_service.dart

Future<bool> checkPhoneDuplicate(String phone) async {
    final querySnapshot = await _db
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();
    
    return querySnapshot.docs.isNotEmpty; // ถ้าเจอข้อมูล (isNotEmpty) แปลว่าซ้ำ (true)
  }

  // 2. อัปเดต saveUser ให้บันทึกข้อมูลครบถ้วน
  Future<void> saveUser({
    required String uid, 
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving user: $e");
    }
  }
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Error getting profile: $e");
      return null;
    }
  }

  // อัปเดตข้อมูลโปรไฟล์ (ชื่อ, นามสกุล)
  Future<void> updateProfile(String uid, String firstName, String lastName) async {
    await _db.collection('users').doc(uid).update({
      'firstName': firstName,
      'lastName': lastName,
    });
  }

  // อัปโหลดรูปภาพและบันทึก URL ลง Firestore
  Future<void> uploadProfileImageBase64(String uid, File imageFile) async {
    try {
      // 1. อ่านไฟล์รูปภาพเป็นไบต์ (Bytes)
      final bytes = await imageFile.readAsBytes();
      
      // 2. แปลงไบต์เป็นข้อความ String (Base64)
      String base64Image = base64Encode(bytes);
      
      // 3. เซฟข้อความนั้นลง Firestore
      await _db.collection('users').doc(uid).update({
        'photoBase64': base64Image
      });
    } catch (e) {
      print("Error saving image to DB: $e");
    }
  }
}