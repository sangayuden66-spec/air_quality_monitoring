class AirQualityModel {
  final double latitude;
  final double longitude;
  final int aqi;
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
    required this.pm25,
    required this.pm10,
    required this.co,
    required this.no2,
    required this.so2,
    required this.o3,
    required this.timestamp,
  });

  factory AirQualityModel.fromJson(Map<String, dynamic> json) {
    // Open-Meteo current_air_quality data structure
    final current = json['current'];
    return AirQualityModel(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      aqi: current['us_aqi']?.toInt() ?? 0,
      pm25: current['pm2_5']?.toDouble() ?? 0.0,
      pm10: current['pm10']?.toDouble() ?? 0.0,
      co: current['carbon_monoxide']?.toDouble() ?? 0.0,
      no2: current['nitrogen_dioxide']?.toDouble() ?? 0.0,
      so2: current['sulphur_dioxide']?.toDouble() ?? 0.0,
      o3: current['ozone']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(current['time']),
    );
  }

  String get aqiCategory {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }
}
