class HealthAdviceHelper {
  static String getCategory(int index) {
    switch (index) {
      case 1: return 'Good';
      case 2: return 'Fair';
      case 3: return 'Moderate';
      case 4: return 'Poor';
      case 5: return 'Very Poor';
      default: return 'Unknown';
    }
  }

  static String getAdvice(int index) {
    switch (index) {
      case 1:
        return 'Air quality is good. Normal outdoor activities are suitable.';
      case 2:
        return 'Air quality is generally acceptable. Sensitive people should monitor symptoms.';
      case 3:
        return 'Sensitive people should reduce prolonged or strenuous outdoor activity.';
      case 4:
        return 'Poor air quality. Limit outdoor activity, keep windows closed, and wear a N95 mask if you must go outside.';
      case 5:
        return 'Dangerous air quality! Avoid all strenuous outdoor activity. Remain indoors with windows closed, use air purifiers, and wear a mask if outside.';
      default:
        return 'General guidance only. Follow local health and emergency-service advice.';
    }
  }
  
  static const String disclaimer = 'General guidance only. Follow local health and emergency-service advice.';
}
