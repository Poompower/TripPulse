import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _dbService = DatabaseService();

  // ตรวจสอบสถานะการ Login
  Stream<User?> get userStatus => _auth.authStateChanges();

  // สมัครสมาชิกด้วย Email
  Future<String?> signUp({
    required String email, 
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      // 1. เช็คเบอร์โทรซ้ำก่อน
      bool isPhoneDuplicate = await _dbService.checkPhoneDuplicate(phone);
      if (isPhoneDuplicate) {
        return 'เบอร์โทรศัพท์นี้ถูกใช้งานไปแล้ว'; // คืนค่า Error กลับไป
      }

      // 2. สร้างบัญชีผ่าน Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
          
      // 3. บันทึกข้อมูลลง Database
      if (result.user != null) {
        await _dbService.saveUser(
          uid: result.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
        );
        return null; // สมัครสำเร็จ ไม่มี Error
      }
      return 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
      
    } on FirebaseAuthException catch (e) {
      // ดักจับ Error จาก Firebase Auth (เช่น อีเมลซ้ำ)
      if (e.code == 'email-already-in-use') {
        return 'อีเมลนี้ถูกลงทะเบียนไปแล้ว';
      } else if (e.code == 'weak-password') {
        return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
      } else if (e.code == 'invalid-email') {
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      }
      return e.message;
    } catch (e) {
      return 'เกิดข้อผิดพลาด: $e';
    }
  }

  // เข้าสู่ระบบด้วย Email
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      return null;
    }
  }

  // ออกจากระบบ
  Future<void> signOut() async => await _auth.signOut();
}