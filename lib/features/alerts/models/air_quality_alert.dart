import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType { alert, summary, health }

class AirQualityAlert {
  final String id;
  final int aqi;
  final int aqiIndex;
  final String category;
  final String message;
  final String location;
  final DateTime createdAt;
  final bool isRead;
  final AlertType type;
  final String? healthAdvice;
  final int triggeredThreshold;
  final Map<String, double> pollutants;

  AirQualityAlert({
    required this.id,
    required this.aqi,
    required this.aqiIndex,
    required this.category,
    required this.message,
    required this.location,
    required this.createdAt,
    this.isRead = false,
    this.type = AlertType.alert,
    this.healthAdvice,
    this.triggeredThreshold = 0,
    this.pollutants = const {},
  });

  factory AirQualityAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AirQualityAlert(
      id: doc.id,
      aqi: (data['aqi'] as num?)?.toInt() ?? 0,
      aqiIndex: (data['aqiIndex'] as num?)?.toInt() ?? 0,
      category: data['category'] ?? 'Alert',
      message:
          data['message'] ??
          (data['healthAdvice'] ?? 'High pollution level detected'),
      location: data['locationName'] ?? data['location'] ?? 'Unknown',
      createdAt:
          (data['timestamp'] as Timestamp? ??
                  data['createdAt'] as Timestamp? ??
                  Timestamp.now())
              .toDate(),
      isRead: data['isRead'] ?? false,
      type: _parseType(data['type']),
      healthAdvice: data['healthAdvice'],
      triggeredThreshold:
          (data['threshold'] as num?)?.toInt() ??
          (data['triggeredThreshold'] as num?)?.toInt() ??
          0,
      pollutants: Map<String, double>.from(data['pollutants'] ?? {}),
    );
  }

  static AlertType _parseType(dynamic type) {
    if (type == null) return AlertType.alert;
    final normalized = type.toString().toLowerCase();
    if (normalized == 'summary') return AlertType.summary;
    if (normalized == 'health' || normalized == 'healthadvice') {
      return AlertType.health;
    }
    return AlertType.alert;
  }
}
