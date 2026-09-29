class IndoorForecast {
  final double forecastValue;

  // Change in the sensor value per minute.
  final double slope;

  final DateTime forecastTime;

  const IndoorForecast({
    required this.forecastValue,
    required this.slope,
    required this.forecastTime,
  });

  String get trend {
    if (slope > 0.01) {
      return 'Worsening';
    }

    if (slope < -0.01) {
      return 'Improving';
    }

    return 'Stable';
  }
}

class IndoorForecastService {
  const IndoorForecastService();

  IndoorForecast generateForecast({
    required List<double> values,
    required List<DateTime> timestamps,
    required int forecastMinutes,
    double? minimumValue,
    double? maximumValue,
  }) {
    if (values.length != timestamps.length) {
      throw ArgumentError(
        'Values and timestamps must have the same length.',
      );
    }

    if (values.length < 2) {
      throw ArgumentError(
        'At least two readings are required for forecasting.',
      );
    }

    if (forecastMinutes <= 0) {
      throw ArgumentError(
        'Forecast minutes must be greater than zero.',
      );
    }

    final origin = timestamps.first;

    // Convert timestamps to minutes from the first reading.
    final x = timestamps
        .map(
          (time) =>
      time.difference(origin).inSeconds / 60.0,
    )
        .toList();

    final y = values;
    final count = values.length.toDouble();

    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);

    final sumXY = List<double>.generate(
      values.length,
          (index) => x[index] * y[index],
    ).reduce((a, b) => a + b);

    final sumXSquared = x
        .map((value) => value * value)
        .reduce((a, b) => a + b);

    final denominator =
        (count * sumXSquared) - (sumX * sumX);

    if (denominator.abs() < 0.000001) {
      throw StateError(
        'The readings do not contain enough time variation.',
      );
    }

    final slope =
        ((count * sumXY) - (sumX * sumY)) /
            denominator;

    final intercept =
        (sumY - (slope * sumX)) / count;

    final forecastTime = timestamps.last.add(
      Duration(minutes: forecastMinutes),
    );

    final futureX =
        forecastTime.difference(origin).inSeconds /
            60.0;

    double forecastValue =
        (slope * futureX) + intercept;

    if (minimumValue != null &&
        forecastValue < minimumValue) {
      forecastValue = minimumValue;
    }

    if (maximumValue != null &&
        forecastValue > maximumValue) {
      forecastValue = maximumValue;
    }

    return IndoorForecast(
      forecastValue: forecastValue,
      slope: slope,
      forecastTime: forecastTime,
    );
  }
}