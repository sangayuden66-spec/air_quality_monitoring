class ItSettingsPreferences {
  final bool criticalSystemAlerts;
  final bool newSupportTickets;
  final bool maintenanceReminders;
  final bool dailyEmailDigest;
  final bool compactView;

  const ItSettingsPreferences({
    required this.criticalSystemAlerts,
    required this.newSupportTickets,
    required this.maintenanceReminders,
    required this.dailyEmailDigest,
    required this.compactView,
  });

  static const ItSettingsPreferences defaults = ItSettingsPreferences(
    criticalSystemAlerts: true,
    newSupportTickets: true,
    maintenanceReminders: true,
    dailyEmailDigest: false,
    compactView: false,
  );

  ItSettingsPreferences copyWith({
    bool? criticalSystemAlerts,
    bool? newSupportTickets,
    bool? maintenanceReminders,
    bool? dailyEmailDigest,
    bool? compactView,
  }) {
    return ItSettingsPreferences(
      criticalSystemAlerts: criticalSystemAlerts ?? this.criticalSystemAlerts,
      newSupportTickets: newSupportTickets ?? this.newSupportTickets,
      maintenanceReminders: maintenanceReminders ?? this.maintenanceReminders,
      dailyEmailDigest: dailyEmailDigest ?? this.dailyEmailDigest,
      compactView: compactView ?? this.compactView,
    );
  }

  Map<String, dynamic> toMap() => {
    'criticalSystemAlerts': criticalSystemAlerts,
    'newSupportTickets': newSupportTickets,
    'maintenanceReminders': maintenanceReminders,
    'dailyEmailDigest': dailyEmailDigest,
    'compactView': compactView,
  };

  factory ItSettingsPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return defaults;
    return ItSettingsPreferences(
      criticalSystemAlerts:
      map['criticalSystemAlerts'] as bool? ?? defaults.criticalSystemAlerts,
      newSupportTickets:
      map['newSupportTickets'] as bool? ?? defaults.newSupportTickets,
      maintenanceReminders:
      map['maintenanceReminders'] as bool? ?? defaults.maintenanceReminders,
      dailyEmailDigest:
      map['dailyEmailDigest'] as bool? ?? defaults.dailyEmailDigest,
      compactView: map['compactView'] as bool? ?? defaults.compactView,
    );
  }
}