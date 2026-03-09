import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../trips/services/database_service.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  DatabaseService get _dbService => DatabaseService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get userStatus => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      developer.log('GoogleAuth signup/login start', name: 'AuthService');
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        developer.log(
          'GoogleAuth cancelled by user at account picker',
          name: 'AuthService',
        );
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      developer.log(
        'GoogleAuth Firebase sign-in success: uid=${userCredential.user?.uid}',
        name: 'AuthService',
      );
      return userCredential;
    } on FirebaseAuthException catch (e, st) {
      developer.log(
        'GoogleAuth FirebaseAuthException code=${e.code}, message=${e.message}',
        name: 'AuthService',
        error: e,
        stackTrace: st,
      );
      return null;
    } catch (e) {
      developer.log(
        'GoogleAuth unexpected error',
        name: 'AuthService',
        error: e,
      );
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
      final isPhoneDuplicate = await _dbService.checkPhoneDuplicate(phone);
      if (isPhoneDuplicate) {
        return 'Phone number already in use';
      }

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

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

      return 'Failed to create account';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Email already in use';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return 'Please enter email and password';
      }

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'User not found';
        case 'wrong-password':
          return 'Wrong password';
        case 'invalid-email':
          return 'Invalid email format';
        case 'invalid-credential':
          return 'Invalid email or password';
        case 'user-disabled':
          return 'This account has been disabled';
        default:
          return 'Authentication error: ${e.message}';
      }
    } catch (_) {
      return 'Unknown error';
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
