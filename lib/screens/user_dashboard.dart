import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/models/air_quality_model.dart';
import '../core/models/sensor_average_model.dart';
import '../core/services/air_quality_service.dart';
import '../core/services/sensor_reading_service.dart';
import '../core/services/notification_service.dart';
import '../features/alerts/services/alert_service.dart';
import '../core/models/report_item.dart';
import '../core/services/report_service.dart';
import '../core/theme/app_theme.dart';

enum _AirQualityMode { indoor, outdoor }

int _toFivePointAqi(int usAqi) {
  if (usAqi <= 50) return 1;
  if (usAqi <= 100) return 2;
  if (usAqi <= 150) return 3;
  if (usAqi <= 200) return 4;
  return 5;
}

String _fivePointAqiCategory(int aqi) {
  switch (aqi) {
    case 1:
      return 'Good';
    case 2:
      return 'Fair';
    case 3:
      return 'Moderate';
    case 4:
      return 'Poor';
    default:
      return 'Very Poor';
  }
}

Color _fivePointAqiColor(int aqi) {
  switch (aqi) {
    case 1:
      return Colors.green;
    case 2:
      return Colors.yellow.shade700;
    case 3:
      return Colors.orange;
    case 4:
      return Colors.red;
    default:
      return Colors.purple;
  }
}

class UserDashboard extends StatefulWidget {
  final LatLng location;
  final VoidCallback? onViewAllReports;
  final VoidCallback? onViewMap;

  const UserDashboard({
    super.key,
    required this.location,
    this.onViewAllReports,
    this.onViewMap,
  });

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final AirQualityService _aqiService = AirQualityService();
  final NotificationService _notificationService = NotificationService();
  final AlertService _alertService = AlertService();
  final SensorReadingService _sensorReadingService = SensorReadingService();

