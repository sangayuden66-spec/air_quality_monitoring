import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/air_quality_model.dart';

class AirQualityService {
  static const String _baseUrl = 'https://air-quality-api.open-meteo.com/v1/air-quality';

  /// Fetches current air quality data for the given coordinates.
  /// Uses the US AQI standard as requested.
  Future<AirQualityModel> fetchCurrentAirQuality(double lat, double lon) async {
    final url = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lon&current=pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone,us_aqi&timezone=auto',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AirQualityModel.fromJson(data);
      } else {
        throw Exception('Failed to load air quality data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching air quality data: $e');
    }
  }
}
