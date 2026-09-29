import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/esp32_backend_service.dart';
import '../models/esp32_telemetry.dart';
import '../theme/app_theme.dart';

// Helper: format a nullable double for display. Shows '–' when null.
String _fmt(double? v, {int decimals = 1, String unit = ''}) {
  if (v == null) return '–';
  return '${v.toStringAsFixed(decimals)}$unit';
}

String _fmtInt(int? v, {String unit = ''}) {
  if (v == null) return '–';
  return '$v$unit';
}

/// Modal bottom sheet providing transparent visibility into the ESP32-S3 backend.
///
/// Displays:
/// - Real-time active hardware sensors (DHT22, SN-3000, Water, Battery)
/// - Placeholders for future sensors (Flow meter, Solar radiation, Barometer)
/// - The local HTTP endpoint for the real ESP32 to POST data
/// - Interactive scenario switcher to simulate real-world field disasters
class Esp32StatusSheet extends StatefulWidget {
  const Esp32StatusSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const Esp32StatusSheet(),
    );
  }

  @override
  State<Esp32StatusSheet> createState() => _Esp32StatusSheetState();
}

class _Esp32StatusSheetState extends State<Esp32StatusSheet> {
  final _backend = Esp32BackendService.instance;

  @override
  void initState() {
    super.initState();
    _backend.addListener(_onBackendUpdate);
  }

  @override
  void dispose() {
    _backend.removeListener(_onBackendUpdate);
    super.dispose();
  }

  void _onBackendUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = _backend.currentTelemetry;
    final isLive = _backend.isHardwareConnected;
    final endpointUrl = 'http://${_backend.serverIp}:${_backend.serverPort}/api/telemetry';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isLive
                            ? AppColors.primaryGreen.withValues(alpha: 0.1)
                            : AppColors.accentOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.cpu,
                        color: isLive ? AppColors.primaryGreen : AppColors.accentOrange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ESP32-S3 Field Hub (Node 1)',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _backend.isRealHardwareStreaming
                                  ? 'Live Hardware • Packets: ${_backend.receivedPacketCount}'
                                  : 'Simulation Mode • No Hardware Detected',
                              style: TextStyle(
                                color: _backend.isRealHardwareStreaming
                                    ? AppColors.primaryGreen
                                    : AppColors.accentOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.borderLight),

          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // AP endpoint info card
                _buildEndpointCard(endpointUrl),
                const SizedBox(height: 20),

                // Real hardware sensors
                const Text(
                  'LIVE HARDWARE SENSORS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                _buildActiveSensorsGrid(telemetry),
                const SizedBox(height: 20),

                // Solenoid Valve Control
                _buildValveControlCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointCard(String endpointUrl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.radio, size: 16, color: AppColors.primaryGreen),
                  SizedBox(width: 6),
                  Text(
                    'ESP32 HTTP Ingestion Endpoint',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Port ${_backend.serverPort}',
                  style: const TextStyle(
                    color: AppColors.accentGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    endpointUrl,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: endpointUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Endpoint URL copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Icon(LucideIcons.copy, size: 16, color: AppColors.primaryGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Node 1 telemetry streaming via local Wi-Fi Mesh AP on port ${_backend.serverPort}.',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSensorsGrid(Esp32Telemetry t) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSensorTile(
          title: 'DHT22 Air Temp',
          value: _fmt(t.dhtTempC, unit: ' °C'),
          subtitle: 'Humidity: ${_fmt(t.dhtHumidityPercent, decimals: 0, unit: '%')}',
          icon: LucideIcons.thermometer,
          iconColor: t.dhtTempC != null ? Colors.orange : Colors.grey,
        ),
        _buildSensorTile(
          title: 'SN-3000 Soil Moist',
          value: _fmt(t.sn3000MoisturePercent, unit: ' %'),
          subtitle: t.soilEcAvailable
              ? 'Temp: ${_fmt(t.sn3000SoilTempC, unit: ' °C')}  EC: ${_fmtInt(t.soilEcUsCm, unit: ' µS/cm')}'
              : 'Temp: ${_fmt(t.sn3000SoilTempC, unit: ' °C')}',
          icon: LucideIcons.droplets,
          iconColor: t.sn3000MoisturePercent != null ? Colors.blue : Colors.grey,
        ),
        _buildSensorTile(
          title: 'Water / Rain Sensor',
          value: t.waterDetected ? 'WET / RAIN' : 'DRY',
          subtitle: t.waterDetected ? 'High Pathogen Risk' : 'Normal',
          icon: LucideIcons.cloudRain,
          iconColor: t.waterDetected ? Colors.teal : Colors.grey,
        ),
        _buildSensorTile(
          title: 'VPD',
          value: _fmt(t.vpdKpa, unit: ' kPa'),
          subtitle: t.waterStressStatus ?? '–',
          icon: LucideIcons.wind,
          iconColor: t.vpdKpa != null ? Colors.deepPurple : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildSensorTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildValveControlCard() {
    final isOpen = _backend.isValveOpen;
    final remaining = _backend.remainingValveSeconds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOpen ? Colors.blue.withValues(alpha: 0.08) : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOpen ? Colors.blue : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.power, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    '12V Solenoid Valve Actuator',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.blue : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOpen ? 'VALVE OPEN (${remaining ~/ 60}m ${remaining % 60}s)' : 'VALVE CLOSED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOpen ? Colors.white : Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isOpen) {
                      _backend.closeValve();
                    } else {
                      _backend.openValve(durationMinutes: 30);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOpen ? Colors.red : AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(isOpen ? 'Close Valve Now' : 'Open Valve (30 Min Timer)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
