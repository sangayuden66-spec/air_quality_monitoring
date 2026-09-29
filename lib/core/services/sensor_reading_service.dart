import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensor_average_model.dart';

class SensorReadingService {
  final FirebaseFirestore _firestore;

  SensorReadingService({
    FirebaseFirestore? firestore,
  }) : _firestore =
      firestore ?? FirebaseFirestore.instance;

  Stream<SensorAverageModel?> watchLatestAverage() {
    return _firestore
        .collection('sensor_readings')
        .doc('latest_average')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();

      if (data == null) {
        return null;
      }

      return SensorAverageModel.fromMap(data);
    });
  }

  Stream<List<SensorAverageModel>> watchAverageHistory({
    int limit = 12,
  }) {
    return _firestore
        .collection('sensor_readings')
        .doc('averages')
        .collection('log')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final readings = snapshot.docs
          .map(
            (document) =>
            SensorAverageModel.fromMap(document.data()),
      )
          .toList();

      return readings.reversed.toList();
    });
  }
}