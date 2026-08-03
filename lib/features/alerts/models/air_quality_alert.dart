import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType { alert, summary, health }

class AirQualityAlert {
  final String id;
  final String userId;
  final int aqi;
  final String category;
  final String message;
  final String location;
  final DateTime createdAt;
  final bool isRead;
  final AlertType type;

  AirQualityAlert({
    required this.id,
    required this.userId,
    required this.aqi,
    required this.category,
    required this.message,
    required this.location,
    required this.createdAt,
    this.isRead = false,
    this.type = AlertType.alert,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'aqi': aqi,
      'category': category,
      'message': message,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'type': type.name,
    };
  }

  factory AirQualityAlert.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AirQualityAlert(
      id: doc.id,
      userId: data['userId'] ?? '',
      aqi: data['aqi'] ?? 0,
      category: data['category'] ?? '',
      message: data['message'] ?? '',
      location: data['location'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      type: AlertType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'alert'),
        orElse: () => AlertType.alert,
      ),
    );
  }

  AirQualityAlert copyWith({
    String? id,
    String? userId,
    int? aqi,
    String? category,
    String? message,
    String? location,
    DateTime? createdAt,
    bool? isRead,
    AlertType? type,
  }) {
    return AirQualityAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      aqi: aqi ?? this.aqi,
      category: category ?? this.category,
      message: message ?? this.message,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}
