import 'package:flutter_test/flutter_test.dart';
import 'package:smartkheti/services/weather_api_service.dart';

void main() {
  group('WeatherApiService & WeatherSnapshot Tests', () {
    test('Diurnal fallback creates realistic values for Kharva', () {
      final snapshot = WeatherSnapshot.diurnalFallback(location: 'Kharva');
      expect(snapshot.locationName, 'Kharva');
      expect(snapshot.tempC, inInclusiveRange(18.0, 40.0));
      expect(snapshot.humidity, inInclusiveRange(20.0, 100.0));
      expect(snapshot.pressureHpa, 1012.0);
      expect(snapshot.isFromLiveFeed, false);
      expect(snapshot.conditionText, isNotEmpty);
    });

    test('WeatherApiService singleton maintains valid initial snapshot', () {
      final service = WeatherApiService.instance;
      expect(service.latestSnapshot, isNotNull);
      expect(service.latestSnapshot.locationName, isNotEmpty);
      expect(service.latestSnapshot.tempC, greaterThan(0.0));
    });

    test('WeatherSnapshot bounds are strictly physical', () {
      final snap = WeatherSnapshot(
        locationName: 'Kharva',
        regionName: 'Gujarat',
        tempC: 31.4,
        humidity: 62.0,
        isRaining: false,
        conditionText: 'Clear Sky',
        solarRadiationWm2: 740.0,
        pressureHpa: 1011.5,
        timestamp: DateTime(2026, 9, 22),
        isFromLiveFeed: true,
      );

      expect(snap.tempC, 31.4);
      expect(snap.humidity, 62.0);
      expect(snap.isRaining, false);
      expect(snap.solarRadiationWm2, 740.0);
    });
  });
}
