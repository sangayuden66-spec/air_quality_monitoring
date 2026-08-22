import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/it_system_config.dart';

class ItSystemConfigService {
  ItSystemConfigService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('systemConfig').doc('settings');

  Stream<ItSystemConfig> watchConfig() {
    return _doc.snapshots().map((doc) => ItSystemConfig.fromMap(doc.data()));
  }

  Future<void> saveApiSettings({
    required String apiKey,
    required String apiEndpointUrl,
    required int timeoutSeconds,
    required int maxRetries,
  }) {
    return _doc.set({
      'apiKey': apiKey,
      'apiEndpointUrl': apiEndpointUrl,
      'timeoutSeconds': timeoutSeconds,
      'maxRetries': maxRetries,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveAqiThresholds(AqiThresholds thresholds) {
    return _doc.set({
      'aqiThresholds': thresholds.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveNotificationSettings(ItNotificationSettings settings) {
    return _doc.set({
      'notifications': settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}