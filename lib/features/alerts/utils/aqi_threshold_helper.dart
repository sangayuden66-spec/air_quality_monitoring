import 'package:flutter/material.dart';

enum AQICategory {
  good,
  moderate,
  unhealthyForSensitiveGroups,
  unhealthy,
  veryUnhealthy,
  hazardous,
}

class AQIThresholdHelper {
  static AQICategory getCategory(int aqi) {
    if (aqi <= 50) return AQICategory.good;
    if (aqi <= 100) return AQICategory.moderate;
    if (aqi <= 150) return AQICategory.unhealthyForSensitiveGroups;
    if (aqi <= 200) return AQICategory.unhealthy;
    if (aqi <= 300) return AQICategory.veryUnhealthy;
    return AQICategory.hazardous;
  }

  static String getCategoryName(AQICategory category) {
    switch (category) {
      case AQICategory.good:
        return 'Good';
      case AQICategory.moderate:
        return 'Moderate';
      case AQICategory.unhealthyForSensitiveGroups:
        return 'Unhealthy for Sensitive Groups';
      case AQICategory.unhealthy:
        return 'Unhealthy';
      case AQICategory.veryUnhealthy:
        return 'Very Unhealthy';
      case AQICategory.hazardous:
        return 'Hazardous';
    }
  }

  static Color getCategoryColor(AQICategory category) {
    switch (category) {
      case AQICategory.good:
        return Colors.green;
      case AQICategory.moderate:
        return Colors.yellow.shade700;
      case AQICategory.unhealthyForSensitiveGroups:
        return Colors.orange;
      case AQICategory.unhealthy:
        return Colors.red;
      case AQICategory.veryUnhealthy:
        return Colors.purple;
      case AQICategory.hazardous:
        return const Color(0xFF800000); // Maroon
    }
  }

  static IconData getCategoryIcon(AQICategory category) {
    switch (category) {
      case AQICategory.good:
        return Icons.sentiment_very_satisfied;
      case AQICategory.moderate:
        return Icons.sentiment_satisfied;
      case AQICategory.unhealthyForSensitiveGroups:
        return Icons.sentiment_neutral;
      case AQICategory.unhealthy:
        return Icons.sentiment_dissatisfied;
      case AQICategory.veryUnhealthy:
        return Icons.sentiment_very_dissatisfied;
      case AQICategory.hazardous:
        return Icons.warning;
    }
  }

  static String getHealthGuidance(AQICategory category) {
    switch (category) {
      case AQICategory.good:
        return 'Air quality is considered satisfactory, and air pollution poses little or no risk.';
      case AQICategory.moderate:
        return 'Air quality is acceptable; however, for some pollutants, there may be a moderate health concern for a very small number of people who are unusually sensitive to air pollution.';
      case AQICategory.unhealthyForSensitiveGroups:
        return 'Members of sensitive groups may experience health effects. The general public is not likely to be affected.';
      case AQICategory.unhealthy:
        return 'Everyone may begin to experience health effects; members of sensitive groups may experience more serious health effects.';
      case AQICategory.veryUnhealthy:
        return 'Health alert: everyone may experience more serious health effects.';
      case AQICategory.hazardous:
        return 'Health warnings of emergency conditions. The entire population is more likely to be affected.';
    }
  }
}
