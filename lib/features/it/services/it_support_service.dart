import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/support_ticket.dart';

class ItSupportService {
  ItSupportService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;
  String? get _displayName => _auth.currentUser?.displayName;

  Stream<List<SupportTicket>> watchAllTickets() {
    return _firestore
        .collection('supportTickets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => SupportTicket.fromFirestore(doc)).toList(),
        );
  }

  Future<void> assignTicketToMe(String ticketId) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('You must be signed in.');
    }

    final update = <String, dynamic>{
      'status': 'in_progress',
      'assignedTo': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (_displayName != null && _displayName!.isNotEmpty) {
      update['assignedToName'] = _displayName;
    } else {
      try {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        final name = userDoc.data()?['displayName'];
        if (name is String && name.isNotEmpty) {
          update['assignedToName'] = name;
        } else {
          update['assignedToName'] = _auth.currentUser?.email?.split('@').first ?? 'IT Staff';
        }
      } catch (_) {
        update['assignedToName'] = _auth.currentUser?.email?.split('@').first ?? 'IT Staff';
      }
    }

    await _firestore.collection('supportTickets').doc(ticketId).update(update);
  }

  Future<void> updateTicketProgress({
    required String ticketId,
    required String itResponse,
    String? resolution,
    required TicketStatus status,
    required bool requiresAdminAttention,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('You must be signed in.');
    }

    debugPrint('Updating ticket $ticketId: status=$status, adminAttention=$requiresAdminAttention');

    final bool isResolving = status == TicketStatus.resolved;

    final update = <String, dynamic>{
      'itResponse': itResponse.trim(),
      'staffComment': itResponse.trim(), // Keep backward compatibility
      'status': _statusValue(status),
      'requiresAdminAttention': isResolving ? false : (status == TicketStatus.pendingAdmin ? true : requiresAdminAttention),
      'updatedAt': FieldValue.serverTimestamp(),
      'assignedTo': uid, // Auto-assign on update
      'assignedToName': _displayName ?? _auth.currentUser?.email?.split('@').first ?? 'IT Staff',
    };

    if (isResolving) {
      if (resolution == null || resolution.trim().isEmpty) {
        throw Exception('A resolution description is required to resolve this ticket.');
      }
      update['resolution'] = resolution.trim();
      update['resolvedBy'] = uid;
      update['resolvedAt'] = FieldValue.serverTimestamp();
    }

    // Use set with merge: true to ensure document structure
    await _firestore.collection('supportTickets').doc(ticketId).set(
      update,
      SetOptions(merge: true),
    );

    // If escalated to admin, create a notification
    if (!isResolving && (requiresAdminAttention || status == TicketStatus.pendingAdmin)) {
      try {
        await _firestore.collection('adminNotifications').add({
          'type': 'ticket_escalation',
          'ticketId': ticketId,
          'title': 'IT Escalation Required',
          'message': 'IT Staff has requested admin assistance for ticket #$ticketId.',
          'status': 'unread',
          'createdBy': uid,
          'createdByName': _displayName ?? _auth.currentUser?.email?.split('@').first ?? 'IT Staff',
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('Admin notification created for ticket $ticketId');
      } catch (e) {
        debugPrint('Failed to create admin notification: $e');
      }
    }
  }

  Future<void> updateTicket({
    required String ticketId,
    required TicketStatus status,
    String? staffComment,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('You must be signed in.');
    }

    final update = <String, dynamic>{
      'status': _statusValue(status),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    };

    final cleanedComment = staffComment?.trim();
    if (cleanedComment != null && cleanedComment.isNotEmpty) {
      update['staffComment'] = cleanedComment;
      update['itResponse'] = cleanedComment;
      update['staffCommentUpdatedAt'] = FieldValue.serverTimestamp();
      update['staffCommentBy'] = uid;
    }

    await _firestore.collection('supportTickets').doc(ticketId).set(
      update,
      SetOptions(merge: true),
    );
  }

  String _statusValue(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 'open';
      case TicketStatus.inProgress:
        return 'in-progress';
      case TicketStatus.resolved:
        return 'resolved';
      case TicketStatus.pendingAdmin:
        return 'pending_admin';
    }
  }

  Stream<int> watchUnreadNotificationCount() {
    final uid = _uid;
    if (uid == null) return Stream.value(0);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('itNotifications')
        .where('status', isEqualTo: 'unread')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markAllNotificationsAsRead() async {
    final uid = _uid;
    if (uid == null) return;

    final unread = await _firestore
        .collection('users')
        .doc(uid)
        .collection('itNotifications')
        .where('status', isEqualTo: 'unread')
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {
        'status': 'read',
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
