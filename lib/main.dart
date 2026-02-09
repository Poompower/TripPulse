import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trippulse/pages/trip_list_screen.dart'; // Import จากโฟลเดอร์ pages

void main() async{
  // ต้องมีเพื่อให้ SQLite เริ่มต้นทำงานได้
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TripPulse',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: TripListScreen(),
    );
  }
}