import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Creates user profile and default alert settings if they don't exist.
  Future<void> ensureUserDocument({
    String? providedName,
    String? providedRole,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDocRef = _usersCollection.doc(user.uid);
      bool loadedFromServer = true;
      late final DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        doc = await userDocRef
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        loadedFromServer = false;
        doc = await userDocRef.get().timeout(const Duration(seconds: 5));
      }
      final normalizedProvidedName = providedName?.trim();
      final normalizedAuthName = user.displayName?.trim();
      final resolvedName =
          (normalizedProvidedName != null && normalizedProvidedName.isNotEmpty)
          ? normalizedProvidedName
          : (normalizedAuthName != null && normalizedAuthName.isNotEmpty)
          ? normalizedAuthName
          : 'User';
      final normalizedProvidedRole = providedRole?.trim().toLowerCase();
      final resolvedRole =
          normalizedProvidedRole == 'admin' || normalizedProvidedRole == 'it'
          ? normalizedProvidedRole!
          : 'user';

      if (!doc.exists) {
        // 1. Create User Document
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: resolvedName,
          notificationsEnabled: true,
          defaultAqiThreshold: 100,
          role: resolvedRole,
          status: 'active',
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );
        await userDocRef.set(newUser.toMap());

        // 2. Create default alert preference without fixed coordinates.
        // Coordinates are initialized from the device location during app startup.
        await userDocRef.collection('alerts').doc('default_alert').set({
          'enabled': true,
          'threshold': 4,
          'locationName': 'Current Location',
          'lastNotifiedAqi': null,
          'lastNotifiedAt': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final data = doc.data() ?? <String, dynamic>{};
        final patch = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
          'lastActiveAt': FieldValue.serverTimestamp(),
        };
        if (loadedFromServer) {
          final role = data['role'];
          final status = data['status'];
          if (role is! String || role.trim().isEmpty) {
            patch['role'] = 'user';
          }
          if (status is! String || status.trim().isEmpty) {
            patch['status'] = 'active';
          }
        }
        await userDocRef.set(patch, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error ensuring user document and defaults: $e');
    }
  }

  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw Exception('Display name cannot be empty.');
    }

    await user.updateDisplayName(normalized);
    await user.reload();
    await _usersCollection.doc(user.uid).set({
      'displayName': normalized,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<UserModel?> getUserData() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return watchUserById(user.uid);
  }

  Stream<UserModel?> watchUserById(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = Map<String, dynamic>.from(snapshot.data()!);
        data['uid'] = (data['uid'] as String?)?.trim().isNotEmpty == true
            ? data['uid']
            : snapshot.id;
        return UserModel.fromMap(data);
      }
      return null;
    });
  }

  Future<UserModel?> getCurrentUserDataOnce() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snapshot = await _usersCollection.doc(user.uid).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    final data = Map<String, dynamic>.from(snapshot.data()!);
    data['uid'] = (data['uid'] as String?)?.trim().isNotEmpty == true
        ? data['uid']
        : snapshot.id;
    return UserModel.fromMap(data);
  }

  Future<void> touchCurrentUserActivity() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _usersCollection.doc(user.uid).set({
      'lastActiveAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
