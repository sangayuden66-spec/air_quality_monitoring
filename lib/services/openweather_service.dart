import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models/air_quality_model.dart';

class OpenWeatherService {
  static const String _apiKey = 'b544fe3d20b5b5095b673ae226259ab0';

  Future<AirQualityModel> fetchAirQuality({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'api.openweathermap.org',
      '/data/2.5/air_pollution',
      {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'appid': _apiKey, 
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _mapToAirQualityModel(data, latitude, longitude);
      } else if (response.statusCode == 401) {
        throw Exception('API Key rejected. Note: New OpenWeather keys can take 2 hours to activate.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('host lookup')) {
        throw Exception('Connection failed. Please ensure your emulator has internet access.');
      }
      throw Exception('Failed to connect to OpenWeather: $e');
    }
  }

  AirQualityModel _mapToAirQualityModel(Map<String, dynamic> json, double lat, double lon) {
    final list = json['list'] as List;
    if (list.isEmpty) throw Exception('No data available for this location.');
    
    final current = list[0];
    final main = current['main'];
    final components = current['components'];
    final int rawIndex = main['aqi'] as int; // OpenWeather scale 1-5

    // Map 1-5 to a 0-500 scale for legacy UI compatibility
    int mappedAqi;
    switch (rawIndex) {
      case 1: mappedAqi = 30; break;
      case 2: mappedAqi = 75; break;
      case 3: mappedAqi = 125; break;
      case 4: mappedAqi = 175; break;
      case 5: mappedAqi = 250; break;
      default: mappedAqi = 0;
    }

    return AirQualityModel(
      latitude: lat,
      longitude: lon,
      aqi: mappedAqi,
      aqiIndex: rawIndex, // Store the 1-5 index for threshold checking
      pm25: (components['pm2_5'] as num).toDouble(),
      pm10: (components['pm10'] as num).toDouble(),
      co: (components['co'] as num).toDouble(),
      no2: (components['no2'] as num).toDouble(),
      so2: (components['so2'] as num).toDouble(),
      o3: (components['o3'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(current['dt'] * 1000),
    );
  }
}
