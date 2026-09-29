import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/esp32_telemetry.dart';
import 'alert_notification_service.dart';

/// Real-hardware-only backend for the ESP32-S3 N16R8 platform.
///
/// No simulation. No fake data. Displays '–' until the first real
/// packet arrives from the physical field unit.
///
/// ## Data flow
/// 1. [EspApPollingService] polls the ESP32 AP and calls [ingestRawJson].
/// 2. [ingestRawJson] parses + validates the packet, then calls [notifyListeners].
/// 3. UI rebuilds from [currentTelemetry].
///
/// ## Hardware watchdog
/// If no packet arrives within [_hardwareTimeoutSeconds], [isRealHardwareStreaming]
/// flips to false. Telemetry data is preserved (not cleared) so the UI can
/// show the last known reading with a "stale" indicator.
///
/// ## Security
/// - Token auth and rate limiting live in [EspApPollingService].
/// - 1 024-byte body limit in [ingestRawJson] (DoS guard).
class Esp32BackendService extends ChangeNotifier {
  static final Esp32BackendService instance = Esp32BackendService._internal();

  Esp32BackendService._internal() {
    _telemetry = Esp32Telemetry.empty;
    _historyBuffer.addLast(_telemetry);
  }

  // ── State ─────────────────────────────────────────────────────────────────
  late Esp32Telemetry _telemetry;
  final ListQueue<Esp32Telemetry> _historyBuffer = ListQueue<Esp32Telemetry>(100);
  static const int _maxBufferCapacity = 100;

  // Hardware streaming state
  bool _isRealHardwareStreaming = false;
  static const int _hardwareTimeoutSeconds = 15;

  Timer?    _hardwareWatchdogTimer;
  HttpServer? _httpServer;

  // Server (kept as optional fallback POST path)
  final int _serverPort = 8080;
  String _serverIp      = '0.0.0.0';
  bool _isServerRunning = false;
  int  _receivedPacketCount = 0;

  DateTime? _lastHardwarePacketTime;

  // Valve actuation state (Epoch-based failsafe)
  DateTime? _valveExpiryTime;

  // ── Accessors ─────────────────────────────────────────────────────────────
  Esp32Telemetry get currentTelemetry => _telemetry;
  List<Esp32Telemetry> get history    => List.unmodifiable(_historyBuffer);

  /// True only when a real packet has been received within the last 15 s.
  bool get isRealHardwareStreaming => _isRealHardwareStreaming;

  /// True if at least one packet has ever been received this session.
  bool get isHardwareConnected => _lastHardwarePacketTime != null;

  bool get isServerRunning    => _isServerRunning;
  int  get serverPort         => _serverPort;
  String get serverIp         => _serverIp;
  int  get receivedPacketCount => _receivedPacketCount;

  DateTime get lastHardwarePacketTime =>
      _lastHardwarePacketTime ?? DateTime.now();

  /// True if valve is currently open and has not expired.
  bool get isValveOpen {
    if (_valveExpiryTime == null) return false;
    if (DateTime.now().isBefore(_valveExpiryTime!)) return true;
    _valveExpiryTime = null;
    return false;
  }

  /// Remaining seconds until valve auto-shuts off.
  int get remainingValveSeconds {
    if (!isValveOpen || _valveExpiryTime == null) return 0;
    return max(0, _valveExpiryTime!.difference(DateTime.now()).inSeconds);
  }

  // ── Valve Control ─────────────────────────────────────────────────────────

  void openValve({int durationMinutes = 30}) {
    _valveExpiryTime =
        DateTime.now().add(Duration(minutes: durationMinutes.clamp(1, 120)));
    notifyListeners();
  }

  void closeValve() {
    _valveExpiryTime = null;
    notifyListeners();
  }

  // ── Real Hardware Packet Ingestion ────────────────────────────────────────

