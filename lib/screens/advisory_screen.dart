import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/esp32_telemetry.dart';
import '../services/esp32_backend_service.dart';
import '../widgets/app_card.dart';
import '../widgets/esp32_status_sheet.dart';
import 'disease_detection/disease_detection_screen.dart';

class AdvisoryScreen extends StatelessWidget {
  const AdvisoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final backend = Esp32BackendService.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        title: Text(
          l10n.advisoryAlerts,
          style: const TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Esp32StatusSheet.show(context),
            icon: const Icon(LucideIcons.slidersHorizontal, color: AppColors.primaryGreen),
            tooltip: 'ESP32 Hardware & Scenarios',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderLight, height: 1),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: backend,
          builder: (context, _) {
            final t = backend.currentTelemetry;
            final alerts = _generateDynamicAlerts(context, t, backend);

            return RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // Hardware banner
                  _buildHardwareBanner(context, t, backend.isRealHardwareStreaming),
                  const SizedBox(height: 16),

                  // Dynamic Alert Cards
                  for (int i = 0; i < alerts.length; i++) ...[
                    alerts[i],
                    if (i < alerts.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHardwareBanner(BuildContext context, Esp32Telemetry t, bool isLive) {
    return InkWell(
      onTap: () => Esp32StatusSheet.show(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isLive
              ? AppColors.primaryGreen.withValues(alpha: 0.08)
              : AppColors.accentOrange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLive
                ? AppColors.primaryGreen.withValues(alpha: 0.3)
                : AppColors.accentOrange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.cpu,
              size: 18,
              color: isLive ? AppColors.primaryGreen : AppColors.accentOrange,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live ESP32 Hardware Active (Node 1)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  Text(
                    'DHT22: ${t.dhtTempC != null ? '${t.dhtTempC!.toStringAsFixed(1)}°C' : 'ERR'} | SN3000: ${t.sn3000MoisturePercent != null ? '${t.sn3000MoisturePercent!.toStringAsFixed(1)}%' : 'ERR'} | Rain: ${t.waterDetected ? 'WET' : 'DRY'}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  List<Widget> _generateDynamicAlerts(
    BuildContext context,
    Esp32Telemetry t,
    Esp32BackendService backend,
  ) {
    final list = <Widget>[];

    // 1. Disease Outbreak Risk Alert
    final dsvVal = t.dsv ?? 0.0;
    if (dsvVal >= 3.0 || t.waterDetected) {
      list.add(_buildAlertCard(
        context: context,
        icon: LucideIcons.shieldAlert,
        iconColor: Colors.red,
        title: 'High Pathogen Outbreak Risk (DSV: ${dsvVal.toStringAsFixed(1)})',
        description:
            'Water sensor detected leaf surface wetness and DHT22 temperature (${t.dhtTempC != null ? '${t.dhtTempC!.toStringAsFixed(1)}°C' : 'ERR'}) is in the critical multiplication zone. Spores of Alternaria and Bacterial Blight germinate within 6-8 hours of sustained wetness.',
        actionLabel: 'Launch Optical Scout Scan',
        onAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DiseaseDetectionScreen()),
          );
        },
      ));
    }

    // 2. Severe Water Stress / Drought Alert
    final moisture = t.sn3000MoisturePercent;
    if (moisture != null && moisture < 25.0) {
      final isOpen = backend.isValveOpen;
      list.add(_buildAlertCard(
        context: context,
        icon: LucideIcons.alertTriangle,
        iconColor: Colors.deepOrange,
        title: 'Severe Root-Zone Water Stress (${moisture.toStringAsFixed(1)}%)',
        description:
            'SN-3000 sensor indicates soil moisture has breached the Permanent Wilting Point (<25%). Plants are unable to extract capillary water, risking leaf drop and fruit cracking.',
        actionLabel: isOpen ? 'Valve is Currently Open' : 'Open 12V Valve (30 Min)',
        actionColor: isOpen ? Colors.grey : AppColors.primaryGreen,
        onAction: isOpen ? null : () => backend.openValve(durationMinutes: 30),
      ));
    }

    // 3. Over-irrigation / Root Asphyxiation Alert
    if (moisture != null && moisture > 85.0) {
      list.add(_buildAlertCard(
        context: context,
        icon: LucideIcons.droplets,
        iconColor: Colors.blue,
        title: 'Soil Saturation & Root Asphyxiation (${moisture.toStringAsFixed(1)}%)',
        description:
            'Root-zone soil pores are saturated with water, depleting dissolved oxygen. Continued irrigation will trigger anaerobic root rot. Ensure field drainage channels are clear.',
      ));
    }

    // 4. Extreme Heat Shock Alert
    final airTemp = t.dhtTempC;
    if (airTemp != null && airTemp > 38.0) {
      list.add(_buildAlertCard(
        context: context,
        icon: LucideIcons.flame,
        iconColor: Colors.redAccent,
        title: 'Extreme Heat Shock Warning (${airTemp.toStringAsFixed(1)}°C)',
        description:
            'Vapor Pressure Deficit is elevated (${t.vpdKpa != null ? '${t.vpdKpa!.toStringAsFixed(2)} kPa' : '–'}). High transpiration rate will cause midday leaf scorch and flower drop. Avoid chemical sprays during peak heat.',
      ));
    }

    // (Battery alert removed — battery not reported by current firmware)

    // 6. Optimal Baseline Status Card (when no critical alerts exist)
    if (list.isEmpty) {
      list.add(_buildAlertCard(
        context: context,
        icon: LucideIcons.checkCircle2,
        iconColor: AppColors.primaryGreen,
        title: 'Microclimate & Soil Conditions Stable',
        description:
            'DHT22 temperature (${t.dhtTempC?.toStringAsFixed(1) ?? '–'}°C) and SN-3000 moisture (${t.sn3000MoisturePercent?.toStringAsFixed(1) ?? '–'}%) are within healthy agronomic limits. Disease Severity Value is low (${t.dsv?.toStringAsFixed(1) ?? '0.0'}). No immediate intervention required.',
      ));
    }

    return list;
  }

  Widget _buildAlertCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    String? actionLabel,
    Color? actionColor,
    VoidCallback? onAction,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(LucideIcons.arrowRight, size: 14),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor ?? AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

