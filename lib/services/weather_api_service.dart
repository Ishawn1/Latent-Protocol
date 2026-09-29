import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Immutable snapshot of microclimate conditions sourced from live meteorological feed.
class WeatherSnapshot {
  final String locationName;
  final String regionName;
  final double tempC;
  final double humidity;
  final bool isRaining;
  final String conditionText;
  final double solarRadiationWm2;
  final double pressureHpa;
  final DateTime timestamp;
  final bool isFromLiveFeed;

  const WeatherSnapshot({
    required this.locationName,
    required this.regionName,
    required this.tempC,
    required this.humidity,
    required this.isRaining,
    required this.conditionText,
    required this.solarRadiationWm2,
    required this.pressureHpa,
    required this.timestamp,
    this.isFromLiveFeed = true,
  });

  /// Realistic diurnal fallback model centered on Kharva.
  factory WeatherSnapshot.diurnalFallback({String location = 'Kharva'}) {
    final now = DateTime.now();
    final hour = now.hour + (now.minute / 60.0);

    // Diurnal temperature model: lowest ~05:30 (21°C), peak ~14:30 (32°C)
    final radians = (hour - 5.5) * (2 * pi / 24.0);
    final temp = 26.5 + 5.5 * sin(radians);

    // Inverse humidity relationship: lowest at max temp, highest at min temp
    final hum = (60.0 - 20.0 * sin(radians)).clamp(30.0, 95.0);

    // Solar radiation: 0 at night, peak ~800 W/m² at solar noon (12:30)
    double solar = 0.0;
    if (hour >= 6.0 && hour <= 18.5) {
      final sunRad = (hour - 6.0) * (pi / 12.5);
      solar = max(0.0, 850.0 * sin(sunRad));
    }

    return WeatherSnapshot(
      locationName: location,
      regionName: 'Gujarat',
      tempC: double.parse(temp.toStringAsFixed(1)),
      humidity: double.parse(hum.toStringAsFixed(1)),
      isRaining: false,
      conditionText: (solar > 100) ? 'Sunny • Clear Sky' : 'Clear Night',
      solarRadiationWm2: double.parse(solar.toStringAsFixed(0)),
      pressureHpa: 1012.0,
      timestamp: now,
      isFromLiveFeed: false,
    );
  }
}

/// Stealth meteorological service. Ingests real-world conditions to feed
/// the ESP32-S3 IoT Hub microclimate telemetry.
class WeatherApiService {
  static final WeatherApiService instance = WeatherApiService._internal();
  WeatherApiService._internal();

  /// WeatherAPI key configurable at compile-time or runtime
  static const String apiKey = String.fromEnvironment(
    'WEATHER_API_KEY',
    defaultValue: 'a2c635ec6d13480bb2c171315240110',
  );

  static const String defaultLocation = 'Kharva';

  WeatherSnapshot _latestSnapshot = WeatherSnapshot.diurnalFallback();
  WeatherSnapshot get latestSnapshot => _latestSnapshot;

  DateTime? _lastFetchTime;
  bool _isFetching = false;
  static const Duration _cacheDuration = Duration(minutes: 15);

  /// Fetches the latest weather using auto:ip for device location, falling back to Kharva.
  Future<WeatherSnapshot> fetchCurrentWeather({bool forceRefresh = false}) async {
    // Cache check
    if (!forceRefresh &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _latestSnapshot;
    }

    if (_isFetching) return _latestSnapshot;
    _isFetching = true;

    try {
      // 1. First try device auto-location via IP
      final snapshot = await _executeFetch('auto:ip') ??
          await _executeFetch(defaultLocation);

      if (snapshot != null) {
        _latestSnapshot = snapshot;
        _lastFetchTime = DateTime.now();
      } else {
        // Fallback to diurnal model with last known or default location
        _latestSnapshot = WeatherSnapshot.diurnalFallback(
          location: _latestSnapshot.locationName.isNotEmpty
              ? _latestSnapshot.locationName
              : defaultLocation,
        );
      }
    } catch (_) {
      // Never throw an exception to the UI; maintain graceful continuity
      _latestSnapshot = WeatherSnapshot.diurnalFallback(
        location: _latestSnapshot.locationName.isNotEmpty
            ? _latestSnapshot.locationName
            : defaultLocation,
      );
    } finally {
      _isFetching = false;
    }

    return _latestSnapshot;
  }

  Future<WeatherSnapshot?> _executeFetch(String queryTarget) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      final encodedQuery = Uri.encodeComponent(queryTarget);
      final uri = Uri.parse(
        'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$encodedQuery&aqi=no',
      );

      final request = await client.getUrl(uri).timeout(const Duration(seconds: 4));
      final response = await request.close().timeout(const Duration(seconds: 4));

      if (response.statusCode != HttpStatus.ok) {
        return null;
      }

      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(responseBody);
      if (data is! Map<String, dynamic>) return null;

      final location = data['location'] as Map<String, dynamic>?;
      final current = data['current'] as Map<String, dynamic>?;
      if (location == null || current == null) return null;

      final locName = location['name']?.toString().trim();
      final regName = location['region']?.toString().trim() ?? '';

      final temp = (current['temp_c'] as num?)?.toDouble() ?? 27.0;
      final hum = (current['humidity'] as num?)?.toDouble() ?? 60.0;
      final precipMm = (current['precip_mm'] as num?)?.toDouble() ?? 0.0;
      final pressureMb = (current['pressure_mb'] as num?)?.toDouble() ?? 1013.0;
      final uv = (current['uv'] as num?)?.toDouble() ?? 0.0;

      final conditionMap = current['condition'] as Map<String, dynamic>?;
      final condText = conditionMap?['text']?.toString().trim() ?? 'Clear';

      final isRain = precipMm > 0.1 ||
          condText.toLowerCase().contains('rain') ||
          condText.toLowerCase().contains('drizzle') ||
          condText.toLowerCase().contains('thunder');

      // Estimate solar irradiance W/m² from UV index (rough agricultural scaling: 1 UV ≈ 90–110 W/m²)
      final solar = uv > 0 ? (uv * 105.0).clamp(50.0, 950.0) : (temp > 28 ? 650.0 : 0.0);

      return WeatherSnapshot(
        locationName: (locName != null && locName.isNotEmpty) ? locName : defaultLocation,
        regionName: regName,
        tempC: double.parse(temp.clamp(-10.0, 55.0).toStringAsFixed(1)),
        humidity: double.parse(hum.clamp(0.0, 100.0).toStringAsFixed(1)),
        isRaining: isRain,
        conditionText: condText,
        solarRadiationWm2: double.parse(solar.toStringAsFixed(0)),
        pressureHpa: double.parse(pressureMb.clamp(900.0, 1100.0).toStringAsFixed(1)),
        timestamp: DateTime.now(),
        isFromLiveFeed: true,
      );
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }
}
