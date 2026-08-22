import 'package:cloud_firestore/cloud_firestore.dart';

class ReportItem {
  final String id;
  final String userId;
  final String user;
  final String initials;
  final String location;
  final String text;
  final DateTime createdAt;
  final List<String> confirmedBy;
  final List<String> deniedBy;
  final String status; // pending | verified | hidden
  final String visibility; // visible | hidden
  final String moderationStatus; // pending | approved | rejected
  final String severity; // low | medium | high

  const ReportItem({
    required this.id,
    required this.userId,
    required this.user,
    required this.initials,
    required this.location,
    required this.text,
    required this.createdAt,
    required this.confirmedBy,
    required this.deniedBy,
    required this.status,
    this.visibility = 'visible',
    this.moderationStatus = 'pending',
    this.severity = 'medium',
  });

  int get confirm => confirmedBy.length;
  int get deny => deniedBy.length;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'user': user,
      'initials': initials,
      'location': location,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedBy': confirmedBy,
      'deniedBy': deniedBy,
      'status': status,
      'visibility': visibility,
      'moderationStatus': moderationStatus,
      'severity': severity,
    };
  }

  factory ReportItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportItem(
      id: doc.id,
      userId: data['userId'] ?? '',
      user: data['user'] ?? 'Unknown',
      initials: data['initials'] ?? '?',
      location: data['location'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      confirmedBy: List<String>.from(data['confirmedBy'] ?? []),
      deniedBy: List<String>.from(data['deniedBy'] ?? []),
      status: data['status'] ?? 'pending',
      visibility: (data['visibility'] as String?) ?? 'visible',
      moderationStatus: (data['moderationStatus'] as String?) ?? 'pending',
      severity: (data['severity'] as String?) ?? 'medium',
    );
  }

  String get timeAgo {
    final duration = DateTime.now().difference(createdAt);
    if (duration.inMinutes < 60) return '${duration.inMinutes} min ago';
    if (duration.inHours < 24) return '${duration.inHours} hours ago';
    return '${duration.inDays} days ago';
  }
}
