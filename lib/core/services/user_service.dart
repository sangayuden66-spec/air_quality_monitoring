import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Creates or updates the user document in Firestore safely.
  /// [providedName] can be passed during signup to ensure the name is saved immediately.
  Future<void> ensureUserDocument({String? providedName}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef = _usersCollection.doc(user.uid);
      final doc = await docRef.get().timeout(const Duration(seconds: 5));

      if (!doc.exists) {
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: providedName ?? user.displayName ?? 'Anonymous User',
          notificationsEnabled: true,
          defaultAqiThreshold: 100,
          createdAt: DateTime.now(),
        );
        await docRef.set(newUser.toMap());
      }
    } catch (e) {
      print('Error ensuring user document: $e');
      // We don't rethrow here to prevent blocking the app flow
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

  Future<void> updatePreferences({
    required bool enabled,
    required int threshold,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _usersCollection.doc(user.uid).update({
      'notificationsEnabled': enabled,
      'defaultAqiThreshold': threshold,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
