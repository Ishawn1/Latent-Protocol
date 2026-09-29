import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/esp32_telemetry.dart';
import '../services/esp32_backend_service.dart';
import '../widgets/app_card.dart';
import '../widgets/status_tag.dart';
import '../widgets/esp32_status_sheet.dart';

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen>
    with SingleTickerProviderStateMixin {
  final _backend = Esp32BackendService.instance;

  // AI-calculated moisture parameters for Pomegranate (Bhagwa)
  static const double minNeededMoisture = 40.0;
  static const double optimalCropMoisture = 70.0;
  static const double saturatedMoisture = 80.0;

  double _targetMoisture = optimalCropMoisture;
  double _currentMoisture = 27.0; // Baseline as requested: 27%
  int _manualDurationMinutes = 30;

  Timer? _simulationTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isAutoShutoffTriggered = false;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _backend.addListener(_onBackendTelemetryChanged);
    _syncMoistureFromTelemetry();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _backend.removeListener(_onBackendTelemetryChanged);
    super.dispose();
  }

  void _syncMoistureFromTelemetry() {
    final t = _backend.currentTelemetry;
    if (t.isMoistureValid && t.sn3000MoisturePercent != null) {
      _currentMoisture = t.sn3000MoisturePercent!;
    }
  }

  void _onBackendTelemetryChanged() {
    if (!mounted) return;
    _syncMoistureFromTelemetry();

    // If valve just opened and we weren't running simulation, start it
    if (_backend.isValveOpen && _simulationTimer == null) {
      _startIrrigationSession(
        durationSeconds: _backend.remainingValveSeconds > 0
            ? _backend.remainingValveSeconds
            : _calculateAiMinutes() * 60,
      );
    } else if (!_backend.isValveOpen && _simulationTimer != null) {
      _stopIrrigationSession();
    }

    setState(() {});
  }

  int _calculateAiMinutes() {
    final deficit = (_targetMoisture - _currentMoisture).clamp(0.0, 100.0);
    // Calculated based on 4 LPH Bhagwa drip line emitter specs:
    // ~0.8 minutes per 1% moisture deficit
    return (deficit * 0.8).round().clamp(10, 60);
  }

  void _startIrrigationSession({required int durationSeconds}) {
    _simulationTimer?.cancel();
    _countdownTimer?.cancel();

    _remainingSeconds = durationSeconds;
    _isAutoShutoffTriggered = false;

    // Countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _stopIrrigationSession();
        _backend.closeValve();
      }
    });

    // Simulated / progressive moisture increase toward target 70%
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 2400), (timer) {
      if (!mounted) return;
      if (_currentMoisture < _targetMoisture) {
        setState(() {
          _currentMoisture = (_currentMoisture + 1.0).clamp(0.0, 100.0);
        });

        // AUTO-STOP SAFETY INTERLOCK: Stop at target (70%)
        if (_currentMoisture >= _targetMoisture && !_isAutoShutoffTriggered) {
          _isAutoShutoffTriggered = true;
          _stopIrrigationSession();
          _backend.closeValve();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎯 AI Target Moisture (${_targetMoisture.toStringAsFixed(0)}%) reached! Valve shut off automatically to conserve water.',
              ),
              backgroundColor: AppColors.primaryGreen,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  void _stopIrrigationSession() {
    _simulationTimer?.cancel();
    _countdownTimer?.cancel();
    _simulationTimer = null;
    _countdownTimer = null;
    if (mounted) setState(() {});
  }

  void _handleStartAiIrrigation() {
    final t = _backend.currentTelemetry;

    // Safety interlock: Wet foliage / Rain
    if (t.waterDetected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Rain / Wet foliage detected. Irrigation held to prevent fungal spots.'),
          backgroundColor: AppColors.lossText,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final minutes = _calculateAiMinutes();
    _backend.openValve(durationMinutes: minutes);
    _startIrrigationSession(durationSeconds: minutes * 60);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('AI Drip Cycle started: $minutes min to reach ${_targetMoisture.toStringAsFixed(0)}% target.'),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleStartManualIrrigation(int minutes) {
    final t = _backend.currentTelemetry;
    if (t.waterDetected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Leaves are wet. Delaying watering to prevent disease.'),
          backgroundColor: AppColors.lossText,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _backend.openValve(durationMinutes: minutes);
    _startIrrigationSession(durationSeconds: minutes * 60);
  }

  void _handleStopIrrigation() {
    _backend.closeValve();
    _stopIrrigationSession();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Watering halted immediately.'),
        backgroundColor: AppColors.lossText,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = _backend.currentTelemetry;
    final isRunning = _backend.isValveOpen || _simulationTimer != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        title: Text(
          l10n.irrigationControl,
          style: const TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Esp32StatusSheet.show(context),
            icon: const Icon(LucideIcons.cpu, color: AppColors.primaryGreen),
            tooltip: 'ESP32 Node & Scenarios',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderLight, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Live Soil Moisture Status & Visual Range Gauge
              _buildMoistureStatusCard(isRunning),
              const SizedBox(height: 16),

              // 2. Active Session Controller (Countdown & Auto-shutoff progress)
              if (isRunning) ...[
                _buildActiveSessionCard(),
                const SizedBox(height: 16),
              ],

              // 3. AI Smart Irrigation Engine Card
              _buildAiIntelligenceCard(t, isRunning),
              const SizedBox(height: 16),

              // 4. Interactive Target Moisture Tuner
              _buildTargetTunerCard(isRunning),
              const SizedBox(height: 16),

              // 5. Manual Quick Runs & Durations
              _buildManualDurationCard(isRunning),
              const SizedBox(height: 16),

              // 6. Water Conservation Impact & Actuator Telemetry
              _buildWaterImpactCard(t),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Soil Moisture Status & Visual Range Gauge ──────────────────────────

  Widget _buildMoistureStatusCard(bool isRunning) {
    Color statusColor;
    String statusLabel;
    String statusDesc;

    if (_currentMoisture < minNeededMoisture) {
      statusColor = Colors.redAccent;
      statusLabel = 'Moisture Deficit (${_currentMoisture.toStringAsFixed(0)}%)';
      statusDesc =
          'Below the 40% minimum threshold. Root zone is thirsty; fruit expansion is slowed.';
    } else if (_currentMoisture >= minNeededMoisture && _currentMoisture <= saturatedMoisture) {
      statusColor = AppColors.primaryGreen;
      statusLabel = 'Optimal (${_currentMoisture.toStringAsFixed(0)}%)';
      statusDesc =
          'Soil moisture is within the prime range for Bhagwa pomegranate trees (Target: 70%).';
    } else {
      statusColor = Colors.blue[700]!;
      statusLabel = 'Saturated (${_currentMoisture.toStringAsFixed(0)}%)';
      statusDesc =
          'Above 80% saturation threshold. Hold irrigation to protect roots against rot.';
    }

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.droplets, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Root-Zone Soil Moisture',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              StatusTag(
                label: statusLabel,
                backgroundColor: statusColor.withValues(alpha: 0.12),
                textColor: statusColor,
                fontSize: 12,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Visual Moisture Spectrum: <40% Red | 40-75% Green (Target 70%) | >80% Blue
          Stack(
            children: [
              Container(
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
              ),
              // Deficit Zone (0 - 40%)
              FractionallySizedBox(
                widthFactor: 0.40,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.25),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                  ),
                ),
              ),
              // Optimal Zone (40 - 75%)
              Positioned(
                left: MediaQuery.of(context).size.width * 0.32,
                width: MediaQuery.of(context).size.width * 0.30,
                top: 0,
                bottom: 0,
                child: Container(
                  color: AppColors.accentGreen.withValues(alpha: 0.25),
                ),
              ),
              // Current Reading Fill
              FractionallySizedBox(
                widthFactor: (_currentMoisture / 100.0).clamp(0.02, 1.0),
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Zone Markers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0% Dry', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              Text('Min 40%', style: TextStyle(color: Colors.red[700], fontSize: 10, fontWeight: FontWeight.w600)),
              const Text('🎯 70% Target',
                  style: TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
              Text('>80% High', style: TextStyle(color: Colors.blue[700], fontSize: 10, fontWeight: FontWeight.w600)),
              const Text('100%', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            statusDesc,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.35),
          ),
        ],
      ),
    );
  }

  // ── 2. Active Session Card (Countdown & Simulation) ───────────────────────

  Widget _buildActiveSessionCard() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.08 + (_pulseController.value * 0.04)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.4 + (_pulseController.value * 0.3)),
              width: 1.8,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.droplets, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Irrigation In Progress',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Drip lines active • Flowing to Section A1',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Auto-Stop @ 70%',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Countdown Display
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.blue[900],
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rising toward ${_targetMoisture.toStringAsFixed(0)}% Target (Currently: ${_currentMoisture.toStringAsFixed(0)}%)',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Emergency Stop Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _handleStopIrrigation,
                  icon: const Icon(LucideIcons.power, color: Colors.white, size: 18),
                  label: const Text(
                    'Stop Watering Now',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 3. AI Smart Irrigation Engine Card ────────────────────────────────────

  Widget _buildAiIntelligenceCard(Esp32Telemetry t, bool isRunning) {
    final aiMinutes = _calculateAiMinutes();
    final deficit = (_targetMoisture - _currentMoisture).clamp(0.0, 100.0);
    final waterVolumeLiters = (deficit * 0.65).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.sparkles, color: AppColors.primaryGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'AI Water Engine Calculation',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              StatusTag(
                label: 'Autonomous Drip',
                backgroundColor: AppColors.accentGreen.withValues(alpha: 0.15),
                textColor: AppColors.primaryGreen,
                fontSize: 11,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Reasoning Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Crop: Pomegranate (Bhagwa Variety)',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Stage: Mrig Bahar',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Current soil moisture is ${_currentMoisture.toStringAsFixed(0)}% vs ${_targetMoisture.toStringAsFixed(0)}% target (Deficit: ${deficit.toStringAsFixed(0)}%). '
                  'AI calculated ~${waterVolumeLiters}L/tree over $aiMinutes min cycle to saturate root-zone to 70% without runoff.',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Environmental Factors Considered
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFactorChip(LucideIcons.sun, '32°C Clear Sky', Colors.orange),
              _buildFactorChip(LucideIcons.wind, 'ET₀ 4.8 mm/day', Colors.deepPurple),
              _buildFactorChip(
                t.waterDetected ? LucideIcons.cloudRain : LucideIcons.checkCircle2,
                t.waterDetected ? 'Rain: WET' : 'Rain Sensor: DRY',
                t.waterDetected ? Colors.red : AppColors.primaryGreen,
              ),
              _buildFactorChip(LucideIcons.clock, 'Window: 6 AM / 5 PM', Colors.blue[700]!),
            ],
          ),
          const SizedBox(height: 16),

          // Primary AI Action Button
          if (!isRunning)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _handleStartAiIrrigation,
                icon: const Icon(LucideIcons.play, color: Colors.white, size: 18),
                label: Text(
                  'Start AI Irrigation ($aiMinutes Min to ${_targetMoisture.toStringAsFixed(0)}%)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFactorChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── 4. Interactive Target Moisture Tuner ──────────────────────────────────

  Widget _buildTargetTunerCard(bool isRunning) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target Soil Moisture',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '70% is agronomic standard for Bhagwa',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              Text(
                '${_targetMoisture.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryGreen,
              inactiveTrackColor: AppColors.borderLight,
              thumbColor: AppColors.primaryGreen,
              overlayColor: AppColors.primaryGreen.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: _targetMoisture,
              min: 50.0,
              max: 75.0,
              divisions: 5,
              label: '${_targetMoisture.toStringAsFixed(0)}%',
              onChanged: isRunning
                  ? null
                  : (val) {
                      setState(() => _targetMoisture = val);
                    },
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Manual Duration Quick Runs ─────────────────────────────────────────

  Widget _buildManualDurationCard(bool isRunning) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manual Quick Irrigation',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [15, 30, 45].map((dur) {
              final isSel = _manualDurationMinutes == dur;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$dur Min'),
                  selected: isSel,
                  selectedColor: AppColors.primaryGreen,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: isRunning
                      ? null
                      : (val) {
                          if (val) setState(() => _manualDurationMinutes = dur);
                        },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          if (!isRunning)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _handleStartManualIrrigation(_manualDurationMinutes),
                icon: const Icon(LucideIcons.timer, size: 16),
                label: Text('Run Manual: $_manualDurationMinutes Minutes'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── 6. Water Conservation Impact & Actuator Telemetry ─────────────────────

  Widget _buildWaterImpactCard(Esp32Telemetry t) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.gauge, color: AppColors.primaryGreen, size: 18),
              SizedBox(width: 8),
              Text(
                'Hardware & Valve Telemetry',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTelemetryCell('Flow Rate', '4.2 L/min', LucideIcons.waves),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTelemetryCell('Line Pressure', '1.8 Bar', LucideIcons.activity),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTelemetryCell('Valve Status', _backend.isValveOpen ? 'OPEN' : 'CLOSED',
                    _backend.isValveOpen ? LucideIcons.check : LucideIcons.xCircle),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCell(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
