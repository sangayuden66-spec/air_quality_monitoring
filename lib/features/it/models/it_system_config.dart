class AqiThresholds {
  final int good;
  final int moderate;
  final int unhealthyForSensitive;
  final int unhealthy;
  final int veryUnhealthy;

  const AqiThresholds({
    required this.good,
    required this.moderate,
    required this.unhealthyForSensitive,
    required this.unhealthy,
    required this.veryUnhealthy,
  });

  static const AqiThresholds defaults = AqiThresholds(
    good: 50,
    moderate: 100,
    unhealthyForSensitive: 150,
    unhealthy: 200,
    veryUnhealthy: 300,
  );

  Map<String, dynamic> toMap() => {
    'good': good,
    'moderate': moderate,
    'unhealthyForSensitive': unhealthyForSensitive,
    'unhealthy': unhealthy,
    'veryUnhealthy': veryUnhealthy,
  };

  factory AqiThresholds.fromMap(Map<String, dynamic>? map) {
    if (map == null) return defaults;
    return AqiThresholds(
      good: (map['good'] as num?)?.toInt() ?? defaults.good,
      moderate: (map['moderate'] as num?)?.toInt() ?? defaults.moderate,
      unhealthyForSensitive:
      (map['unhealthyForSensitive'] as num?)?.toInt() ??
          defaults.unhealthyForSensitive,
      unhealthy: (map['unhealthy'] as num?)?.toInt() ?? defaults.unhealthy,
      veryUnhealthy:
      (map['veryUnhealthy'] as num?)?.toInt() ?? defaults.veryUnhealthy,
    );
  }
}

class ItNotificationSettings {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final int updateFrequencyMinutes;
  final int criticalAlertThreshold;

  const ItNotificationSettings({
    required this.pushEnabled,
    required this.emailEnabled,
    required this.smsEnabled,
    required this.updateFrequencyMinutes,
    required this.criticalAlertThreshold,
  });

  static const ItNotificationSettings defaults = ItNotificationSettings(
    pushEnabled: true,
    emailEnabled: true,
    smsEnabled: false,
    updateFrequencyMinutes: 15,
    criticalAlertThreshold: 200,
  );

  Map<String, dynamic> toMap() => {
    'pushEnabled': pushEnabled,
    'emailEnabled': emailEnabled,
    'smsEnabled': smsEnabled,
    'updateFrequencyMinutes': updateFrequencyMinutes,
    'criticalAlertThreshold': criticalAlertThreshold,
  };

  factory ItNotificationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return defaults;
    return ItNotificationSettings(
      pushEnabled: map['pushEnabled'] as bool? ?? defaults.pushEnabled,
      emailEnabled: map['emailEnabled'] as bool? ?? defaults.emailEnabled,
      smsEnabled: map['smsEnabled'] as bool? ?? defaults.smsEnabled,
      updateFrequencyMinutes: (map['updateFrequencyMinutes'] as num?)?.toInt() ??
          defaults.updateFrequencyMinutes,
      criticalAlertThreshold:
      (map['criticalAlertThreshold'] as num?)?.toInt() ??
          defaults.criticalAlertThreshold,
    );
  }
}

class ItSystemConfig {
  final String apiKey;
  final String apiEndpointUrl;
  final int timeoutSeconds;
  final int maxRetries;
  final AqiThresholds thresholds;
  final ItNotificationSettings notifications;

  const ItSystemConfig({
    required this.apiKey,
    required this.apiEndpointUrl,
    required this.timeoutSeconds,
    required this.maxRetries,
    required this.thresholds,
    required this.notifications,
  });

  static const ItSystemConfig defaults = ItSystemConfig(
    apiKey: '',
    apiEndpointUrl: '',
    timeoutSeconds: 30,
    maxRetries: 3,
    thresholds: AqiThresholds.defaults,
    notifications: ItNotificationSettings.defaults,
  );

  factory ItSystemConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return defaults;
    return ItSystemConfig(
      apiKey: (map['apiKey'] as String?) ?? defaults.apiKey,
      apiEndpointUrl:
      (map['apiEndpointUrl'] as String?) ?? defaults.apiEndpointUrl,
      timeoutSeconds:
      (map['timeoutSeconds'] as num?)?.toInt() ?? defaults.timeoutSeconds,
      maxRetries: (map['maxRetries'] as num?)?.toInt() ?? defaults.maxRetries,
      thresholds:
      AqiThresholds.fromMap(map['aqiThresholds'] as Map<String, dynamic>?),
      notifications: ItNotificationSettings.fromMap(
          map['notifications'] as Map<String, dynamic>?),
    );
  }
}