import '../models/air_quality_model.dart';
import '../../services/openweather_service.dart';

class AirQualityService {
  final OpenWeatherService _openWeatherService = OpenWeatherService();

  /// Fetches current air quality data for the given coordinates using OpenWeather API.
  Future<AirQualityModel> fetchCurrentAirQuality(double lat, double lon) async {
    try {
      return await _openWeatherService.fetchAirQuality(
        latitude: lat,
        longitude: lon,
      );
    } catch (e) {
      // Re-throw with a descriptive message if needed
      throw Exception('Failed to fetch air quality from OpenWeather: $e');
    }
  }
}
