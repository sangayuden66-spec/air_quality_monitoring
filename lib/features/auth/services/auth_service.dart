import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  Stream<User?> get user => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Ensure document exists on sign in
      await _userService.ensureUserDocument();
      return credential;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
    String name, {
    String role = 'user',
  }) async {
    try {
      final normalizedName = name.trim();
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // 1. Update Auth Profile
        if (normalizedName.isNotEmpty) {
          await credential.user!.updateDisplayName(normalizedName);
          await credential.user!.reload();
        }

        // 2. Create Firestore Document Immediately
        await _userService.ensureUserDocument(
          providedName: normalizedName.isEmpty ? null : normalizedName,
          providedRole: role,
        );
      }

      return credential;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
