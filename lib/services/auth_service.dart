import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _dbService = DatabaseService();
  
  // 1. ประกาศตัวแปร _googleSignIn ไว้ที่นี่ (เพื่อให้เรียกใช้ได้ทั้งใน signIn และ signOut)
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ตรวจสอบสถานะการ Login
  Stream<User?> get userStatus => _auth.authStateChanges();

  // ฟังก์ชัน Login ด้วย Google (คงของเดิมไว้ 100%)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  Future<String?> signUp({
    required String email, 
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      bool isPhoneDuplicate = await _dbService.checkPhoneDuplicate(phone);
      if (isPhoneDuplicate) return 'เบอร์โทรศัพท์นี้ถูกใช้งานไปแล้ว';

      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
          
      if (result.user != null) {
        await _dbService.saveUser(
          uid: result.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
        );
        return null; 
      }
      return 'เกิดข้อผิดพลาด';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'อีเมลนี้ถูกลงทะเบียนไปแล้ว';
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ✨ แก้ไขฟังก์ชันนี้: เปลี่ยนให้ดัก Error และส่งกลับเป็นข้อความภาษาไทย
  Future<String?> signIn(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) return 'กรุณากรอกอีเมลและรหัสผ่านให้ครบถ้วน';
      
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      return null; // ถ้าสำเร็จ คืนค่า null (ไม่มี Error)
    } on FirebaseAuthException catch (e) {
      // เช็ค Code จาก Firebase เพื่อแปลงเป็นคำไทย
      switch (e.code) {
        case 'user-not-found':
          return 'ไม่พบอีเมลนี้ในระบบ';
        case 'wrong-password':
          return 'รหัสผ่านไม่ถูกต้อง';
        case 'invalid-email':
          return 'รูปแบบอีเมลไม่ถูกต้อง';
        case 'invalid-credential':
          return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
        case 'user-disabled':
          return 'บัญชีนี้ถูกระงับการใช้งาน';
        default:
          return 'เกิดข้อผิดพลาด: ${e.message}';
      }
    } catch (e) {
      return 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
    }
  }

  Future<void> signOut() async {
    // 6. เรียกใช้ตัวแปรที่ประกาศไว้ข้างบน
    await _googleSignIn.signOut(); 
    await _auth.signOut();
  }
}