  AirQualityModel? _data;
  List<AirQualityModel> _historyData = [];
  bool _isLoading = true;
  String? _error;
  DateTime? _outdoorLastUpdated;
  String _locationName = 'Finding location…';
  _AirQualityMode _selectedMode = _AirQualityMode.indoor;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadLocationName();
  }

  @override
  void didUpdateWidget(UserDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _fetchData();
      _loadLocationName();
    }
  }

  Future<void> _loadLocationName() async {
    try {
      final placemarks = await placemarkFromCoordinates(
        widget.location.latitude,
        widget.location.longitude,
      );

      if (!mounted) return;

      if (placemarks.isEmpty) {
        setState(() => _locationName = 'Current location');
        return;
      }

      final place = placemarks.first;
      final parts = <String>[
        if (place.locality?.trim().isNotEmpty == true) place.locality!.trim(),
        if (place.administrativeArea?.trim().isNotEmpty == true)
          place.administrativeArea!.trim(),
      ];

      setState(() {
        _locationName = parts.isEmpty
            ? (place.country?.trim().isNotEmpty == true
            ? place.country!.trim()
            : 'Current location')
            : parts.toSet().join(', ');
      });
    } catch (error) {
      debugPrint('Location name lookup failed: $error');
      if (mounted) {
        setState(() => _locationName = 'Current location');
      }
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Fetch current AQI
      final current = await _aqiService.fetchCurrentAirQuality(
        widget.location.latitude,
        widget.location.longitude,
      );

      // 2. Fetch last 24 hours of history for the graph
      final now = DateTime.now();
      final history = await _aqiService.fetchAirQualityHistory(
        widget.location.latitude,
        widget.location.longitude,
        now.subtract(const Duration(hours: 24)),
        now,
      );

      if (!mounted) return;
      setState(() {
        _data = current;
        _historyData = history
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoading = false;
        _outdoorLastUpdated = DateTime.now();
      });

      await _checkAlertThreshold(current);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAlertThreshold(AirQualityModel currentData) async {
    final decision = await _alertService.processTriggeredAlert(
      data: currentData,
    );
    if (!decision.shouldNotify) return;

    try {
      await _notificationService.showAqiAlert(
        aqi: currentData.aqi,
        category: currentData.aqiCategory,
        advice: currentData.healthAdvice,
        location: decision.locationName,
      );
    } catch (e) {
      debugPrint('Local notification display failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        if (_selectedMode == _AirQualityMode.outdoor) {
          await _fetchData();
        }
      },
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AirQualityModeSelector(
                selectedMode: _selectedMode,
                onChanged: (mode) {
                  setState(() => _selectedMode = mode);
                },
              ),
              const SizedBox(height: 16),

              if (_selectedMode == _AirQualityMode.indoor) ...[
                _SensorAqiHeroCard(
                  stream: _sensorReadingService.watchLatestAverage(),
                  locationName: _locationName,
                ),
                const SizedBox(height: 16),
                _SensorAverageCard(
                  stream: _sensorReadingService.watchLatestAverage(),
                ),
                const SizedBox(height: 24),
              ] else if (_isLoading) ...[
                const _OutdoorLoadingCard(),
                const SizedBox(height: 24),
              ] else if (_error != null) ...[
                _OutdoorErrorCard(
                  message: _error!,
                  onRetry: _fetchData,
                ),
                const SizedBox(height: 24),
              ] else if (_data != null) ...[
                _OutdoorAqiHeroCard(
                  data: _data!,
                  lastUpdated: _outdoorLastUpdated,
                  locationName: _locationName,
                ),
                const SizedBox(height: 16),
                _PollutantGrid(data: _data!),
                const SizedBox(height: 24),
                _LocationPreview(
                  location: widget.location,
                  aqi: _toFivePointAqi(_data!.aqi),
                  onViewFull: widget.onViewMap,
                ),
                const SizedBox(height: 24),
                _HistoryChart(data: _historyData),
                const SizedBox(height: 24),
              ],

              _ReportsSection(onViewAll: widget.onViewAllReports),
              const SizedBox(height: 24),

              if (_selectedMode == _AirQualityMode.outdoor) ...[
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _fetchData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Outdoor Data'),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AirQualityModeSelector extends StatelessWidget {
  final _AirQualityMode selectedMode;
  final ValueChanged<_AirQualityMode> onChanged;

  const _AirQualityModeSelector({
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_AirQualityMode>(
      segments: const [
        ButtonSegment<_AirQualityMode>(
          value: _AirQualityMode.indoor,
          icon: Icon(Icons.home_outlined),
          label: Text('Indoor'),
        ),
        ButtonSegment<_AirQualityMode>(
          value: _AirQualityMode.outdoor,
          icon: Icon(Icons.public),
          label: Text('Outdoor'),
        ),
      ],
      selected: {selectedMode},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        onChanged(selection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.comfortable,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _OutdoorAqiHeroCard extends StatelessWidget {
  final AirQualityModel data;
  final DateTime? lastUpdated;
  final String locationName;

  const _OutdoorAqiHeroCard({
    required this.data,
    required this.locationName,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final outdoorAqi = _toFivePointAqi(data.aqi);
    final color = _fivePointAqiColor(outdoorAqi);
    final category = _fivePointAqiCategory(outdoorAqi);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Outdoor Air Quality',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            locationName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Outdoor AQI (1–5 Scale)',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            '$outdoorAqi',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          Text(
            category,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (lastUpdated != null) ...[
            const SizedBox(height: 16),
            Text(
              'Updated: ${DateFormat('hh:mm a').format(lastUpdated!)}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _OutdoorLoadingCard extends StatelessWidget {
  const _OutdoorLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        color: AppThemeColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 14),
          Text(
            'Loading outdoor air quality…',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _OutdoorErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _OutdoorErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemeColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 42, color: Colors.red),
          const SizedBox(height: 12),
          const Text(
            'Outdoor data is unavailable',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _SensorAqiHeroCard extends StatelessWidget {
  final Stream<SensorAverageModel?> stream;
  final String locationName;

  const _SensorAqiHeroCard({
    required this.stream,
    required this.locationName,
  });

  Color _getAqiColor(double aqi) {
    if (aqi < 1.5) return Colors.green;
    if (aqi < 2.5) return const Color(0xFF8A9A00);
    if (aqi < 3.5) return Colors.orange;
    if (aqi < 4.5) return Colors.red;
    return Colors.purple;
  }

  String _getAqiCategory(double aqi) {
    if (aqi < 1.5) return 'Excellent';
    if (aqi < 2.5) return 'Good';
    if (aqi < 3.5) return 'Moderate';
    if (aqi < 4.5) return 'Poor';
    return 'Unhealthy';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorAverageModel?>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildUnavailableCard(
            'Unable to load indoor AQI: ${snapshot.error}',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 270,
            decoration: BoxDecoration(
              color: AppThemeColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final sensorData = snapshot.data;
        if (sensorData == null) {
          return _buildUnavailableCard(
            'No indoor sensor average is available yet.',
          );
        }

        final aqi = sensorData.averageAqi.clamp(1.0, 5.0).toDouble();
        final color = _getAqiColor(aqi);
        final category = _getAqiCategory(aqi);
        final isStale = DateTime.now().difference(sensorData.timestamp) >
            const Duration(minutes: 10);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                'Indoor Air Quality',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                locationName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'AQI (1–5 Scale)',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    aqi.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8, left: 5),
                    child: Text(
                      '/ 5',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Average of ${sensorData.sampleCount} sensor readings',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                '${isStale ? 'Last reading' : 'Updated'}: ${DateFormat('dd MMM yyyy, hh:mm a').format(sensorData.timestamp)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isStale ? Colors.yellow.shade100 : Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnavailableCard(String message) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sensors_off_outlined,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _PollutantGrid extends StatelessWidget {
  final AirQualityModel data;
  const _PollutantGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final pollutants = [
      ('PM2.5', data.pm25, 'µg/m³'),
      ('PM10', data.pm10, 'µg/m³'),
      ('CO', data.co, 'µg/m³'),
      ('NO₂', data.no2, 'µg/m³'),
      ('SO₂', data.so2, 'µg/m³'),
      ('O₃', data.o3, 'µg/m³'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: pollutants.length,
      itemBuilder: (context, index) {
        final p = pollutants[index];
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppThemeColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  p.$1,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  p.$2.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  p.$3,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LocationPreview extends StatelessWidget {
  final LatLng location;
  final int aqi;
  final VoidCallback? onViewFull;

  const _LocationPreview({
    required this.location,
    required this.aqi,
    this.onViewFull,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  'Your Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            TextButton(onPressed: onViewFull, child: const Text('View Full')),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: AppThemeColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: location,
                    zoom: 12,
                  ),
                  liteModeEnabled: true,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  circles: {
                    Circle(
                      circleId: const CircleId('aqi_area'),
                      center: location,
                      radius: 2000,
                      fillColor: AppThemeColors.primary.withValues(alpha: 0.1),
                      strokeColor: AppThemeColors.primary.withValues(
                        alpha: 0.3,
                      ),
                      strokeWidth: 1,
                    ),
                  },
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$aqi',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.air,
                          size: 14,
                          color: AppThemeColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryChart extends StatelessWidget {
  final List<AirQualityModel> data;
  const _HistoryChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final sorted = [...data]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Outdoor AQI History (1–5)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppThemeColors.border),
          ),
          child: sorted.isEmpty
              ? const Center(child: Text('Fetching history...'))
              : LineChart(
            (() {
              final start = sorted.first.timestamp;
              final spots = sorted
                  .map(
                    (entry) => FlSpot(
                  entry.timestamp.difference(start).inMinutes / 60.0,
                  _toFivePointAqi(entry.aqi).toDouble(),
                ),
              )
                  .toList();
              final xMax = spots.last.x < 1 ? 1.0 : spots.last.x;

              return LineChartData(
                minX: 0,
                maxX: xMax,
                minY: 1,
                maxY: 5,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 1,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 6,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value > xMax) {
                          return const SizedBox.shrink();
                        }
                        final time = start.add(
                          Duration(minutes: (value * 60).round()),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('ha').format(time).toLowerCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppThemeColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(show: spots.length <= 2),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppThemeColors.primary.withValues(alpha: 0.2),
                          AppThemeColors.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              );
            })(),
          ),
        ),
        const SizedBox(height: 12),
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ChartLegend(color: Colors.green, label: 'Good'),
              SizedBox(width: 12),
              _ChartLegend(color: Colors.yellow, label: 'Fair'),
              SizedBox(width: 12),
              _ChartLegend(color: Colors.orange, label: 'Moderate'),
              SizedBox(width: 12),
              _ChartLegend(color: Colors.red, label: 'Poor'),
              SizedBox(width: 12),
              _ChartLegend(color: Colors.purple, label: 'Very Poor'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _ReportsSection extends StatelessWidget {
  final VoidCallback? onViewAll;
  const _ReportsSection({this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final ReportService reportService = ReportService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Live Reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            TextButton(onPressed: onViewAll, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<ReportItem>>(
          stream: reportService.getReportsStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No reports available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }
            return Column(
              children: snapshot.data!
                  .take(3)
                  .map((report) => _ReportCard(report: report))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportItem report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue.shade600,
                child: Text(
                  report.initials,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          report.user,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${report.confirm}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      report.location,
                      style: const TextStyle(
                        color: AppThemeColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                report.timeAgo,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorAverageCard extends StatelessWidget {
  final Stream<SensorAverageModel?> stream;

  const _SensorAverageCard({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorAverageModel?>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _SensorMessageCard(
            icon: Icons.error_outline,
            message: 'Unable to load indoor sensor data: ${snapshot.error}',
            color: Colors.red,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final sensorData = snapshot.data;
        if (sensorData == null) {
          return const _SensorMessageCard(
            icon: Icons.sensors_off_outlined,
            message: 'No five-reading sensor average is available yet.',
            color: Colors.grey,
          );
        }

        final isStale = DateTime.now().difference(sensorData.timestamp) >
            const Duration(minutes: 10);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppThemeColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.sensors,
                    color: AppThemeColors.primary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Indoor Sensor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _SensorStatusBadge(isStale: isStale),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${sensorData.sampleCount}-reading average',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 10.0;
                  final itemWidth = constraints.maxWidth >= 520
                      ? (constraints.maxWidth - (spacing * 2)) / 3
                      : (constraints.maxWidth - spacing) / 2;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      _SensorValueBox(
                        width: itemWidth,
                        label: 'Indoor AQI',
                        value: sensorData.averageAqi.toStringAsFixed(1),
                        unit: '1–5 scale',
                      ),
                      _SensorValueBox(
                        width: itemWidth,
                        label: 'eCO₂',
                        value: sensorData.averageEco2.toStringAsFixed(0),
                        unit: 'ppm',
                      ),
                      _SensorValueBox(
                        width: itemWidth,
                        label: 'TVOC',
                        value: sensorData.averageTvoc.toStringAsFixed(0),
                        unit: 'ppb',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    isStale ? Icons.warning_amber : Icons.schedule,
                    size: 14,
                    color: isStale ? Colors.orange : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isStale
                          ? 'Sensor data may be out of date. Last update: ${DateFormat('dd MMM yyyy, hh:mm a').format(sensorData.timestamp)}'
                          : 'Updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(sensorData.timestamp)}',
                      style: TextStyle(
                        color: isStale ? Colors.orange : Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SensorStatusBadge extends StatelessWidget {
  final bool isStale;

  const _SensorStatusBadge({required this.isStale});

  @override
  Widget build(BuildContext context) {
    final color = isStale ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            isStale ? 'Offline' : 'Live',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorValueBox extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final String unit;

  const _SensorValueBox({
    required this.width,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SensorMessageCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _SensorMessageCard({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemeColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}