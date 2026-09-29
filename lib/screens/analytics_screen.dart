import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/models/air_quality_model.dart';
import '../core/models/sensor_average_model.dart';
import '../core/services/air_quality_service.dart';
import '../core/services/sensor_reading_service.dart';
import '../core/services/indoor_forecast_service.dart';

enum _AnalyticsMode { indoor, outdoor }

class AnalyticsScreen extends StatefulWidget {
  final LatLng location;
  final VoidCallback? onBackToHome;

  const AnalyticsScreen({
    super.key,
    required this.location,
    this.onBackToHome,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AirQualityService _aqiService = AirQualityService();
  final SensorReadingService _sensorService = SensorReadingService();
  final IndoorForecastService _forecastService =
  const IndoorForecastService();

  _AnalyticsMode _selectedMode = _AnalyticsMode.indoor;
  bool _isLoading = true;
  String? _error;
  AirQualityModel? _current;
  List<AirQualityModel> _forecast = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(AnalyticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final current = await _aqiService.fetchCurrentAirQuality(
        widget.location.latitude,
        widget.location.longitude,
      );
      final forecast = await _aqiService.fetchForecastAirQuality(
        widget.location.latitude,
        widget.location.longitude,
      );

      if (!mounted) return;
      setState(() {
        _current = current;
        _forecast = forecast..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FB),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            if (_selectedMode == _AnalyticsMode.outdoor) {
              await _fetchData();
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 18),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 14, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBackToHome,
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
                    ),
                    const Expanded(
                      child: Column(
                        children: [
                          Text('Analytics', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                          Text('Air Quality Trends & Predictions', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _AnalyticsModeSelector(
                  selectedMode: _selectedMode,
                  onChanged: (mode) {
                    setState(() => _selectedMode = mode);
                  },
                ),
              ),
              const SizedBox(height: 18),
              if (_selectedMode == _AnalyticsMode.indoor)
                _IndoorAnalyticsSection(
                  stream: _sensorService.watchAverageHistory(limit: 12),
                  forecastService: _forecastService,
                )
              else
                _buildOutdoorAnalytics(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutdoorAnalytics() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _AnalyticsMessageCard(
        icon: Icons.error_outline,
        title: 'Outdoor analytics unavailable',
        message: _error!,
        actionLabel: 'Retry',
        onAction: _fetchData,
      );
    }

    if (_current == null) {
      return const _AnalyticsMessageCard(
        icon: Icons.cloud_off_outlined,
        title: 'No outdoor analytics',
        message: 'No outdoor air-quality data is available.',
      );
    }

    final current = _current!;
    final now = DateTime.now();
    final upcoming = _forecast
        .where(
          (item) => item.timestamp.isAfter(
        now.subtract(const Duration(hours: 1)),
      ),
    )
        .toList();
    final next3h = upcoming
        .where(
          (item) => item.timestamp.isBefore(
        now.add(const Duration(hours: 3, minutes: 30)),
      ),
    )
        .toList();
    final predicted = next3h.isNotEmpty
        ? next3h.last
        : (upcoming.isNotEmpty ? upcoming.first : current);
    final hourly = (upcoming.isNotEmpty ? upcoming : [current])
        .take(7)
        .toList();
    final daily = _buildDailyForecast(current, upcoming);
    final insights = _buildInsights(current, predicted);
    final comparisons = _buildComparisons(current, upcoming);
    final confidence = _buildForecastConfidence(upcoming);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PredictionCard(current: current, predicted: predicted),
        const SizedBox(height: 18),
        const _SectionTitle(
          icon: Icons.schedule,
          title: '12-Hour Forecast',
        ),
        _HourlyForecastCard(items: hourly),
        const SizedBox(height: 18),
        const _SectionTitle(
          icon: Icons.calendar_today_outlined,
          title: '7-Day Forecast',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: daily
                .map((item) => _DayForecastCard(item: item))
                .toList(),
          ),
        ),
        const SizedBox(height: 18),
        const _SectionTitle(
          icon: Icons.tips_and_updates_outlined,
          title: 'Key Insights',
        ),
        const SizedBox(height: 8),
        ...insights.map((item) => _InsightCard(item: item)),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Forecast Comparison',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: comparisons
                .map(
                  (item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _HistoryCard(item: item),
                ),
              ),
            )
                .toList(),
          ),
        ),
        const SizedBox(height: 10),
        _ConfidenceCard(percent: confidence),
      ],
    );
  }

