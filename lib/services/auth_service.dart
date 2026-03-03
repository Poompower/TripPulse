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

  // ฟังก์ชัน Login ด้วย Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 2. แก้จุดนี้: ต้องใช้ตัวแปร _googleSignIn และตามด้วยคำสั่ง .signIn()
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return null;

      // 3. ขอ Authentication Token
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 4. สร้าง Credential (T ตัวใหญ่ที่ accessToken และ idToken)
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Login เข้า Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  // --- ส่วนของ SignUp / SignIn / SignOut (ใช้ตัวแปร _googleSignIn ที่ประกาศไว้) ---

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

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    // 6. เรียกใช้ตัวแปรที่ประกาศไว้ข้างบน
    await _googleSignIn.signOut(); 
    await _auth.signOut();
  }
}