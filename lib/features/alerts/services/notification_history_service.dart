import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_history_item.dart';

class NotificationHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Get a stream of notification history for the current user
  Stream<List<NotificationHistoryItem>> getHistoryStream() {
    if (_uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('notificationHistory')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationHistoryItem.fromFirestore(doc))
          .toList();
    });
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    if (_uid == null) return;

    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('notificationHistory')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Delete a notification from history
  Future<void> deleteNotification(String notificationId) async {
    if (_uid == null) return;

    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('notificationHistory')
        .doc(notificationId)
        .delete();
  }
}
