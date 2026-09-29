import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/esp32_telemetry.dart';

/// Service managing Android System Tray notifications for ESP32-S3 Edge-AI alerts.
///
/// Features:
/// - Dedicated high-priority Android notification channel with sound & vibration.
/// - Edge-triggered state evaluation (alerts on state change).
/// - Persistent 15-minute anti-spam cooldown across app restarts.
/// - Cold-start payload buffering for safe deep-link navigation.
class AlertNotificationService {
  static final AlertNotificationService instance = AlertNotificationService._internal();
  AlertNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static const String _channelId = 'smartkheti_edge_ai_channel';
  static const String _channelName = 'SmartKheti Edge-AI Diagnostics';
  static const String _channelDesc =
      'Urgent on-chip neural alerts for root-zone irrigation and crop leaf inspection';

  static const int _waterStressNotificationId = 1001;
  static const int _inspectionNotificationId = 1002;

  static const String _prefWaterStressMs = 'smartkheti_last_water_stress_ms';
  static const String _prefInspectionMs = 'smartkheti_last_inspection_ms';

  static const Duration _cooldownDuration = Duration(minutes: 15);

  // Synchronous in-memory state guards
  bool _isInitialized = false;
  bool _hasNotificationPermission = false;
  bool _lastWaterStressAlert = false;
  DateTime? _lastWaterStressNotifyTime;

  bool _lastInspectionAlert = false;
  DateTime? _lastInspectionNotifyTime;

  // Cold-start pending action payload
  String? _pendingActionPayload;
  void Function(String payload)? _actionHandler;

  bool get hasNotificationPermission => _hasNotificationPermission;

  /// Initializes local notifications, sets up high-importance Android channel,
  /// loads persisted cooldown timestamps, and attaches the payload tap handler.
  Future<void> initialize({void Function(String payload)? onAction}) async {
    if (_isInitialized) {
      if (onAction != null) {
        _actionHandler = onAction;
        _flushPendingPayload();
      }
      return;
    }

    _actionHandler = onAction;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handlePayload(payload);
        }
      },
    );

    // Create high-importance notification channel for Android 8.0+ (API 26+)
    final androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 250, 150, 250]),
      playSound: true,
    );

    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);

      // Request runtime permission for Android 13+ (API 33+)
      final granted = await androidPlugin.requestNotificationsPermission();
      _hasNotificationPermission = granted ?? false;
    } else {
      _hasNotificationPermission = true;
    }

    // Load persisted timestamps from SharedPreferences
    await _loadPersistedTimestamps();

    _isInitialized = true;
    _flushPendingPayload();
  }

  /// Sets or updates the navigation action handler (e.g. from main.dart).
  void setActionHandler(void Function(String payload) handler) {
    _actionHandler = handler;
    _flushPendingPayload();
  }

  void _handlePayload(String payload) {
    if (_actionHandler != null) {
      _actionHandler!(payload);
    } else {
      _pendingActionPayload = payload;
    }
  }

  void _flushPendingPayload() {
    if (_pendingActionPayload != null && _actionHandler != null) {
      final payload = _pendingActionPayload!;
      _pendingActionPayload = null;
      _actionHandler!(payload);
    }
  }

  Future<void> _loadPersistedTimestamps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wsMs = prefs.getInt(_prefWaterStressMs);
      if (wsMs != null && wsMs > 0) {
        _lastWaterStressNotifyTime = DateTime.fromMillisecondsSinceEpoch(wsMs);
      }
      final inspMs = prefs.getInt(_prefInspectionMs);
      if (inspMs != null && inspMs > 0) {
        _lastInspectionNotifyTime = DateTime.fromMillisecondsSinceEpoch(inspMs);
      }
    } catch (e) {
      debugPrint('AlertNotificationService: Error reading preferences: $e');
    }
  }

  void _persistTimestamp(String key, DateTime time) {
    // Non-blocking async write to disk
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(key, time.millisecondsSinceEpoch);
    }).catchError((e) {
      debugPrint('AlertNotificationService: Error writing preference $key: $e');
    });
  }

  /// Evaluates incoming ESP32-S3 telemetry for on-chip Edge-AI alerts.
  ///
  /// State check and timestamp update occur synchronously on the Dart isolate
  /// before any async notification dispatch, guaranteeing that rapid packets
  /// do not cause duplicate notifications.
  void evaluateTelemetry(Esp32Telemetry t) {
    if (!_isInitialized) return;

    final now = DateTime.now();

    // ─────────────────────────────────────────────────────────────────────────
    // 1. IRRIGATION NEEDED Evaluation
    // ─────────────────────────────────────────────────────────────────────────
    if (t.aiWaterStressAlert) {
      final shouldNotify = !_lastWaterStressAlert ||
          _lastWaterStressNotifyTime == null ||
          now.difference(_lastWaterStressNotifyTime!) >= _cooldownDuration;

      // Update state synchronously
      _lastWaterStressAlert = true;

      if (shouldNotify) {
        _lastWaterStressNotifyTime = now;
        _persistTimestamp(_prefWaterStressMs, now);

        final probText = t.aiWaterStressProb != null ? '${t.aiWaterStressProb!.toStringAsFixed(1)}%' : 'Critical';

        _showNotification(
          id: _waterStressNotificationId,
          title: '💧 SmartKheti Edge-AI: IRRIGATION NEEDED',
          body: 'Root-zone water stress probability is $probText. Tap to open irrigation valve controls.',
          payload: 'action_irrigate',
        );
      }
    } else {
      // Alert condition cleared on the field node
      _lastWaterStressAlert = false;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. INSPECTION REQUIRED Evaluation (ESP32-S3 On-Chip Edge-AI Inference)
    // ─────────────────────────────────────────────────────────────────────────
    if (t.aiInspectionAlert) {
      final shouldNotify = !_lastInspectionAlert ||
          _lastInspectionNotifyTime == null ||
          now.difference(_lastInspectionNotifyTime!) >= _cooldownDuration;

      // Update state synchronously
      _lastInspectionAlert = true;

      if (shouldNotify) {
        _lastInspectionNotifyTime = now;
        _persistTimestamp(_prefInspectionMs, now);

        final probText =
            t.aiCropInspectionProb != null ? '${t.aiCropInspectionProb!.toStringAsFixed(1)}%' : 'High Risk';

        _showNotification(
          id: _inspectionNotificationId,
          title: '🔍 SmartKheti Edge-AI: INSPECTION REQUIRED',
          body: 'On-chip anomaly risk is $probText. Tap to launch YOLO Leaf Scanner.',
          payload: 'action_inspect',
        );
      }
    } else {
      // Alert condition cleared on the field node
      _lastInspectionAlert = false;
    }
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'SmartKheti Edge-AI Alert',
      styleInformation: BigTextStyleInformation(''),
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('AlertNotificationService: Error showing notification: $e');
    }
  }

  /// Cancels all active Edge-AI notifications.
  Future<void> cancelAlerts() async {
    await _notificationsPlugin.cancel(id: _waterStressNotificationId);
    await _notificationsPlugin.cancel(id: _inspectionNotificationId);
  }
}
