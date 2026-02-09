import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';

class DatabaseService {
  // สร้าง Instance ของ Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // เปลี่ยนชื่อ Collection เป็น 'trips'
  final String _collection = 'trips';

  // 1. เพิ่มข้อมูลทริปใหม่ (Create)
  Future<void> insertTrip(Trip trip) async {
    // ถ้าไม่มี id (เพิ่มใหม่) ให้ Firestore เจนให้ หรือถ้ามี id (แก้ไข) ให้ทับตัวเดิม
    final docRef = trip.id == null 
        ? _db.collection(_collection).doc() 
        : _db.collection(_collection).doc(trip.id.toString());

    await docRef.set(trip.toMap());
  }

  // 2. ดึงข้อมูลทริปทั้งหมด (Read) - เปลี่ยนจาก Future เป็น Stream จะดีมากเพื่อ Real-time
  Future<List<Trip>> trips() async {
    final querySnapshot = await _db.collection(_collection).get();
    
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return Trip(
        id: doc.id as dynamic, // ใช้ ID จาก Firestore แทน
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
}