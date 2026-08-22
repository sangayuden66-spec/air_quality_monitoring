import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/it_settings_preferences.dart';

class ItSettingsService {
  ItSettingsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  Stream<ItSettingsPreferences> watchPreferences() {
    final uid = _uid;
    if (uid == null) return Stream.value(ItSettingsPreferences.defaults);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('itPreferences')
        .doc('settings')
        .snapshots()
        .map((doc) => ItSettingsPreferences.fromMap(doc.data()));
  }

  Future<void> savePreferences(ItSettingsPreferences prefs) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('itPreferences')
        .doc('settings')
        .set(prefs.toMap(), SetOptions(merge: true));
  }
}