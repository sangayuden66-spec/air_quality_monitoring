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

  Future<List<AirQualityModel>> fetchAirQualityForecast({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'api.openweathermap.org',
      '/data/2.5/air_pollution/forecast',
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
        final list = (data['list'] as List?) ?? [];
        return list
            .map((entry) => _mapListItemToAirQualityModel(entry, latitude, longitude))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('API Key rejected. Note: New OpenWeather keys can take 2 hours to activate.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('host lookup')) {
        throw Exception('Connection failed. Please ensure your emulator has internet access.');
      }
      throw Exception('Failed to connect to OpenWeather forecast: $e');
    }
  }

  Future<List<AirQualityModel>> fetchAirQualityHistory({
    required double latitude,
    required double longitude,
    required DateTime start,
    required DateTime end,
  }) async {
    if (!start.isBefore(end)) {
      throw Exception('History start time must be before end time.');
    }

    final uri = Uri.https(
      'api.openweathermap.org',
      '/data/2.5/air_pollution/history',
      {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'start': (start.toUtc().millisecondsSinceEpoch ~/ 1000).toString(),
        'end': (end.toUtc().millisecondsSinceEpoch ~/ 1000).toString(),
        'appid': _apiKey,
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['list'] as List?) ?? [];
        return list
            .map((entry) => _mapListItemToAirQualityModel(entry, latitude, longitude))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('API Key rejected. Note: New OpenWeather keys can take 2 hours to activate.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('host lookup')) {
        throw Exception('Connection failed. Please ensure your emulator has internet access.');
      }
      throw Exception('Failed to connect to OpenWeather history: $e');
    }
  }

  AirQualityModel _mapToAirQualityModel(Map<String, dynamic> json, double lat, double lon) {
    final list = json['list'] as List;
    if (list.isEmpty) throw Exception('No data available for this location.');
    
    final current = list[0] as Map<String, dynamic>;
    return _mapListItemToAirQualityModel(current, lat, lon);
  }

  AirQualityModel _mapListItemToAirQualityModel(Map<String, dynamic> item, double lat, double lon) {
    final main = item['main'] as Map<String, dynamic>;
    final components = item['components'] as Map<String, dynamic>;
    final int rawIndex = main['aqi'] as int; // OpenWeather scale 1-5
    final mappedAqi = _mapAqiIndexToAqi(rawIndex);

    return AirQualityModel(
      latitude: lat,
      longitude: lon,
      aqi: mappedAqi,
      aqiIndex: rawIndex,
      pm25: (components['pm2_5'] as num).toDouble(),
      pm10: (components['pm10'] as num).toDouble(),
      co: (components['co'] as num).toDouble(),
      no2: (components['no2'] as num).toDouble(),
      so2: (components['so2'] as num).toDouble(),
      o3: (components['o3'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch((item['dt'] as int) * 1000),
    );
  }

  int _mapAqiIndexToAqi(int rawIndex) {
    switch (rawIndex) {
      case 1:
        return 30;
      case 2:
        return 75;
      case 3:
        return 125;
      case 4:
        return 175;
      case 5:
        return 250;
      default:
        return 0;
    }
  }
}
