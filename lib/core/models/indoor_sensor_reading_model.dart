import 'package:cloud_firestore/cloud_firestore.dart';

class IndoorSensorReadingModel {
  final double aqi;
  final String aqiRating;
  final double tvoc;
  final double eco2;
  final String eco2Rating;
  final String status;
  final DateTime timestamp;

  const IndoorSensorReadingModel({
    required this.aqi,
    required this.aqiRating,
    required this.tvoc,
    required this.eco2,
    required this.eco2Rating,
    required this.status,
    required this.timestamp,
  });

  factory IndoorSensorReadingModel.fromMap(
      Map<String, dynamic> data,
      ) {
    final Timestamp? timestamp = data['timestamp'] as Timestamp?;

    return IndoorSensorReadingModel(
      aqi: (data['aqi_value'] as num?)?.toDouble() ?? 0,
      aqiRating: data['aqi_rating']?.toString() ?? 'Unknown',
      tvoc: (data['tvoc'] as num?)?.toDouble() ?? 0,
      eco2: (data['eco2_value'] as num?)?.toDouble() ?? 0,
      eco2Rating:
      data['eco2_rating']?.toString() ?? 'Unknown',
      status: data['status']?.toString() ?? 'Unknown',
      timestamp: timestamp?.toDate() ?? DateTime.now(),
    );
  }
}