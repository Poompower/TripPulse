import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 1. Import หน้าจอข้ามโฟลเดอร์ให้ถูกต้อง
import 'login_screen.dart'; // อยู่โฟลเดอร์เดียวกัน พิมพ์ชื่อไฟล์ได้เลย
import 'complete_profile_screen.dart'; // อยู่โฟลเดอร์เดียวกัน
import '../../trips/screens/trip_list_screen.dart'; // ข้ามไปเอาหน้า TripList
import '../../trips/services/database_service.dart'; // ข้ามไปเอา DatabaseService

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // ชั้นที่ 1: เช็คว่า "เคยล็อกอินทิ้งไว้ไหม?"
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // ระหว่างรอโหลดสถานะจาก Firebase
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // ถ้าไม่มีข้อมูล = ไม่เคยล็อกอิน หรือกด Log out ไปแล้ว
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const LoginScreen();
        }

        // ชั้นที่ 2: ถ้าล็อกอินแล้ว เช็คต่อว่า "กรอกโปรไฟล์ครบหรือยัง?"
        final user = authSnapshot.data!;
        
        return FutureBuilder<bool>(
          future: DatabaseService().checkUserProfileComplete(user.uid),
          builder: (context, profileSnapshot) {
            // ระหว่างรอโหลดข้อมูลจาก Database
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // ถ้ากรอกโปรไฟล์ครบแล้ว ไปหน้า TripList
            if (profileSnapshot.data == true) {
              return const TripListScreen(); 
            }

            // ถ้ายังไม่ครบ ให้เด้งไปหน้า Complete Profile พร้อมส่ง user ไปให้
            return CompleteProfileScreen(user: user);
          },
        );
      },
    );
  }
}