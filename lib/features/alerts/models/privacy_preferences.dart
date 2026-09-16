class PrivacyPreferences {
  final bool usageAnalytics;
  final bool crashReports;
  final bool personalizedRecommendations;
  final bool shareAnonymizedAirData;

  const PrivacyPreferences({
    required this.usageAnalytics,
    required this.crashReports,
    required this.personalizedRecommendations,
    required this.shareAnonymizedAirData,
  });

  static const PrivacyPreferences defaults = PrivacyPreferences(
    usageAnalytics: true,
    crashReports: true,
    personalizedRecommendations: true,
    shareAnonymizedAirData: false,
  );

  PrivacyPreferences copyWith({
    bool? usageAnalytics,
    bool? crashReports,
    bool? personalizedRecommendations,
    bool? shareAnonymizedAirData,
  }) {
    return PrivacyPreferences(
      usageAnalytics: usageAnalytics ?? this.usageAnalytics,
      crashReports: crashReports ?? this.crashReports,
      personalizedRecommendations:
          personalizedRecommendations ?? this.personalizedRecommendations,
      shareAnonymizedAirData:
          shareAnonymizedAirData ?? this.shareAnonymizedAirData,
    );
  }

  Map<String, dynamic> toMap() => {
    'usageAnalytics': usageAnalytics,
    'crashReports': crashReports,
    'personalizedRecommendations': personalizedRecommendations,
    'shareAnonymizedAirData': shareAnonymizedAirData,
  };

  factory PrivacyPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return defaults;
    return PrivacyPreferences(
      usageAnalytics: map['usageAnalytics'] as bool? ?? defaults.usageAnalytics,
      crashReports: map['crashReports'] as bool? ?? defaults.crashReports,
      personalizedRecommendations:
          map['personalizedRecommendations'] as bool? ??
          defaults.personalizedRecommendations,
      shareAnonymizedAirData:
          map['shareAnonymizedAirData'] as bool? ??
          defaults.shareAnonymizedAirData,
    );
  }
}
