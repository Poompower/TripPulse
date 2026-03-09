import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../itenaries/models/activity.dart';
import '../models/trip.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final String _collection = 'trips';
  final String _activitiesCollection = 'activities';
  final String _metaCollection = 'app_meta';
  final String _currencyCacheDoc = 'currency_cache';

  Future<void> insertTrip(Trip trip) async {
    final docRef = trip.id == null
        ? _db.collection(_collection).doc()
        : _db.collection(_collection).doc(trip.id.toString());

    await docRef.set(trip.toMap(), SetOptions(merge: true));
  }

  Future<List<Trip>> trips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final querySnapshot = await _db
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return Trip(
        id: doc.id,
        title: data['title'] ?? '',
        destination: data['destination'] ?? '',
        city: data['city'] as String?,
        country: data['country'] as String?,
        countryCode: data['countryCode'] as String?,
        lat: (data['lat'] as num?)?.toDouble(),
        lon: (data['lon'] as num?)?.toDouble(),
        startDate: data['startDate'] ?? '',
        endDate: data['endDate'] ?? '',
        currency: data['currency'] ?? 'USD',
        budget: (data['budget'] as num?)?.toDouble() ?? 0,
        isFavorite: data['isFavorite'] == true,
        userId: data['userId'] ?? '',
      );
    }).toList();
  }

  Future<void> updateTripFavorite({
    required dynamic tripId,
    required bool isFavorite,
  }) async {
    await _db.collection(_collection).doc(tripId.toString()).set({
      'isFavorite': isFavorite,
    }, SetOptions(merge: true));
  }

  Future<void> deleteTrip(dynamic id) async {
    await _db.collection(_collection).doc(id.toString()).delete();

    final activitiesSnapshot = await _db
        .collection(_collection)
        .doc(id.toString())
        .collection(_activitiesCollection)
        .get();

    for (final doc in activitiesSnapshot.docs) {
      await doc.reference.delete();
    }
  }

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
        imageUrl: data['imageUrl'],
        category: data['category'],
        notes: data['notes'],
        lat: (data['lat'] as num?)?.toDouble(),
        lon: (data['lon'] as num?)?.toDouble(),
      );
    }).toList();
  }

  Future<List<Activity>> getActivitiesByTrip(dynamic tripId) async {
    final querySnapshot = await _db
        .collection(_collection)
        .doc(tripId.toString())
        .collection(_activitiesCollection)
        .orderBy('dayNumber')
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
        imageUrl: data['imageUrl'],
        category: data['category'],
        notes: data['notes'],
        lat: (data['lat'] as num?)?.toDouble(),
        lon: (data['lon'] as num?)?.toDouble(),
      );
    }).toList();
  }

  Stream<List<Activity>> streamActivitiesByTrip(dynamic tripId) {
    return _db
        .collection(_collection)
        .doc(tripId.toString())
        .collection(_activitiesCollection)
        .orderBy('dayNumber')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Activity(
              id: doc.id,
              tripId: tripId.toString(),
              dayNumber: (data['dayNumber'] as num?)?.toInt() ?? 1,
              title: (data['title'] ?? '').toString(),
              location: data['location']?.toString(),
              time: data['time']?.toString(),
              imageUrl: data['imageUrl']?.toString(),
              category: data['category']?.toString(),
              notes: data['notes']?.toString(),
              lat: (data['lat'] as num?)?.toDouble(),
              lon: (data['lon'] as num?)?.toDouble(),
            );
          }).toList();
        });
  }

  Stream<List<Activity>> streamActivitiesByDay({
    required dynamic tripId,
    required int dayNumber,
  }) {
    return _db
        .collection(_collection)
        .doc(tripId.toString())
        .collection(_activitiesCollection)
        .where('dayNumber', isEqualTo: dayNumber)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Activity(
              id: doc.id,
              tripId: tripId.toString(),
              dayNumber: (data['dayNumber'] as num?)?.toInt() ?? dayNumber,
              title: (data['title'] ?? '').toString(),
              location: data['location']?.toString(),
              time: data['time']?.toString(),
              imageUrl: data['imageUrl']?.toString(),
              category: data['category']?.toString(),
              notes: data['notes']?.toString(),
              lat: (data['lat'] as num?)?.toDouble(),
              lon: (data['lon'] as num?)?.toDouble(),
            );
          }).toList();
        });
  }

  Future<void> deleteActivity(dynamic tripId, dynamic activityId) async {
    await _db
        .collection(_collection)
        .doc(tripId.toString())
        .collection(_activitiesCollection)
        .doc(activityId.toString())
        .delete();
  }

  Future<({Map<String, String> currencies, DateTime? updatedAt})?>
  getCurrencyCache() async {
    final snapshot = await _db
        .collection(_metaCollection)
        .doc(_currencyCacheDoc)
        .get();
    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null) return null;

    final raw = data['currencies'];
    if (raw is! Map<String, dynamic>) return null;

    final currencies = <String, String>{
      for (final entry in raw.entries) entry.key: entry.value.toString(),
    };

    DateTime? updatedAt;
    final updatedRaw = data['updatedAt'];
    if (updatedRaw is Timestamp) {
      updatedAt = updatedRaw.toDate();
    }

    return (currencies: currencies, updatedAt: updatedAt);
  }

  Future<void> upsertCurrencyCache({
    required Map<String, String> currencies,
    required DateTime updatedAt,
  }) async {
    await _db.collection(_metaCollection).doc(_currencyCacheDoc).set({
      'currencies': currencies,
      'updatedAt': Timestamp.fromDate(updatedAt),
    }, SetOptions(merge: true));
  }

  Future<bool> checkPhoneDuplicate(String phone) async {
    final querySnapshot = await _db
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> saveUser({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  Future<void> updateProfile(
    String uid,
    String firstName,
    String lastName,
  ) async {
    await _db.collection('users').doc(uid).update({
      'firstName': firstName,
      'lastName': lastName,
    });
  }

  Future<void> uploadProfileImageBase64(String uid, File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    await _db.collection('users').doc(uid).update({'photoBase64': base64Image});
  }

  Future<bool> checkUserProfileComplete(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      // ถ้ามีเอกสาร และ มีฟิลด์ phone แปลว่าเคยสมัครสมบูรณ์แล้ว
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data.containsKey('phone') && data['phone'].toString().isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
