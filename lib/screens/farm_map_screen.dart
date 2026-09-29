import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/farm_models.dart';
import '../models/esp32_telemetry.dart';
import '../services/esp32_backend_service.dart';
import '../widgets/app_card.dart';
import '../widgets/status_tag.dart';
import '../widgets/esp32_status_sheet.dart';
import 'disease_detection/live_detection_screen.dart';

class FarmMapScreen extends StatefulWidget {
  const FarmMapScreen({super.key});

  @override
  State<FarmMapScreen> createState() => _FarmMapScreenState();
}

class _FarmMapScreenState extends State<FarmMapScreen> {
  final _backend = Esp32BackendService.instance;
  final Plot _plot = Plot.demoOrchard;

  void _showZoneDetailSheet(BuildContext context, VirtualZone zone, bool isLiveNode) {
    final t = _backend.currentTelemetry;

    // Resolve moisture safely: avoid magic numbers like -1.0; use nullable double?
    final double? moisture = isLiveNode
        ? (t.isMoistureValid ? t.sn3000MoisturePercent : null)
        : (zone.soilMoisturePercent > 0 ? zone.soilMoisturePercent : null);

    final double? temp = isLiveNode
        ? (t.isTempValid ? t.dhtTempC : null)
        : zone.tempC;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and crop information
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Section ${zone.id}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pomegranate (${zone.cropVariety}) • ${zone.name}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  StatusTag(
                    label: zone.statusLabel,
                    backgroundColor: zone.statusColor.withValues(alpha: 0.15),
                    textColor: zone.statusColor,
                    fontSize: 12,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Unified telemetry in modal
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.droplet, size: 16, color: Colors.blue),
                              SizedBox(width: 6),
                              Text('Soil Moisture', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            moisture != null ? '${moisture.toStringAsFixed(0)}% (${moisture < 35 ? 'Dry' : 'Good'})' : 'Checking...',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.thermometer, size: 16, color: Colors.orange),
                              SizedBox(width: 6),
                              Text('Zone Temp', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            temp != null ? '${temp.toStringAsFixed(1)} °C' : 'Offline',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (zone.activeConcern != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: zone.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: zone.statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.alertCircle, color: zone.statusColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Alert: ${zone.activeConcern!}',
                          style: TextStyle(
                            color: zone.statusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LiveDetectionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.camera, color: Colors.white, size: 18),
                  label: Text(
                    'Scan Leaves in Section ${zone.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        title: Text(
          l10n.farmMap,
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
            tooltip: 'Hardware Status',
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
              // Orchard Overview Card
              _buildOrchardOverviewCard(l10n),
              const SizedBox(height: 16),

              // Map Legend
              _buildLegendSection(l10n),
              const SizedBox(height: 16),

              // Interactive Virtual Zone Grid (dynamic telemetry scoped)
              ListenableBuilder(
                listenable: _backend,
                builder: (context, _) {
                  final t = _backend.currentTelemetry;
                  return _buildZoneGrid(context, t, l10n);
                },
              ),
              const SizedBox(height: 20),

              // Hardware Hub Callout (dynamic telemetry scoped)
              ListenableBuilder(
                listenable: _backend,
                builder: (context, _) {
                  final t = _backend.currentTelemetry;
                  return _buildHardwareHubPin(t, l10n);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrchardOverviewCard(AppLocalizations l10n) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.mapPin, color: AppColors.primaryGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _plot.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusTag(
                      label: 'Active Farm',
                      backgroundColor: AppColors.farmHealthTagBg,
                      textColor: AppColors.farmHealthTagText,
                      fontSize: 10,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${_plot.areaAcres} Acres • 6 Field Sections • Kharva, Gujarat',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendSection(AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildLegendItem(const Color(0xFF16A34A), 'Healthy 🟢'),
          const SizedBox(width: 12),
          _buildLegendItem(const Color(0xFFEAB308), 'Needs Water 💧'),
          const SizedBox(width: 12),
          _buildLegendItem(const Color(0xFFEA580C), 'Disease Alert 🔍'),
          const SizedBox(width: 12),
          _buildLegendItem(const Color(0xFF94A3B8), 'Pending Scout ⏳'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildZoneGrid(
    BuildContext context,
    Esp32Telemetry t,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Farm Sections (Tap to Inspect Any Section)',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < _plot.zones.length; i += 2) ...[
          Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 0.94,
                  child: _buildZoneCard(context, _plot.zones[i], t),
                ),
              ),
              const SizedBox(width: 12),
              if (i + 1 < _plot.zones.length)
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 0.94,
                    child: _buildZoneCard(context, _plot.zones[i + 1], t),
                  ),
                )
              else
                const Spacer(),
            ],
          ),
          if (i + 2 < _plot.zones.length) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildZoneCard(
    BuildContext context,
    VirtualZone zone,
    Esp32Telemetry t,
  ) {
    final isLiveNode = zone.hasHardwareNode;

    final double? moisture = isLiveNode
        ? (t.isMoistureValid ? t.sn3000MoisturePercent : null)
        : (zone.soilMoisturePercent > 0 ? zone.soilMoisturePercent : null);

    return GestureDetector(
      onTap: () => _showZoneDetailSheet(context, zone, isLiveNode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: zone.statusColor.withValues(alpha: 0.6),
            width: isLiveNode ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: zone.statusColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Section Tag + LIVE/HUB badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: zone.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Section ${zone.id}',
                    style: TextStyle(
                      color: zone.statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isLiveNode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(LucideIcons.radio, size: 10, color: AppColors.primaryGreen),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Middle: Name and active concern
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Section ${zone.id}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  zone.activeConcern != null ? 'Alert: ${zone.activeConcern!}' : 'Healthy & Good',
                  style: TextStyle(
                    color: zone.activeConcern != null ? zone.statusColor : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: zone.activeConcern != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            // Bottom Structured Telemetry (Moisture + Scouted time with zero overlapping)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.droplets, size: 12, color: Colors.blue[600]),
                          const SizedBox(width: 4),
                          Text(
                            moisture != null ? '${moisture.toStringAsFixed(0)}%' : 'Checking',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: (moisture != null && moisture < 35)
                              ? Colors.red.withValues(alpha: 0.15)
                              : AppColors.accentGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          moisture != null ? (moisture < 35 ? 'Dry' : 'Good') : '–',
                          style: TextStyle(
                            color: (moisture != null && moisture < 35)
                                ? Colors.red
                                : AppColors.primaryGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.clock, size: 10, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          zone.lastScoutedTime,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHardwareHubPin(Esp32Telemetry t, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.radio, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📡 SmartKheti Sensor Hub: Section A1',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Section A1 is monitored 24/7 by your physical ESP32 sensor box. Other sections reflect optical scouting passes.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
