import 'dart:math';

/// Operational status of a sensor or telemetry node.
enum NodeHealthStatus { normal, warning, critical, fault }

/// Represents telemetry data from an ESP32-S3 N16R8 node.
///
/// All sensor readings are nullable — a null value means the sensor
/// did not report a valid reading in this packet (DHT error, Modbus
/// timeout, etc.).  The UI must always null-check before displaying.
///
/// ## Key rules
/// - `isHardwareLive = false` → no real packet received yet; show '–' everywhere
/// - `dhtTempC == null` → DHT22 read error for this packet
/// - `soilEcAvailable == false` → SN-3000 failed or EC not reported
class Esp32Telemetry {
  // ── Active Physical Hardware Sensors ──────────────────────────────────────

  /// Air Temperature from DHT22 in °C. Null when DHT22 read fails.
  final double? dhtTempC;

  /// Relative Air Humidity from DHT22 in %. Null when DHT22 read fails.
  final double? dhtHumidityPercent;

  /// Soil Moisture from SN-3000 in %. Null when sensor offline.
  final double? sn3000MoisturePercent;

  /// Soil Temperature from SN-3000 in °C. Null when sensor offline.
  final double? sn3000SoilTempC;

  /// Soil EC from SN-3000 in µS/cm (0–9999). Null when sensor offline.
  final int? soilEcUsCm;

  /// True if [soilEcUsCm] came from a valid sensor reading.
  bool get soilEcAvailable => soilEcUsCm != null;

  /// Rain / Leaf surface wetness from digital Water Sensor.
  final bool waterDetected;

  // ── Calculated Edge Metrics ───────────────────────────────────────────────

  /// Vapor Pressure Deficit in kPa (calculated from DHT22 readings).
  /// Null when either DHT22 reading is unavailable.
  final double? vpdKpa;

  /// Disease Severity Value (0.0–4.0) based on leaf wetness + humidity.
  /// Computed on the Flutter side from available readings.
  final double? dsv;

  /// Water stress classification derived from SN-3000 moisture.
  /// Null when soil moisture is unavailable.
  final String? waterStressStatus;

  // ── On-Chip Edge-AI Inference (ESP32-S3 Neural Diagnostics) ──────────────
  /// True if ESP32 neural forward pass executed successfully.
  final bool aiModelReady;

  /// Water stress probability in % (0.0 to 100.0) from on-chip neural model.
  final double? aiWaterStressProb;

  /// Crop inspection/disease risk in % (0.0 to 100.0) from on-chip neural model.
  final double? aiCropInspectionProb;

  /// True if ESP32 Edge-AI predicts urgent water stress (>= 50%).
  final bool aiWaterStressAlert;

  /// True if ESP32 Edge-AI predicts urgent crop disease/anomaly inspection (>= 50%).
  final bool aiInspectionAlert;

  // ── Metadata ─────────────────────────────────────────────────────────────
  final String deviceId;
  final String firmwareVersion;
  final DateTime timestamp;

  /// True only when this object was built from a real hardware packet.
  final bool isHardwareLive;

  final NodeHealthStatus healthStatus;

  const Esp32Telemetry({
    required this.dhtTempC,
    required this.dhtHumidityPercent,
    required this.sn3000MoisturePercent,
    required this.sn3000SoilTempC,
    required this.soilEcUsCm,
    required this.waterDetected,
    required this.vpdKpa,
    required this.dsv,
    required this.waterStressStatus,
    this.aiModelReady = false,
    this.aiWaterStressProb,
    this.aiCropInspectionProb,
    this.aiWaterStressAlert = false,
    this.aiInspectionAlert = false,
    required this.deviceId,
    required this.firmwareVersion,
    required this.timestamp,
    required this.isHardwareLive,
    required this.healthStatus,
  });

  // ── Computed helpers ──────────────────────────────────────────────────────

  /// True if SN-3000 moisture is within realistic bounds.
  bool get isMoistureValid {
    final m = sn3000MoisturePercent;
    return m != null && m > 0.0 && m <= 100.0;
  }