  List<_DailyForecastData> _buildDailyForecast(AirQualityModel current, List<AirQualityModel> forecast) {
    final byDay = <String, List<AirQualityModel>>{};
    final all = [current, ...forecast];
    for (final item in all) {
      final key = DateFormat('yyyy-MM-dd').format(item.timestamp);
      byDay.putIfAbsent(key, () => []).add(item);
    }
    final keys = byDay.keys.toList()..sort();
    return keys.take(7).map((key) {
      final dayItems = byDay[key]!;
      final low = dayItems.map((e) => e.aqiIndex).reduce((a, b) => a < b ? a : b);
      final high = dayItems.map((e) => e.aqiIndex).reduce((a, b) => a > b ? a : b);
      final avg = (dayItems.map((e) => e.aqiIndex).reduce((a, b) => a + b) / dayItems.length).round().clamp(1, 5).toInt();
      final avgIndex = (dayItems.map((e) => e.aqiIndex).reduce((a, b) => a + b) / dayItems.length).round().clamp(1, 5).toInt();
      final date = dayItems.first.timestamp;
      return _DailyForecastData(
        dayLabel: _labelForDate(date),
        quality: _categoryFromIndex(avgIndex),
        low: low,
        high: high,
        current: avg,
      );
    }).toList();
  }

  List<_InsightData> _buildInsights(AirQualityModel current, AirQualityModel predicted) {
    final delta = predicted.aqiIndex - current.aqiIndex;
    final trendTitle = delta > 0
        ? 'Air Quality May Worsen'
        : delta < 0
        ? 'Air Quality Improvement Ahead'
        : 'Air Quality Expected to Remain Stable';
    final trendText = delta > 0
        ? 'AQI may rise by $delta level${delta == 1 ? '' : 's'} in the next 3 hours.'
        : delta < 0
        ? 'AQI may improve by ${delta.abs()} level${delta.abs() == 1 ? '' : 's'} in the next 3 hours.'
        : 'AQI is expected to remain at level ${current.aqiIndex} during the next 3 hours.';

    final pmText = current.pm25 >= 35
        ? 'PM2.5 is elevated (${current.pm25.toStringAsFixed(1)} µg/m³). Consider reducing outdoor exposure.'
        : 'PM2.5 is currently moderate (${current.pm25.toStringAsFixed(1)} µg/m³).';

    final dominant = {
      'PM2.5': current.pm25,
      'PM10': current.pm10,
      'CO': current.co,
      'NO₂': current.no2,
      'SO₂': current.so2,
      'O₃': current.o3,
    }.entries.reduce((a, b) => a.value >= b.value ? a : b);

    return [
      _InsightData(
        icon: delta > 0
            ? Icons.trending_up_rounded
            : delta < 0
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded,
        iconColor: delta > 0
            ? const Color(0xFFFF7A00)
            : delta < 0
            ? const Color(0xFF10B981)
            : const Color(0xFF3B82F6),
        iconBg: delta > 0
            ? const Color(0xFFFFF4E9)
            : delta < 0
            ? const Color(0xFFE9FBF1)
            : const Color(0xFFEFF6FF),
        title: trendTitle,
        subtitle: trendText,
      ),
      _InsightData(
        icon: Icons.masks_rounded,
        iconColor: const Color(0xFF3B82F6),
        iconBg: const Color(0xFFEFF6FF),
        title: 'Particle Exposure Insight',
        subtitle: pmText,
      ),
      _InsightData(
        icon: Icons.air_rounded,
        iconColor: const Color(0xFF0EA5E9),
        iconBg: const Color(0xFFE6F9FF),
        title: 'Dominant Pollutant',
        subtitle: '${dominant.key} currently has the highest concentration (${dominant.value.toStringAsFixed(1)}).',
      ),
    ];
  }