  /// Ingests a raw JSON string from any transport (AP polling, BLE, or POST).
  ///
  /// Carries forward previous soil readings on partial sensor failures.
  /// Returns true if the packet was valid and accepted.
  bool ingestRawJson(String rawJson) {
    if (rawJson.length > 1024) return false; // DoS guard

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return false;

      final parsed = Esp32Telemetry.fromJson(
        decoded,
        isHardwareLive: true,
        previous: _telemetry, // carry-forward for soil sensor failures
      );
      if (parsed == null) return false;

      _telemetry = parsed;
      _lastHardwarePacketTime = DateTime.now();
      _isRealHardwareStreaming = true;
      _receivedPacketCount++;
      _addToBuffer(_telemetry);

      // Evaluate on-chip Edge-AI notifications (Irrigation Needed / Inspection Required)
      AlertNotificationService.instance.evaluateTelemetry(_telemetry);

      // Reset watchdog — it will flip _isRealHardwareStreaming=false
      // if no packet arrives within 15 s, but it never clears _telemetry.
      _resetHardwareWatchdog();

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Hardware Watchdog ─────────────────────────────────────────────────────

  void _resetHardwareWatchdog() {
    _hardwareWatchdogTimer?.cancel();
    _hardwareWatchdogTimer = Timer(
      const Duration(seconds: _hardwareTimeoutSeconds),
      _onWatchdogExpired,
    );
  }

  void _onWatchdogExpired() {
    final since = _lastHardwarePacketTime == null
        ? const Duration(seconds: 999)
        : DateTime.now().difference(_lastHardwarePacketTime!);

    if (since.inSeconds >= _hardwareTimeoutSeconds) {
      _isRealHardwareStreaming = false;
      // Telemetry data is preserved — UI shows last reading with stale indicator
      debugPrint(
        'ESP32 watchdog: no packet for ${since.inSeconds}s — streaming stopped.',
      );
      notifyListeners();
    }
  }

  // ── Fallback HTTP Server (port 8080) ──────────────────────────────────────
  // Kept as an optional POST path. Uses same token as AP polling service.

  static const String _sharedToken = 'smartkheti-field-2025';
  static const int _maxPacketsPerMinute = 30;
  final List<DateTime> _ingestTimestamps = [];

  Future<void> startHttpServer() async {
    if (_isServerRunning) return;
    try {
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, _serverPort);
      _isServerRunning = true;

      try {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLinkLocal: false,
        );
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback) { _serverIp = addr.address; break; }
          }
          if (_serverIp != '0.0.0.0') break;
        }
      } catch (_) {
        _serverIp = '127.0.0.1';
      }

      _httpServer!.listen(_handleHttpRequest, onError: (e) {
        debugPrint('ESP32 fallback HTTP server error: $e');
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Could not bind fallback HTTP server on port $_serverPort: $e');
    }
  }

  bool _checkRateLimit() {
    final now = DateTime.now();
    final window = now.subtract(const Duration(minutes: 1));
    _ingestTimestamps.removeWhere((t) => t.isBefore(window));
    if (_ingestTimestamps.length >= _maxPacketsPerMinute) return false;
    _ingestTimestamps.add(now);
    return true;
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, X-Smartkheti-Token');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path;

    if (request.method == 'POST' &&
        (path == '/api/telemetry' || path == '/telemetry')) {
      final token = request.headers.value('X-Smartkheti-Token');
      if (token != _sharedToken) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.write(jsonEncode({'error': 'Unauthorized'}));
        await request.response.close();
        return;
      }

      if (!_checkRateLimit()) {
        request.response.statusCode = 429;
        request.response.write(jsonEncode({'error': 'Rate limit exceeded'}));
        await request.response.close();
        return;
      }

      try {
        final bytes = await request
            .timeout(const Duration(seconds: 2))
            .fold<List<int>>(<int>[], (acc, data) {
          if (acc.length + data.length > 1024) {
            throw const HttpException('Payload too large');
          }
          return acc..addAll(data);
        });
        final content = utf8.decode(bytes, allowMalformed: true);
        final success = ingestRawJson(content);
        if (!success) {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write(jsonEncode({'error': 'Invalid telemetry schema'}));
          await request.response.close();
          return;
        }
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'status': 'ok',
          'valve_open': isValveOpen,
          'duration_sec': remainingValveSeconds,
        }));
        await request.response.close();
      } on HttpException {
        request.response.statusCode = HttpStatus.requestEntityTooLarge;
        await request.response.close();
      } on TimeoutException {
        request.response.statusCode = HttpStatus.requestTimeout;
        await request.response.close();
      } catch (_) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
      }
      return;
    }

    if (request.method == 'GET' && path == '/api/status') {
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'device': _telemetry.deviceId,
        'is_real_hardware': _isRealHardwareStreaming,
        'valve_open': isValveOpen,
        'remaining_seconds': remainingValveSeconds,
        'air_temp': _telemetry.dhtTempC,
        'humidity': _telemetry.dhtHumidityPercent,
        'soil_moisture': _telemetry.sn3000MoisturePercent,
        'soil_ec': _telemetry.soilEcUsCm,
        'rain': _telemetry.waterDetected,
      }));
      await request.response.close();
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  // ── Buffer ────────────────────────────────────────────────────────────────

  void _addToBuffer(Esp32Telemetry item) {
    if (_historyBuffer.length >= _maxBufferCapacity) {
      _historyBuffer.removeFirst();
    }
    _historyBuffer.addLast(item);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _hardwareWatchdogTimer?.cancel();
    _httpServer?.close(force: true);
    super.dispose();
  }
}
