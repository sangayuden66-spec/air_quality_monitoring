import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationHistoryItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final int aqi;
  final String category;
  final int threshold;
  final String locationName;
  final double latitude;
  final double longitude;
  final String healthAdvice;
  final Map<String, double> pollutants;
  final DateTime createdAt;
  final bool isRead;
  final String? alertId;

  const NotificationHistoryItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.aqi,
    required this.category,
    required this.threshold,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.healthAdvice,
    required this.pollutants,
    required this.createdAt,
    required this.isRead,
    this.alertId,
  });

  int get aqiIndex => aqi;

  factory NotificationHistoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? <String, dynamic>{});
    final timestamp =
        data['createdAt'] as Timestamp? ?? data['timestamp'] as Timestamp?;
    final rawPollutants = data['pollutants'];

    return NotificationHistoryItem(
      id: doc.id,
      type: (data['type'] ?? 'airQualityAlert').toString(),
      title: (data['title'] ?? data['category'] ?? 'Air Quality Alert')
          .toString(),
      message: (data['message'] ?? data['healthAdvice'] ?? '').toString(),
      aqi:
          (data['aqi'] as num?)?.toInt() ??
          (data['aqiIndex'] as num?)?.toInt() ??
          0,
      category: (data['category'] ?? 'Unknown').toString(),
      threshold:
          (data['threshold'] as num?)?.toInt() ??
          (data['triggeredThreshold'] as num?)?.toInt() ??
          0,
      locationName: (data['locationName'] ?? data['location'] ?? 'Unknown')
          .toString(),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      healthAdvice: (data['healthAdvice'] ?? '').toString(),
      pollutants: _toDoubleMap(rawPollutants),
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] == true,
      alertId: data['alertId']?.toString(),
    );
  }

  static Map<String, double> _toDoubleMap(dynamic raw) {
    if (raw is! Map) return const {};
    final normalized = <String, double>{};
    raw.forEach((key, value) {
      final numeric = value is num
          ? value.toDouble()
          : double.tryParse(value.toString());
      if (numeric != null) {
        normalized[key.toString()] = numeric;
      }
    });
    return normalized;
  }
}
