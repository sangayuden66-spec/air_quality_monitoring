import 'package:cloud_firestore/cloud_firestore.dart';

class SensorAverageModel {
  final double averageAqi;
  final double averageEco2;
  final double averageTvoc;
  final int sampleCount;
  final DateTime timestamp;

  const SensorAverageModel({
    required this.averageAqi,
    required this.averageEco2,
    required this.averageTvoc,
    required this.sampleCount,
    required this.timestamp,
  });

  factory SensorAverageModel.fromMap(Map<String, dynamic> data) {
    final Timestamp? firestoreTimestamp =
    data['timestamp'] as Timestamp?;

    return SensorAverageModel(
      averageAqi:
      (data['avg_aqi'] as num?)?.toDouble() ?? 0.0,
      averageEco2:
      (data['avg_eco2'] as num?)?.toDouble() ?? 0.0,
      averageTvoc:
      (data['avg_tvoc'] as num?)?.toDouble() ?? 0.0,
      sampleCount:
      (data['sample_count'] as num?)?.toInt() ?? 0,
      timestamp:
      firestoreTimestamp?.toDate() ?? DateTime.now(),
    );
  }
}