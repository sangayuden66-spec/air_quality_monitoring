import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSupportTicket {
  final String id;
  final String category;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final DateTime createdAt;

  const UserSupportTicket({
    required this.id,
    required this.category,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  factory UserSupportTicket.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data();

    return UserSupportTicket(
      id: document.id,
      category: _readString(
        data['category'],
        fallback: 'General Inquiry',
      ),
      subject: _readString(
        data['subject'],
        fallback: 'No subject',
      ),
      description: _readString(
        data['description'],
        fallback: '',
      ),
      status: _readString(
        data['status'],
        fallback: 'open',
      ),
      priority: _readString(
        data['priority'],
        fallback: 'low',
      ),
      createdAt: _readDateTime(
        data['createdAt'],
        fallback: data['updatedAt'],
      ),
    );
  }

  static String _readString(
      dynamic value, {
        required String fallback,
      }) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return fallback;
  }

  static DateTime _readDateTime(
      dynamic value, {
        dynamic fallback,
      }) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (fallback is Timestamp) {
      return fallback.toDate();
    }

    if (fallback is DateTime) {
      return fallback;
    }

    // Handles an unresolved Firestore server timestamp safely.
    return DateTime.now();
  }
}

class SupportTicketService {
  SupportTicketService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _ticketsCollection =>
      _firestore.collection('supportTickets');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  String _mapPriority(String category) {
    switch (category.trim().toLowerCase()) {
      case 'technical issue':
        return 'high';

      case 'data accuracy':
        return 'medium';

      case 'feature request':
      case 'general inquiry':
      default:
        return 'low';
    }
  }

  Future<String> submitTicket({
    required String category,
    required String subject,
    required String description,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('You must be signed in to submit a ticket.');
    }

    final cleanedCategory = category.trim();
    final cleanedSubject = subject.trim();
    final cleanedDescription = description.trim();

    _validateTicket(
      category: cleanedCategory,
      subject: cleanedSubject,
      description: cleanedDescription,
    );

    final requesterName = await _resolveRequesterName(currentUser);

    final ticketReference = _ticketsCollection.doc();

    await ticketReference.set({
      // Must match the Firestore rule exactly.
      'userId': currentUser.uid,

      'requesterName': requesterName,
      'requesterEmail': currentUser.email ?? '',
      'category': cleanedCategory,
      'subject': cleanedSubject,
      'description': cleanedDescription,
      'priority': _mapPriority(cleanedCategory),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ticketReference.id;
  }

  Stream<List<UserSupportTicket>> watchMyRecentTickets({
    int limit = 5,
  }) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Stream.value(const <UserSupportTicket>[]);
    }

    // This query requires only the default single-field Firestore index.
    // Sorting and limiting are performed locally.
    return _ticketsCollection
        .where(
      'userId',
      isEqualTo: currentUser.uid,
    )
        .snapshots()
        .map((snapshot) {
      final tickets = snapshot.docs
          .map(UserSupportTicket.fromFirestore)
          .toList();

      tickets.sort(
            (first, second) =>
            second.createdAt.compareTo(first.createdAt),
      );

      return tickets.take(limit).toList();
    });
  }

  void _validateTicket({
    required String category,
    required String subject,
    required String description,
  }) {
    if (category.isEmpty) {
      throw Exception('Please select a category.');
    }

    if (subject.isEmpty) {
      throw Exception('Subject is required.');
    }

    if (subject.length > 120) {
      throw Exception('Subject cannot exceed 120 characters.');
    }

    if (description.isEmpty) {
      throw Exception('Description is required.');
    }

    if (description.length > 500) {
      throw Exception('Description cannot exceed 500 characters.');
    }
  }

  Future<String> _resolveRequesterName(User currentUser) async {
    final authenticationName = currentUser.displayName?.trim();

    if (authenticationName != null && authenticationName.isNotEmpty) {
      return authenticationName;
    }

    try {
      final userSnapshot =
      await _usersCollection.doc(currentUser.uid).get();

      final displayName = userSnapshot.data()?['displayName'];

      if (displayName is String && displayName.trim().isNotEmpty) {
        return displayName.trim();
      }
    } catch (_) {
      // Continue with the email fallback if Firestore is unavailable.
    }

    final email = currentUser.email?.trim();

    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'AQMS User';
  }
}