class AirQualityModel {
  final double latitude;
  final double longitude;
  final int aqi; // US AQI (0-500) for display
  final int aqiIndex; // OpenWeather index (1-5) for logic
  final double pm25;
  final double pm10;
  final double co;
  final double no2;
  final double so2;
  final double o3;
  final DateTime timestamp;

  AirQualityModel({
    required this.latitude,
    required this.longitude,
    required this.aqi,
    required this.aqiIndex,
    required this.pm25,
    required this.pm10,
    required this.co,
    required this.no2,
    required this.so2,
    required this.o3,
    required this.timestamp,
  });

  String get aqiCategory {
    switch (aqiIndex) {
      case 1: return 'Good';
      case 2: return 'Fair';
      case 3: return 'Moderate';
      case 4: return 'Poor';
      case 5: return 'Dangerous / Hazardous';
      default: return 'Unknown';
    }
  }

  String get healthAdvice {
    switch (aqiIndex) {
      case 1:
        return 'Air quality is good. Normal outdoor activities are suitable.';
      case 2:
        return 'Air quality is generally acceptable. Sensitive people should monitor symptoms.';
      case 3:
        return 'Sensitive people should reduce prolonged or strenuous outdoor activity.';
      case 4:
        return 'POOR AIR QUALITY: Wear a mask outdoors. Limit time outside and keep windows closed.';
      case 5:
        return 'DANGEROUS AIR QUALITY: Stay indoors! Use air purifiers, keep all windows closed, and wear a N95 mask if you must step out.';
      default:
        return 'General guidance only. Follow local health and emergency-service advice.';
    }
  }
}
