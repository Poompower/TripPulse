import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/widgets.dart';
import '../models/trip.dart';

class DatabaseService {
  Future<Database> getDatabase() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. หาตำแหน่ง Path ที่เก็บฐานข้อมูล
    final String path = join(await getDatabasesPath(), 'travel_db.db');

    // 2. ปรินท์ออกมาดูที่ Debug Console
    print("📍 Database Path: $path");

    return openDatabase(
      path, // ใช้ตัวแปร path ที่เราสร้างไว้
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE trips(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, destination TEXT, startDate TEXT, endDate TEXT, currency TEXT, budget REAL)',
        );
      },
      version: 1,
    );
  }

  Future<void> insertTrip(Trip trip) async {
    final db = await getDatabase();
    await db.insert(
      'trips',
      trip.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Trip>> trips() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'trips',
      orderBy: 'id DESC',
    );
    return List.generate(
      maps.length,
      (i) => Trip(
        id: maps[i]['id'],
        title: maps[i]['title'],
        destination: maps[i]['destination'],
        startDate: maps[i]['startDate'],
        endDate: maps[i]['endDate'],
        currency: maps[i]['currency'],
        budget: maps[i]['budget'],
      ),
    );
  }

  Future<void> deleteTrip(int id) async {
    final db = await getDatabase();
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }
}
