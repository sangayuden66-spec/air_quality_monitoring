import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/support_ticket.dart';

class ItSupportService {
  ItSupportService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<SupportTicket>> watchAllTickets() {
    return _firestore
        .collection('supportTickets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
          .map((doc) => SupportTicket.fromFirestore(doc))
          .toList(),
    );
  }
}