  List<_ComparisonData> _buildComparisons(AirQualityModel current, List<AirQualityModel> forecast) {
    int avgWithin(Duration d) {
      final cutoff = DateTime.now().add(d);
      final items = forecast.where((e) => e.timestamp.isBefore(cutoff)).toList();
      if (items.isEmpty) return current.aqiIndex;
      return (items.map((e) => e.aqiIndex).reduce((a, b) => a + b) / items.length).round().clamp(1, 5).toInt();
    }

    final v24 = avgWithin(const Duration(hours: 24));
    final v48 = avgWithin(const Duration(hours: 48));
    final v72 = avgWithin(const Duration(hours: 72));

    String deltaText(int value) {
      final diff = value - current.aqiIndex;
      if (diff == 0) return '↔ 0';
      return diff > 0 ? '↗ $diff' : '↘ ${diff.abs()}';
    }

    return [
      _ComparisonData(title: 'Next 24h', value: v24, delta: deltaText(v24), isPositive: v24 <= current.aqiIndex),
      _ComparisonData(title: 'Next 48h', value: v48, delta: deltaText(v48), isPositive: v48 <= current.aqiIndex),
      _ComparisonData(title: 'Next 72h', value: v72, delta: deltaText(v72), isPositive: v72 <= current.aqiIndex),
    ];
  }

  int _buildForecastConfidence(List<AirQualityModel> forecast) {
    if (forecast.length < 2) return 80;
    final values = forecast.take(12).map((e) => e.aqiIndex.toDouble()).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    final volatility = variance.sqrtClamped();
    final confidence = (98 - (volatility * 1.2)).round().clamp(70, 98);
    return confidence;
  }

  String _categoryFromIndex(int idx) {
    switch (idx) {
      case 1:
        return 'Good';
      case 2:
        return 'Fair';
      case 3:
        return 'Moderate';
      case 4:
        return 'Poor';
      case 5:
        return 'Very Poor';
      default:
        return 'Unknown';
    }
  }

  String _labelForDate(DateTime date) {
    final now = DateTime.now();
    final d1 = DateTime(now.year, now.month, now.day);
    final d2 = DateTime(date.year, date.month, date.day);
    final diff = d2.difference(d1).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('EEE').format(date);
  }
}

extension on num {
  double sqrtClamped() {
    if (this <= 0) return 0;
    double x = toDouble();
    double r = x;
    for (int i = 0; i < 10; i++) {
      r = 0.5 * (r + x / r);
    }
    return r;
  }
}

class _AnalyticsModeSelector extends StatelessWidget {
  final _AnalyticsMode selectedMode;
  final ValueChanged<_AnalyticsMode> onChanged;