  /// True if DHT22 temperature is within agronomic operating bounds.
  bool get isTempValid {
    final t = dhtTempC;
    return t != null && t >= -10.0 && t <= 60.0;
  }

  // ── Static calculators ────────────────────────────────────────────────────

  /// Calculates Vapor Pressure Deficit (VPD) in kPa using Tetens equation.
  /// Returns null if either argument is null / non-finite.
  static double? calculateVpd(double? tempC, double? humidityPercent) {
    if (tempC == null || humidityPercent == null) return null;
    if (tempC.isNaN || !tempC.isFinite) return null;
    if (humidityPercent.isNaN || !humidityPercent.isFinite) return null;
    final t = tempC.clamp(-20.0, 60.0);
    final h = humidityPercent.clamp(0.0, 100.0);
    final es = 0.61078 * exp((17.27 * t) / (t + 237.3));
    final ea = es * (h / 100.0);
    return double.parse((es - ea).clamp(0.0, 10.0).toStringAsFixed(2));
  }

  /// DSV (Disease Severity Value) computed from leaf wetness + humidity.
  /// Returns null when humidity is unavailable.
  static double? calculateDsv(bool waterDetected, double? humidityPercent) {
    if (humidityPercent == null) return null;
    if (waterDetected) return humidityPercent > 85 ? 3.8 : 2.5;
    if (humidityPercent > 80) return 1.2;
    return 0.2;
  }

  /// Water stress classification from SN-3000 moisture. Null if unavailable.
  static String? evaluateWaterStress(double? moisturePercent) {
    if (moisturePercent == null) return null;
    if (moisturePercent < 25.0) return 'Severe Wilting Risk';
    if (moisturePercent < 40.0) return 'Moderate Depletion';
    if (moisturePercent <= 75.0) return 'Optimal Field Capacity';
    if (moisturePercent <= 85.0) return 'High Moisture';
    return 'Over-irrigated / Saturation';
  }

  /// Evaluates health status from available environmental readings.
  static NodeHealthStatus evaluateHealthStatus({
    required double? dsv,
    required double? moisture,
    required double? temp,
  }) {
    final d = dsv ?? 0.0;
    final m = moisture ?? 50.0; // assume mid-range when unknown
    final t = temp ?? 25.0;     // assume safe temp when unknown
    if (d >= 3.5 || m < 20.0 || m > 90.0 || t > 40.0) {
      return NodeHealthStatus.critical;
    }
    if (d >= 2.0 || m < 35.0 || m > 80.0 || t > 36.0) {
      return NodeHealthStatus.warning;
    }
    return NodeHealthStatus.normal;
  }

  // ── Safe JSON parsers ─────────────────────────────────────────────────────

  static double? _safeDouble(dynamic value, {double? min, double? max}) {
    if (value == null) return null;
    double? parsed;
    if (value is num) {
      parsed = value.toDouble();
    } else if (value is String) {
      parsed = double.tryParse(value);
    }
    if (parsed == null || parsed.isNaN || !parsed.isFinite) return null;
    if (min != null && parsed < min - 0.5) return null;
    if (max != null && parsed > max + 0.5) return null;
    return parsed;
  }

  static int? _safeInt(dynamic value, {int? min, int? max}) {
    if (value == null) return null;
    int? parsed;
    if (value is num) {
      parsed = value.toInt();
    } else if (value is String) {
      parsed = int.tryParse(value);
    }
    if (parsed == null) return null;
    if (min != null && parsed < min) return null;
    if (max != null && parsed > max) return null;
    return parsed;
  }

  // ── fromJson ──────────────────────────────────────────────────────────────

