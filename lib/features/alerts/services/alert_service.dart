import '../models/air_quality_alert.dart';

class AlertService {
  // Mock data matching the reference image provided by the user
  final List<AirQualityAlert> _mockAlerts = [
    AirQualityAlert(
      id: '1',
      userId: 'user123',
      aqi: 75,
      category: 'Moderate',
      message: 'PM2.5 levels are moderate in your area',
      location: 'Current Area',
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      isRead: false,
      type: AlertType.alert,
    ),
    AirQualityAlert(
      id: '2',
      userId: 'user123',
      aqi: 45,
      category: 'Good',
      message: 'Air quality has improved from yesterday',
      location: 'Current Area',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      type: AlertType.summary,
    ),
    AirQualityAlert(
      id: '3',
      userId: 'user123',
      aqi: 0,
      category: 'N/A',
      message: 'Consider wearing a mask during outdoor activities',
      location: 'Current Area',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: true,
      type: AlertType.health,
    ),
    AirQualityAlert(
      id: '4',
      userId: 'user123',
      aqi: 160,
      category: 'Unhealthy',
      message: 'AQI levels expected to rise in the evening',
      location: 'Current Area',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
      type: AlertType.alert,
    ),
  ];

  Stream<List<AirQualityAlert>> getAlertsStream() {
    return Stream.value(_mockAlerts);
  }

  Future<void> checkAndGenerateAlert(String location, int aqi) async {
    // Mock implementation
  }

  Future<void> saveAlert(AirQualityAlert alert) async {
    // Mock implementation
  }

  Future<void> markAsRead(String alertId) async {
    // Mock implementation
  }

  Future<void> deleteAlert(String alertId) async {
    // Mock implementation
  }

  Stream<int> getUnreadCount() {
    return Stream.value(_mockAlerts.where((a) => !a.isRead).length);
  }

  Future<void> savePreferences({
    required bool enabled,
    required int threshold,
    required bool sensitiveGroupAlerts,
  }) async {
    // Mock implementation
  }

  Future<Map<String, dynamic>?> getPreferences() async {
    return {
      'enabled': true,
      'threshold': 100,
      'sensitiveGroupAlerts': true,
    };
  }
}