  const _AnalyticsModeSelector({
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_AnalyticsMode>(
      segments: const [
        ButtonSegment<_AnalyticsMode>(
          value: _AnalyticsMode.indoor,
          icon: Icon(Icons.home_outlined),
          label: Text('Indoor'),
        ),
        ButtonSegment<_AnalyticsMode>(
          value: _AnalyticsMode.outdoor,
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
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _IndoorAnalyticsSection extends StatelessWidget {
  final Stream<List<SensorAverageModel>> stream;
  final IndoorForecastService forecastService;

  const _IndoorAnalyticsSection({
    required this.stream,
    required this.forecastService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SensorAverageModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AnalyticsMessageCard(
            icon: Icons.error_outline,
            title: 'Indoor analytics unavailable',
            message: snapshot.error.toString(),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final readings = snapshot.data ?? const <SensorAverageModel>[];

        if (readings.length < 2) {
          return const _AnalyticsMessageCard(
            icon: Icons.hourglass_empty,
            title: 'Collecting indoor data',
            message:
            'At least two five-minute averages are required. Keep the Raspberry Pi running and check again shortly.',
          );
        }

        final latest = readings.last;
        final aqiValues = readings.map((item) => item.averageAqi).toList();
        final eco2Values = readings.map((item) => item.averageEco2).toList();
        final tvocValues = readings.map((item) => item.averageTvoc).toList();
        final timestamps = readings.map((item) => item.timestamp).toList();

        final averageAqi = _mean(aqiValues);
        final minimumAqi = _minimum(aqiValues);
        final maximumAqi = _maximum(aqiValues);
        final averageEco2 = _mean(eco2Values);
        final averageTvoc = _mean(tvocValues);
        final isStale = DateTime.now().difference(latest.timestamp) >
            const Duration(minutes: 15);

        IndoorForecast? forecast;
        String? forecastError;

        try {
          forecast = forecastService.generateForecast(
            values: aqiValues,
            timestamps: timestamps,
            forecastMinutes: 30,
            minimumValue: 1,
            maximumValue: 5,
          );
        } catch (error) {
          forecastError = error.toString();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (forecast != null)
              _IndoorForecastCard(
                currentAqi: latest.averageAqi,
                forecast: forecast,
                isStale: isStale,
                lastUpdated: latest.timestamp,
              )
            else
              _AnalyticsMessageCard(
                icon: Icons.show_chart,
                title: 'Forecast is not ready',
                message: forecastError ?? 'More readings are required.',
              ),
            const SizedBox(height: 18),
            const _SectionTitle(
              icon: Icons.analytics_outlined,
              title: 'Last 60 Minutes',
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: [
                  _IndoorMetricCard(
                    label: 'Average AQI',
                    value: averageAqi.toStringAsFixed(1),
                    unit: '1–5 scale',
                    color: const Color(0xFF8A2BE2),
                  ),
                  _IndoorMetricCard(
                    label: 'AQI Range',
                    value:
                    '${minimumAqi.toStringAsFixed(1)}–${maximumAqi.toStringAsFixed(1)}',
                    unit: '${readings.length} averages',
                    color: const Color(0xFF2D7EF7),
                  ),
                  _IndoorMetricCard(
                    label: 'Average eCO₂',
                    value: averageEco2.toStringAsFixed(0),
                    unit: 'ppm',
                    color: const Color(0xFF10B981),
                  ),
                  _IndoorMetricCard(
                    label: 'Average TVOC',
                    value: averageTvoc.toStringAsFixed(0),
                    unit: 'ppb',
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _IndoorLineChart(
              title: 'Indoor AQI',
              unit: '1–5 scale',
              values: aqiValues,
              timestamps: timestamps,
              color: const Color(0xFF8A2BE2),
              fixedMinimum: 1,
              fixedMaximum: 5,
            ),
            const SizedBox(height: 14),
            _IndoorLineChart(
              title: 'eCO₂',
              unit: 'ppm',
              values: eco2Values,
              timestamps: timestamps,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 14),
            _IndoorLineChart(
              title: 'TVOC',
              unit: 'ppb',
              values: tvocValues,
              timestamps: timestamps,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(
              icon: Icons.tips_and_updates_outlined,
              title: 'Indoor Insights',
            ),
            const SizedBox(height: 8),
            _IndoorInsightCard(
              icon: _trendIcon(forecast?.trend),
              color: _trendColor(forecast?.trend),
              title: 'AQI trend: ${forecast?.trend ?? 'Unavailable'}',
              message: forecast == null
                  ? 'More readings are required to calculate a trend.'
                  : _trendMessage(forecast),
            ),
            _IndoorInsightCard(
              icon: isStale ? Icons.sensors_off : Icons.sensors,
              color: isStale ? Colors.orange : const Color(0xFF10B981),
              title: isStale ? 'Sensor may be offline' : 'Sensor is active',
              message:
              'Last five-reading average: ${DateFormat('dd MMM, hh:mm a').format(latest.timestamp)}.',
            ),
          ],
        );
      },
    );
  }

  static double _mean(List<double> values) {
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double _minimum(List<double> values) {
    return values.reduce((a, b) => a < b ? a : b);
  }

  static double _maximum(List<double> values) {
    return values.reduce((a, b) => a > b ? a : b);
  }

  static IconData _trendIcon(String? trend) {
    if (trend == 'Worsening') return Icons.trending_up;
    if (trend == 'Improving') return Icons.trending_down;
    return Icons.trending_flat;
  }

  static Color _trendColor(String? trend) {
    if (trend == 'Worsening') return const Color(0xFFEF4444);
    if (trend == 'Improving') return const Color(0xFF10B981);
    return const Color(0xFF3B82F6);
  }

  static String _trendMessage(IndoorForecast forecast) {
    final direction = forecast.slope >= 0 ? 'increase' : 'decrease';
    return 'The regression slope indicates an estimated $direction of '
        '${forecast.slope.abs().toStringAsFixed(3)} AQI units per minute.';
  }
}

class _IndoorForecastCard extends StatelessWidget {
  final double currentAqi;
  final IndoorForecast forecast;
  final bool isStale;
  final DateTime lastUpdated;

  const _IndoorForecastCard({
    required this.currentAqi,
    required this.forecast,
    required this.isStale,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final difference = forecast.forecastValue - currentAqi;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D7EF7), Color(0xFF8A2BE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text(
            '30-Minute Indoor AQI Forecast',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IndoorForecastValue(
                label: 'Current',
                value: currentAqi,
              ),
              const SizedBox(width: 14),
              Icon(
                difference > 0.05
                    ? Icons.trending_up
                    : difference < -0.05
                    ? Icons.trending_down
                    : Icons.trending_flat,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 14),
              _IndoorForecastValue(
                label: 'Predicted',
                value: forecast.forecastValue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${forecast.trend} · ${DateFormat('hh:mm a').format(forecast.forecastTime)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isStale
                ? 'Warning: the latest sensor data may be out of date.'
                : 'Based on five-minute sensor averages. Updated ${DateFormat('hh:mm a').format(lastUpdated)}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _IndoorForecastValue extends StatelessWidget {
  final String label;
  final double value;

  const _IndoorForecastValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 5),
        Container(
          width: 68,
          height: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF5B400),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            value.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _IndoorMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _IndoorMetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: color),
          ),
          Text(unit, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _IndoorLineChart extends StatelessWidget {
  final String title;
  final String unit;
  final List<double> values;
  final List<DateTime> timestamps;
  final Color color;
  final double? fixedMinimum;
  final double? fixedMaximum;

  const _IndoorLineChart({
    required this.title,
    required this.unit,
    required this.values,
    required this.timestamps,
    required this.color,
    this.fixedMinimum,
    this.fixedMaximum,
  });

  @override
  Widget build(BuildContext context) {
    final rawMinimum = values.reduce((a, b) => a < b ? a : b);
    final rawMaximum = values.reduce((a, b) => a > b ? a : b);
    final padding = rawMaximum == rawMinimum
        ? 1.0
        : (rawMaximum - rawMinimum) * 0.15;
    final minimum = fixedMinimum ?? (rawMinimum - padding);
    final maximum = fixedMaximum ?? (rawMaximum + padding);
    final verticalInterval = (maximum - minimum) / 4;
    final horizontalInterval = values.length > 4
        ? (values.length / 4).ceilToDouble()
        : 1.0;
    final spots = List<FlSpot>.generate(
      values.length,
          (index) => FlSpot(index.toDouble(), values[index]),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(12, 14, 14, 10),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          Text(unit, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (values.length - 1).toDouble(),
                minY: minimum,
                maxY: maximum,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: verticalInterval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: const Color(0xFFE5E7EB),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: verticalInterval,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(title == 'Indoor AQI' ? 1 : 0),
                        style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: horizontalInterval,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index < 0 || index >= timestamps.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Text(
                            DateFormat('HH:mm').format(timestamps[index]),
                            style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
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
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(show: values.length <= 6),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndoorInsightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _IndoorInsightCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsMessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _AnalyticsMessageCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFF6B7280)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280))),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final AirQualityModel current;
  final AirQualityModel predicted;

  const _PredictionCard({required this.current, required this.predicted});

  @override
  Widget build(BuildContext context) {
    final delta = predicted.aqiIndex - current.aqiIndex;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D7EF7), Color(0xFF8A2BE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text('Next 3 Hours Prediction (AQI 1–5)', style: TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PredictionPill(label: 'Current', value: current.aqiIndex),
              const SizedBox(width: 10),
              Icon(
                delta > 0
                    ? Icons.trending_up_rounded
                    : delta < 0
                    ? Icons.trending_down_rounded
                    : Icons.trending_flat_rounded,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 10),
              _PredictionPill(label: 'Predicted', value: predicted.aqiIndex),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            delta > 0
                ? '↑ $delta level${delta == 1 ? '' : 's'} worsening'
                : delta < 0
                ? '↓ ${delta.abs()} level${delta.abs() == 1 ? '' : 's'} improving'
                : '↔ AQI expected to remain stable',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HourlyForecastCard extends StatelessWidget {
  final List<AirQualityModel> items;

  const _HourlyForecastCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: _cardDecoration(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final label = index == 0 ? 'Now' : DateFormat('ha').format(item.timestamp).toLowerCase();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  const SizedBox(height: 8),
                  Container(
                    width: 42,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5B400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.aqiIndex}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF374151)),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PredictionPill extends StatelessWidget {
  final String label;
  final int value;

  const _PredictionPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFFF5B400),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 4))],
          ),
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 28),
          ),
        ),
      ],
    );
  }
}

class _DailyForecastData {
  final String dayLabel;
  final String quality;
  final int low;
  final int high;
  final int current;

  const _DailyForecastData({
    required this.dayLabel,
    required this.quality,
    required this.low,
    required this.high,
    required this.current,
  });
}

class _DayForecastCard extends StatelessWidget {
  final _DailyForecastData item;

  const _DayForecastCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isGood = item.quality.toLowerCase() == 'good' || item.quality.toLowerCase() == 'fair';
    final barColor = isGood ? const Color(0xFF10B981) : const Color(0xFFF5B400);
    final normalized = item.high == item.low ? 0.6 : ((item.current - item.low) / (item.high - item.low)).clamp(0.12, 0.95);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.dayLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: Text(item.quality, style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: normalized,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Low: ${item.low}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    const Spacer(),
                    Text('High: ${item.high}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 52,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            alignment: Alignment.center,
            child: Text('${item.current}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _InsightData {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;

  const _InsightData({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });
}

class _InsightCard extends StatelessWidget {
  final _InsightData item;

  const _InsightCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: item.iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(item.icon, size: 18, color: item.iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(item.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonData {
  final String title;
  final int value;
  final String delta;
  final bool isPositive;

  const _ComparisonData({
    required this.title,
    required this.value,
    required this.delta,
    required this.isPositive,
  });
}

class _HistoryCard extends StatelessWidget {
  final _ComparisonData item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text('${item.value}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFFF5B400))),
          const SizedBox(height: 2),
          Text(
            item.delta,
            style: TextStyle(
              fontSize: 12,
              color: item.isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceCard extends StatelessWidget {
  final int percent;

  const _ConfidenceCard({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9FBF6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCDF3E7)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF10B981),
                child: Icon(Icons.show_chart_rounded, size: 16, color: Colors.white),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Forecast Confidence', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('Model confidence based on forecast consistency', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFBFEBDD),
              color: const Color(0xFF10B981),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('$percent%', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0D111827),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );
}