  /// Parses a JSON packet from the ESP32 firmware (v1.0-wifi).
  ///
  /// Expected JSON keys (teammate's firmware):
  /// ```json
  /// {
  ///   "device":          "ESP32-S3-N16R8",
  ///   "version":         "v1.0-wifi",
  ///   "airTemp":         23.1,          // absent if DHT22 failed
  ///   "humidity":        63.6,          // absent if DHT22 failed
  ///   "rainDetected":    false,         // bool (also accepts int 0/1)
  ///   "soilMoisture":    22.1,          // only when soilOK
  ///   "soilTemperature": 23.6,          // only when soilOK
  ///   "soilEC":          152,           // only when soilOK
  ///   "soilSensorOK":    false          // only sent when soil failed
  /// }
  /// ```
  ///
  /// ## Partial packet handling
  /// A packet is accepted even when some sensors fail. Only truly
  /// unparseable JSON or a missing `device` field causes rejection.
  /// Each sensor's field is set to null if the reading was missing.
  ///
  /// ## Soil sensor state logic
  /// | `soilSensorOK` present | Soil keys present | Interpretation |
  /// |---|---|---|
  /// | `false`                | No                | Sensor failed — keep last good values |
  /// | Absent                 | Yes               | Sensor OK — use new values |
  /// | Absent                 | No                | Unknown — keep last good values |
  static Esp32Telemetry? fromJson(
    Map<String, dynamic> json, {
    bool isHardwareLive = true,
    Esp32Telemetry? previous, // last known good reading for carry-forward
  }) {
    try {
      // Require device identity to be correct
      final deviceId = json['device'];
      if (deviceId is! String || !deviceId.startsWith('ESP32-S3-N16R8')) {
        return null;
      }

      // ── DHT22 ──────────────────────────────────────────────────────────
      final temp = _safeDouble(json['airTemp'] ?? json['dht_temp'], min: -40.0, max: 80.0);
      final hum  = _safeDouble(json['humidity'] ?? json['dht_hum'], min: 0.0, max: 100.0);

      // ── Rain sensor ────────────────────────────────────────────────────
      // Firmware sends bool; handle int 0/1 and string for robustness
      bool waterDetected = false;
      final rainVal = json['rainDetected'] ?? json['water_wet'];
      if (rainVal is bool) {
        waterDetected = rainVal;
      } else if (rainVal is num) {
        waterDetected = rainVal >= 0.5;
      } else if (rainVal is String) {
        waterDetected = rainVal.toLowerCase() == 'true' || rainVal == '1';
      }

      // ── Soil sensor ────────────────────────────────────────────────────
      // Three-state: OK (keys present), FAILED (soilSensorOK: false),
      // or UNKNOWN (neither present → carry forward previous values).
      final soilSensorOkFlag = json['soilSensorOK']; // only set when false
      final soilMoistRaw  = json['soilMoisture'] ?? json['sn3000_moist'];
      final soilTempRaw   = json['soilTemperature'] ?? json['sn3000_temp'];
      final soilEcRaw     = json['soilEC'] ?? json['soil_ec'];

      double? soilMoisture;
      double? soilTemperature;
      int?    soilEc;

      final bool soilKeysSent = soilMoistRaw != null ||
          soilTempRaw != null || soilEcRaw != null;
      final bool soilExplicitFail =
          soilSensorOkFlag is bool && soilSensorOkFlag == false;

      if (soilKeysSent && !soilExplicitFail) {
        // Sensor reported OK — parse new values
        soilMoisture    = _safeDouble(soilMoistRaw, min: 0.0, max: 100.0);
        soilTemperature = _safeDouble(soilTempRaw, min: -20.0, max: 60.0);
        soilEc          = _safeInt(soilEcRaw, min: 0, max: 9999);
      } else {
        // Sensor failed or unknown — carry forward last good values
        soilMoisture    = previous?.sn3000MoisturePercent;
        soilTemperature = previous?.sn3000SoilTempC;
        soilEc          = previous?.soilEcUsCm;
      }

      // ── On-Chip Edge-AI Inference ─────────────────────────────────────
      final aiMap = json['aiAlerts'];
      bool aiModelReady = false;
      double? aiWaterStressProb;
      double? aiCropInspectionProb;
      bool aiWaterStressAlert = false;
      bool aiInspectionAlert = false;

      if (aiMap is Map<String, dynamic>) {
        aiModelReady = aiMap['modelReady'] == true;
        final wsp = _safeDouble(aiMap['waterStressProbability'], min: 0.0, max: 100.0);
        aiWaterStressProb = wsp?.clamp(0.0, 100.0);
        final cip = _safeDouble(aiMap['cropInspectionRisk'], min: 0.0, max: 100.0);
        aiCropInspectionProb = cip?.clamp(0.0, 100.0);
        aiWaterStressAlert = aiMap['waterStressAlert'] == true;
        aiInspectionAlert = aiMap['inspectionAlert'] == true;
      }

      // ── Computed metrics ───────────────────────────────────────────────
      final vpd         = calculateVpd(temp, hum);
      final dsv         = calculateDsv(waterDetected, hum);
      final waterStress = evaluateWaterStress(soilMoisture);
      final health      = evaluateHealthStatus(
        dsv:      dsv,
        moisture: soilMoisture,
        temp:     temp,
      );

      final version = (json['version'] as String?) ?? 'v1.0-wifi';

      return Esp32Telemetry(
        dhtTempC:              temp,
        dhtHumidityPercent:    hum,
        sn3000MoisturePercent: soilMoisture,
        sn3000SoilTempC:       soilTemperature,
        soilEcUsCm:            soilEc,
        waterDetected:         waterDetected,
        vpdKpa:                vpd,
        dsv:                   dsv,
        waterStressStatus:     waterStress,
        aiModelReady:          aiModelReady,
        aiWaterStressProb:     aiWaterStressProb,
        aiCropInspectionProb:  aiCropInspectionProb,
        aiWaterStressAlert:    aiWaterStressAlert,
        aiInspectionAlert:     aiInspectionAlert,
        deviceId:              deviceId,
        firmwareVersion:       version,
        timestamp:             DateTime.now(),
        isHardwareLive:        isHardwareLive,
        healthStatus:          health,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Empty placeholder (no data yet) ──────────────────────────────────────

  /// Initial state before any hardware packet is received.
  /// All sensor readings are null — UI must show '–' for every value.
  static Esp32Telemetry get empty => Esp32Telemetry(
    dhtTempC:              null,
    dhtHumidityPercent:    null,
    sn3000MoisturePercent: null,
    sn3000SoilTempC:       null,
    soilEcUsCm:            null,
    waterDetected:         false,
    vpdKpa:                null,
    dsv:                   null,
    waterStressStatus:     null,
    aiModelReady:          false,
    aiWaterStressProb:     null,
    aiCropInspectionProb:  null,
    aiWaterStressAlert:    false,
    aiInspectionAlert:     false,
    deviceId:              'ESP32-S3-N16R8',
    firmwareVersion:       'v1.0-wifi',
    timestamp:             DateTime.now(),
    isHardwareLive:        false,
    healthStatus:          NodeHealthStatus.normal,
  );
}

/// Null-safe convenience accessors for [Esp32Telemetry].
///
/// Screens should use these instead of direct null-checks to avoid
/// scattering `?? 0.0` across every comparison site.
///
/// - `safeTemp` → dhtTempC ?? 0.0 (0 °C treated as "no reading" in UI)
/// - `safeMoisture` → sn3000MoisturePercent ?? 50.0 (neutral fallback)
/// - `safeHum` → dhtHumidityPercent ?? 0.0
extension Esp32TelemetrySafe on Esp32Telemetry {
  /// DHT22 air temperature, safe for comparisons. Returns 0.0 when null.
  double get safeTemp => dhtTempC ?? 0.0;

  /// SN-3000 soil moisture, safe for comparisons. Returns 50.0 (mid-range) when null.
  double get safeMoisture => sn3000MoisturePercent ?? 50.0;

  /// DHT22 relative humidity, safe for comparisons. Returns 0.0 when null.
  double get safeHum => dhtHumidityPercent ?? 0.0;

  /// SN-3000 soil temperature, safe for display. Returns 0.0 when null.
  double get safeSoilTemp => sn3000SoilTempC ?? 0.0;

  /// DSV disease index, safe for comparisons. Returns 0.0 when null.
  double get safeDsv => dsv ?? 0.0;

  /// VPD in kPa, safe for display. Returns 0.0 when null.
  double get safeVpd => vpdKpa ?? 0.0;
}
