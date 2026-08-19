import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationHistoryItem {
  final String id;
  final int aqiIndex; // 1-5
  final String category;
  final String location;
  final String healthAdvice;
  final int triggeredThreshold;
  final Map<String, double> pollutants;
  final DateTime timestamp;
  final bool isRead;

  NotificationHistoryItem({
    required this.id,
    required this.aqiIndex,
    required this.category,
    required this.location,
    required this.healthAdvice,
    required this.triggeredThreshold,
    required this.pollutants,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationHistoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationHistoryItem(
      id: doc.id,
      aqiIndex: (data['aqiIndex'] as num?)?.toInt() ?? 0,
      category: data['category'] ?? 'Unknown',
      location: data['location'] ?? 'Unknown',
      healthAdvice: data['healthAdvice'] ?? '',
      triggeredThreshold: (data['triggeredThreshold'] as num?)?.toInt() ?? 0,
      pollutants: Map<String, double>.from(data['pollutants'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }
}
