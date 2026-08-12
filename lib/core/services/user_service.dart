import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Creates or updates the user document in Firestore safely.
  Future<void> ensureUserDocument() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _usersCollection.doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        notificationsEnabled: true,
        defaultAqiThreshold: 100,
        createdAt: DateTime.now(),
      );
      await docRef.set(newUser.toMap());
    } else {
      // Update email/displayName if they changed or were missing
      await docRef.update({
        'email': user.email ?? '',
        if (user.displayName != null) 'displayName': user.displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Retrieves the current user's data.
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

  /// Updates user notification preferences.
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
