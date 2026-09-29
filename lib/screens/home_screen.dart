import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/esp32_telemetry.dart';
import '../services/esp32_backend_service.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import '../widgets/esp32_status_sheet.dart';
import 'disease_detection/disease_detection_screen.dart';
import 'irrigation_screen.dart';
import 'farm_map_screen.dart';
import 'advisory_screen.dart';
import 'farm_analytics_screen.dart';
import '../widgets/weather_forecast_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final backend = Esp32BackendService.instance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ListenableBuilder(
        listenable: backend,
        builder: (context, _) {
          final telemetry = backend.currentTelemetry;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with Farmer Greeting & Farm Identification
              _buildHeaderCard(context, l10n, telemetry),
              const SizedBox(height: 16),

              // 2. Unified Hero Card: Actionable Watering & Moisture Status
              _buildUnifiedHeroCard(context, l10n, telemetry, backend),
              const SizedBox(height: 16),

              // 3. Live Environmental Sensor Telemetry Grid (DHT22 + SN-3000 + Rain)
              _buildTelemetryGrid(context, l10n, telemetry, backend),
              const SizedBox(height: 18),

              // 4. 5-Day Weather Forecast Widget (Kharva, Gujarat)
              const WeatherForecastCard(),
              const SizedBox(height: 18),

              // 5. Field Risk Indicators & Crop Pathogen Summary
              _buildRiskSummarySection(context, telemetry),
              const SizedBox(height: 18),

              // 6. Smart Farming Core Tools (Live Scan, Irrigation, Map, Analytics, Advisory, Mandi)
              _buildFarmToolsSection(context, l10n, backend),
            ],
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 1. HEADER CARD (Unified, Clean, No Mode Switcher)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildHeaderCard(
    BuildContext context,
    AppLocalizations l10n,
    Esp32Telemetry t,
  ) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = l10n.goodMorning;
    } else if (hour < 17) {
      greeting = l10n.goodAfternoon;
    } else {
      greeting = l10n.goodEvening;
    }

    final isLive = t.isHardwareLive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.accentGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, Suresh Bhai 🌱',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bhagwa Orchard • Kharva, Gujarat (3.5 Acres)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Esp32StatusSheet.show(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: const Icon(LucideIcons.cpu, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Hardware & Telemetry Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isLive ? const Color(0xFF4ADE80) : Colors.amberAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isLive
                        ? 'ESP32 Field Node 1 • Live Telemetry Active'
                        : 'SmartKheti Field Hub • Standby / Demo Mode',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => Esp32StatusSheet.show(context),
                  child: const Text(
                    'Node Info',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 2. UNIFIED HERO CARD (Clear Action + Soil Moisture Dial)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildUnifiedHeroCard(
    BuildContext context,
    AppLocalizations l10n,
    Esp32Telemetry t,
    Esp32BackendService backend,
  ) {
    final isOpen = backend.isValveOpen;
    final moisture = t.sn3000MoisturePercent;

    String title;
    String description;
    String actionLabel;
    IconData icon;
    Color color;
    VoidCallback onAction;

    if (!t.isMoistureValid || moisture == null) {
      title = l10n.checkingSensors;
      description = 'Connecting to SN-3000 soil probe. Ensure Field Node 1 is powered.';
      actionLabel = 'Check Node Probe';
      icon = LucideIcons.radio;
      color = Colors.grey[700]!;
      onAction = () => Esp32StatusSheet.show(context);
    } else if (isOpen) {
      final remainingMin = backend.remainingValveSeconds ~/ 60;
      title = 'Drip Irrigation in Progress 💧';
      description = '12V solenoid valve active. ${remainingMin}m remaining with auto-shutoff at target 70%.';
      actionLabel = 'Stop Watering Now';
      icon = LucideIcons.power;
      color = Colors.blue[700]!;
      onAction = () {
        backend.closeValve();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drip irrigation stopped.')),
        );
      };
    } else if (t.waterDetected) {
      title = 'Leaves are Wet — Hold Watering 🌧️';
      description = 'Rain or high foliage dew detected. Delay irrigation to prevent Alternaria spore spread.';
      actionLabel = 'View Crop Alerts';
      icon = LucideIcons.cloudRain;
      color = const Color(0xFFD97706);
      onAction = () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdvisoryScreen()),
          );
    } else if (moisture < 40.0) {
      title = 'Soil is Dry (${moisture.toStringAsFixed(0)}%) — Needs Water';
      description = 'Soil moisture is below 40% threshold. Bhagwa Pomegranates need watering up to 70% target.';
      actionLabel = 'Start AI Irrigation';
      icon = LucideIcons.droplets;
      color = const Color(0xFFDC2626);
      onAction = () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const IrrigationScreen()),
          );
    } else if (moisture > 80.0) {
      title = 'Soil Saturated (${moisture.toStringAsFixed(0)}%) 🟢';
      description = 'Moisture is above 80% saturation. Avoid waterlogging and ensure drainage channels are open.';
      actionLabel = 'Inspect Field Map';
      icon = LucideIcons.map;
      color = Colors.blue[800]!;
      onAction = () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FarmMapScreen()),
          );
    } else {
      title = 'Soil Moisture Optimal (${moisture.toStringAsFixed(0)}%) 🌿';
      description = 'Root zone moisture is in the ideal 40%–70% range for pomegranate fruit development.';
      actionLabel = 'Smart Irrigation Hub';
      icon = LucideIcons.checkCircle2;
      color = AppColors.primaryGreen;
      onAction = () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const IrrigationScreen()),
          );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'AI Agronomic Recommendation',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Moisture Level Gauge bar if valid
          if (moisture != null && t.isMoistureValid) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Soil Moisture: ${moisture.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Text(
                  'Optimal Target: 70%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Stack(
              children: [
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                // 40% to 70% optimal zone marker
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.35,
                  right: MediaQuery.of(context).size.width * 0.22,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (moisture / 100.0).clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(isOpen ? LucideIcons.power : LucideIcons.arrowRight, size: 16, color: Colors.white),
              label: Text(
                actionLabel,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 3. ENVIRONMENTAL SENSOR TELEMETRY GRID
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildTelemetryGrid(
    BuildContext context,
    AppLocalizations l10n,
    Esp32Telemetry t,
    Esp32BackendService backend,
  ) {
    final moisture = t.sn3000MoisturePercent;
    final temp = t.dhtTempC;
    final humidity = t.dhtHumidityPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(
              icon: LucideIcons.activity,
              title: 'Live Field Telemetry',
            ),
            GestureDetector(
              onTap: () => Esp32StatusSheet.show(context),
              child: const Text(
                'Sensor Hub',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTelemetryCard(
                icon: LucideIcons.droplets,
                label: 'Soil Moisture',
                value: moisture != null ? '${moisture.toStringAsFixed(0)}%' : '–',
                subtext: moisture != null
                    ? (moisture < 40 ? 'Dry (<40%)' : (moisture > 80 ? 'Saturated' : 'Optimal'))
                    : 'SN-3000 Probe',
                color: moisture != null
                    ? (moisture < 40 ? Colors.red : (moisture > 80 ? Colors.blue : AppColors.primaryGreen))
                    : Colors.grey,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IrrigationScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTelemetryCard(
                icon: LucideIcons.thermometer,
                label: 'Air Temp',
                value: temp != null ? '${temp.toStringAsFixed(1)}°C' : '–',
                subtext: temp != null ? (temp > 35 ? 'Heat Stress' : 'Favorable') : 'DHT22 Sensor',
                color: temp != null ? (temp > 35 ? Colors.orange : Colors.teal) : Colors.grey,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdvisoryScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTelemetryCard(
                icon: LucideIcons.wind,
                label: 'Air Humidity',
                value: humidity != null ? '${humidity.toStringAsFixed(0)}%' : '–',
                subtext: humidity != null && humidity > 85 ? 'Spore Risk High' : 'Normal Vapor',
                color: humidity != null && humidity > 85 ? Colors.purple : Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdvisoryScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTelemetryCard(
                icon: LucideIcons.cloudRain,
                label: 'Rain / Wet Leaf',
                value: t.waterDetected ? 'WET 🌧️' : 'DRY ☀️',
                subtext: t.waterDetected ? 'Valve Interlocked' : 'Safe to Spray',
                color: t.waterDetected ? const Color(0xFFD97706) : AppColors.primaryGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdvisoryScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTelemetryCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtext,
              style: TextStyle(
                color: color.withValues(alpha: 0.85),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 4. FIELD RISK INDICATORS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildRiskSummarySection(BuildContext context, Esp32Telemetry t) {
    final dsvVal = t.safeDsv;
    final tempVal = t.dhtTempC;
    final moistVal = t.sn3000MoisturePercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(
              icon: LucideIcons.shieldAlert,
              title: 'Agronomic Risk Index',
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdvisoryScreen()),
              ),
              child: const Text(
                'Advisory Details',
                style: TextStyle(fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildRiskBadge(
                label: 'Blight Risk',
                severity: dsvVal >= 3.0 ? 'High' : (dsvVal >= 1.5 ? 'Moderate' : 'Low'),
                color: dsvVal >= 3.0 ? Colors.red : (dsvVal >= 1.5 ? Colors.orange : AppColors.primaryGreen),
                icon: LucideIcons.leaf,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRiskBadge(
                label: 'Heat Scorch',
                severity: tempVal == null ? 'Pending' : (tempVal > 38.0 ? 'High' : (tempVal > 33.0 ? 'Medium' : 'Low')),
                color: tempVal == null ? Colors.grey : (tempVal > 38.0 ? Colors.red : (tempVal > 33.0 ? Colors.orange : AppColors.primaryGreen)),
                icon: LucideIcons.flame,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRiskBadge(
                label: 'Water Stress',
                severity: moistVal == null ? 'Pending' : (moistVal < 25.0 ? 'High' : (moistVal < 40.0 ? 'Moderate' : 'Optimal')),
                color: moistVal == null ? Colors.grey : (moistVal < 25.0 ? Colors.red : (moistVal < 40.0 ? Colors.orange : AppColors.primaryGreen)),
                icon: LucideIcons.droplets,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRiskBadge({
    required String label,
    required String severity,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            severity,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 5. CORE SMART FARMING TOOLS (Including Farm Analytics!)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildFarmToolsSection(
    BuildContext context,
    AppLocalizations l10n,
    Esp32BackendService backend,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(icon: LucideIcons.sprout, title: l10n.farmTools),
        const SizedBox(height: 14),

        // Row 1: AI Live Scan + Interactive Irrigation
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                context,
                LucideIcons.camera,
                'AI Crop Scanner',
                'Live Disease & Pest AI',
                const Color(0xFF16A34A),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DiseaseDetectionScreen()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildToolCard(
                context,
                LucideIcons.droplets,
                'Smart Irrigation',
                backend.isValveOpen ? 'Watering Running' : 'AI 70% Target Control',
                const Color(0xFF0284C7),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IrrigationScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Row 2: Farm Map + Farm Analytics (New!)
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                context,
                LucideIcons.map,
                'Farm Map & Zones',
                '6 Orchard Sections',
                const Color(0xFF059669),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FarmMapScreen()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildToolCard(
                context,
                LucideIcons.barChart3,
                'Farm Analytics',
                'Yield Trends & Matrix',
                const Color(0xFF7C3AED),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FarmAnalyticsScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Row 3: Agronomic Advisory + Kharva APMC Mandi
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                context,
                LucideIcons.shieldAlert,
                'Crop Advisory',
                'Pathogen & Spray Alerts',
                const Color(0xFFEA580C),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdvisoryScreen()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildToolCard(
                context,
                Icons.currency_rupee,
                'Pomegranate Mandi',
                'Kharva APMC Rates',
                const Color(0xFF0D9488),
                () => _showMandiPricesSheet(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    IconData icon,
    String label,
    String subtitle,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showMandiPricesSheet(BuildContext context) {
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
              const Row(
                children: [
                  Icon(Icons.currency_rupee, color: AppColors.primaryGreen, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Kharva & Gujarat APMC Rates',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMandiRow('Pomegranate (Bhagwa Grade-A)', '₹120 – ₹145 / kg', 'Stable'),
              _buildMandiRow('Pomegranate (Bhagwa Grade-B)', '₹85 – ₹110 / kg', '+₹5.00'),
              _buildMandiRow('Pomegranate (Arakta Regular)', '₹60 – ₹75 / kg', 'Stable'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMandiRow(String crop, String price, String trend) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              crop,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                trend,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
