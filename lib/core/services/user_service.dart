import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Creates user profile and default alert settings if they don't exist.
  Future<void> ensureUserDocument({String? providedName}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDocRef = _usersCollection.doc(user.uid);
      final doc = await userDocRef.get().timeout(const Duration(seconds: 5));

      if (!doc.exists) {
        // 1. Create User Document
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: providedName ?? user.displayName ?? 'Anonymous User',
          notificationsEnabled: true,
          defaultAqiThreshold: 100,
          createdAt: DateTime.now(),
        );
        await userDocRef.set(newUser.toMap());

        // 2. Create Default Alert Preference (Requirement #1)
        // Default to threshold 4 (Poor) so users get warned of bad air immediately
        await userDocRef.collection('alerts').doc('default_alert').set({
          'enabled': true,
          'threshold': 4,
          'locationName': 'My Home',
          'latitude': -35.2809, // Canberra default
          'longitude': 149.1300,
          'lastNotifiedAqi': null,
          'lastNotifiedAt': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error ensuring user document and defaults: $e');
    }
  }

  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _usersCollection.doc(user.uid).update({
      'displayName': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<UserModel?> getUserData() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return _usersCollection.doc(user.uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}
