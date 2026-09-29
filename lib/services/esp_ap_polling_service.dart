import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'esp32_backend_service.dart';

/// Polls the ESP32 Wi-Fi Access Point at the fixed gateway address.
///
/// ## Farmer UX
/// 1. Power on the SmartKheti field unit.
/// 2. Connect phone to the `SmartKheti-XXXX` Wi-Fi network
///    (password printed on the device label).
/// 3. Open the app — data appears automatically.
///
/// ## How it works
/// - ESP32 runs in AP mode → always reachable at [_esp32ApIp] (192.168.4.1)
/// - This service polls GET [_esp32ApIp]/data every [_pollIntervalSeconds] seconds
/// - Auth token sent in `X-Smartkheti-Token` request header
/// - Device identity confirmed by checking `device` field in JSON response
/// - On success: forwards raw JSON to [Esp32BackendService.ingestRawJson]
/// - On failure: increments [consecutiveFailures]; after [_maxFailures] → disconnected
///
/// ## Safety guards
/// - [_isRequesting] flag prevents concurrent overlapping requests
/// - Strict [_httpTimeoutSeconds] (2s) prevents hanging connections
/// - Timer cancelled in [dispose] to prevent memory leaks
class EspApPollingService extends ChangeNotifier {
  static final EspApPollingService instance = EspApPollingService._internal();
  EspApPollingService._internal();

  // ── Constants ─────────────────────────────────────────────────────────────

  /// Fixed IP of ESP32 in AP mode (always 192.168.4.1 for ESP32 SoftAP).
  static const String _esp32ApIp   = '192.168.4.1';
  static const int    _esp32ApPort = 80;

  /// Auth token — must match `SMARTKHETI_TOKEN` define in ESP32 firmware.
  static const String _authToken = 'smartkheti-field-2025';

  /// Expected device ID prefix in the JSON `device` field.
  static const String _expectedDevicePrefix = 'ESP32-S3-N16R8';

  static const int _pollIntervalSeconds = 5;
  static const int _httpTimeoutSeconds  = 2; // Must be < _pollIntervalSeconds
  static const int _maxFailures         = 3; // ~10s until disconnected banner shows

  // ── State ─────────────────────────────────────────────────────────────────
  Timer? _pollTimer;
  bool   _isRequesting = false;

  bool      _isConnected          = false;
  int       _consecutiveFailures  = 0;
  int       _totalPacketsReceived = 0;
  DateTime? _lastSuccessTime;
  String    _lastError            = '';

  // ── Accessors ─────────────────────────────────────────────────────────────
  bool      get isConnected          => _isConnected;
  int       get consecutiveFailures  => _consecutiveFailures;
  int       get totalPacketsReceived => _totalPacketsReceived;
  DateTime? get lastSuccessTime      => _lastSuccessTime;
  String    get lastError            => _lastError;
  String    get esp32Url             => 'http://$_esp32ApIp:$_esp32ApPort/data';

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Start polling. Call when the farmer connects their phone to the ESP32 AP.
  void startPolling() {
    if (_pollTimer?.isActive ?? false) return;
    _poll(); // fire immediately
    _pollTimer = Timer.periodic(
      const Duration(seconds: _pollIntervalSeconds),
      (_) => _poll(),
    );
  }

  /// Stop polling (e.g. when user leaves the monitoring screen).
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Manually trigger a single poll (e.g. pull-to-refresh).
  Future<void> refresh() => _poll();

  // ── Core polling logic ────────────────────────────────────────────────────

  Future<void> _poll() async {
    if (_isRequesting) return; // Guard: prevent concurrent requests
    _isRequesting = true;

    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: _httpTimeoutSeconds)
        ..idleTimeout       = const Duration(seconds: _httpTimeoutSeconds);

      HttpClientRequest request;
      try {
        request = await client
            .getUrl(Uri.parse(esp32Url))
            .timeout(const Duration(seconds: _httpTimeoutSeconds));
      } on TimeoutException {
        _recordFailure('Connection timeout — is the device powered on?');
        client.close(force: true);
        return;
      } on SocketException catch (e) {
        _recordFailure('Not connected to SmartKheti Wi-Fi: ${e.message}');
        client.close(force: true);
        return;
      }

      // Auth token in request header — client proves identity to server
      request.headers.set('X-Smartkheti-Token', _authToken);
      request.headers.set('Accept', 'application/json');

      HttpClientResponse response;
      try {
        response = await request.close()
            .timeout(const Duration(seconds: _httpTimeoutSeconds));
      } on TimeoutException {
        _recordFailure('Response timeout — sensor may be busy');
        client.close(force: true);
        return;
      }

      if (response.statusCode == 401) {
        _recordFailure('Token mismatch — check firmware configuration');
        await response.drain<void>();
        client.close();
        return;
      }

      if (response.statusCode != 200) {
        _recordFailure('HTTP ${response.statusCode}');
        await response.drain<void>();
        client.close();
        return;
      }

      // Read body with 1 KB cap (DoS guard — sensors produce < 300 bytes)
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
        if (bytes.length > 1024) {
          _recordFailure('Response too large — possible rogue device');
          client.close(force: true);
          return;
        }
      }
      client.close();

      final body = utf8.decode(bytes, allowMalformed: true);

      // Verify device identity before ingesting any data
      if (!_verifyDeviceIdentity(body)) {
        _recordFailure(
          'Device identity mismatch — wrong device at 192.168.4.1. '
          'Disconnect from other Wi-Fi networks and reconnect to SmartKheti.',
        );
        return;
      }

      // Forward to backend — uses existing _safeDouble/_safeInt validators
      final ingested = Esp32BackendService.instance.ingestRawJson(body);
      if (!ingested) {
        _recordFailure('Sensor data schema invalid');
        return;
      }

      _recordSuccess();
    } catch (e) {
      _recordFailure('Unexpected error: $e');
    } finally {
      _isRequesting = false;
    }
  }

  // ── Device identity verification ──────────────────────────────────────────

  /// Confirms the responding device is a SmartKheti ESP32, not a router or
  /// another AP that happens to occupy 192.168.4.1.
  bool _verifyDeviceIdentity(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return false;
      final device = decoded['device'];
      if (device is! String) return false;
      return device.startsWith(_expectedDevicePrefix);
    } catch (_) {
      return false;
    }
  }

  // ── State helpers ─────────────────────────────────────────────────────────

  void _recordSuccess() {
    _consecutiveFailures  = 0;
    _totalPacketsReceived++;
    _lastSuccessTime = DateTime.now();
    _lastError       = '';
    if (!_isConnected) {
      _isConnected = true;
      debugPrint('EspApPollingService: Connected to SmartKheti field unit');
    }
    notifyListeners();
  }

  void _recordFailure(String reason) {
    _consecutiveFailures++;
    _lastError = reason;
    debugPrint(
      'EspApPollingService: Failure ($_consecutiveFailures/$_maxFailures) — $reason',
    );
    if (_consecutiveFailures >= _maxFailures && _isConnected) {
      _isConnected = false;
      debugPrint('EspApPollingService: Disconnected after $_consecutiveFailures failures');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
