import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartkheti/models/esp32_telemetry.dart';
import 'package:smartkheti/services/esp32_backend_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Esp32Telemetry Model & Parser Tests', () {
    test('Correctly parses valid ESP32-S3 payload', () {
      final json = {
        'device': 'ESP32-S3-N16R8',
        'dht_temp': 28.5,
        'dht_hum': 65.0,
        'sn3000_moist': 42.0,
        'sn3000_temp': 24.0,
        'water_wet': 1,
        'soil_ec': 450,
      };

      final telemetry = Esp32Telemetry.fromJson(json, isHardwareLive: true);
      expect(telemetry, isNotNull);
      expect(telemetry!.dhtTempC, 28.5);
      expect(telemetry.dhtHumidityPercent, 65.0);
      expect(telemetry.sn3000MoisturePercent, 42.0);
      expect(telemetry.sn3000SoilTempC, 24.0);
      expect(telemetry.waterDetected, true);
      expect(telemetry.soilEcUsCm, 450);
      expect(telemetry.isHardwareLive, true);
      expect(telemetry.vpdKpa, greaterThan(0.0));
    });

    test('Rejects payload with invalid or missing device id', () {
      final corruptedJson = {
        'device': 'UNKNOWN-CONTROLLER',
        'raw_adc': 50,
      };

      final telemetry = Esp32Telemetry.fromJson(corruptedJson);
      expect(telemetry, isNull);
    });

    test('Rejects NaN and Infinity values without crashing', () {
      final invalidJson = {
        'dht_temp': 'NaN',
        'dht_hum': 'Infinity',
        'sn3000_moist': 50.0,
      };

      final telemetry = Esp32Telemetry.fromJson(invalidJson);
      expect(telemetry, isNull);
    });

    test('Computes Vapor Pressure Deficit (VPD) accurately', () {
      // At 25°C and 50% RH:
      // es ≈ 3.167 kPa, ea ≈ 1.584 kPa, VPD ≈ 1.58 kPa
      final vpd = Esp32Telemetry.calculateVpd(25.0, 50.0);
      expect(vpd, closeTo(1.58, 0.15));
    });

    test('Evaluates soil moisture stress levels correctly', () {
      expect(Esp32Telemetry.evaluateWaterStress(15.0), 'Severe Wilting Risk');
      expect(Esp32Telemetry.evaluateWaterStress(35.0), 'Moderate Depletion');
      expect(Esp32Telemetry.evaluateWaterStress(55.0), 'Optimal Field Capacity');
      expect(Esp32Telemetry.evaluateWaterStress(95.0), 'Over-irrigated / Saturation');
    });
  });

  group('Esp32BackendService Dual-Mode & Failsafe Tests', () {
    test('Default backend initializes with telemetry and history buffer', () {
      final backend = Esp32BackendService.instance;
      expect(backend.currentTelemetry, isNotNull);
      expect(backend.history, isNotEmpty);
    });

    test('Ingests raw JSON from real hardware correctly and updates telemetry', () {
      final backend = Esp32BackendService.instance;
      final rawJson = jsonEncode({
        'device': 'ESP32-S3-N16R8-LIVE',
        'dht_temp': 29.1,
        'dht_hum': 55.0,
        'sn3000_moist': 38.0,
        'water_wet': 0,
      });

      final success = backend.ingestRawJson(rawJson);
      expect(success, true);
      expect(backend.currentTelemetry.deviceId, 'ESP32-S3-N16R8-LIVE');
      expect(backend.currentTelemetry.dhtTempC, 29.1);
      expect(backend.currentTelemetry.isHardwareLive, true);
      expect(backend.isHardwareConnected, true);
    });

    test('Failsafe valve timer activates and shuts off cleanly', () {
      final backend = Esp32BackendService.instance;
      expect(backend.isValveOpen, false);

      backend.openValve(durationMinutes: 30);
      expect(backend.isValveOpen, true);
      expect(backend.remainingValveSeconds, greaterThan(1700));

      backend.closeValve();
      expect(backend.isValveOpen, false);
      expect(backend.remainingValveSeconds, 0);
    });
  });
}
