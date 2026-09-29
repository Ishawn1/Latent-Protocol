import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/esp32_telemetry.dart';
import '../models/farm_models.dart';
import '../services/esp32_backend_service.dart';
import '../widgets/app_card.dart';
import '../widgets/status_tag.dart';
import '../widgets/esp32_status_sheet.dart';

enum AnalyticsViewTab { trends, alerts }

class FarmAnalyticsScreen extends StatefulWidget {
  final AnalyticsViewTab initialTab;

  const FarmAnalyticsScreen({
    super.key,
    this.initialTab = AnalyticsViewTab.trends,
  });

  @override
  State<FarmAnalyticsScreen> createState() => _FarmAnalyticsScreenState();
}

class _FarmAnalyticsScreenState extends State<FarmAnalyticsScreen> {
  final _backend = Esp32BackendService.instance;
  late AnalyticsViewTab _activeTab;
  String _selectedTimeframe = '7 Days';

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
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
          l10n.farmAnalytics,
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
        child: ListenableBuilder(
          listenable: _backend,
          builder: (context, _) {
            final t = _backend.currentTelemetry;

            return Column(
              children: [
                // Top Segmented Switcher: [ Analytics & Trends ] vs [ Advisories & Alerts ]
                _buildSegmentedSwitcher(),

                // Content Area
                Expanded(
                  child: _activeTab == AnalyticsViewTab.trends
                      ? _buildTrendsView(context, l10n, t)
                      : _buildAlertsView(context, l10n, t),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSegmentedSwitcher() {
    return Container(
      color: AppColors.cardBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                tab: AnalyticsViewTab.trends,
                icon: LucideIcons.lineChart,
                label: 'Performance & Trends',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildTabButton(
                tab: AnalyticsViewTab.alerts,
                icon: LucideIcons.shieldAlert,
                label: 'Advisory & Alerts',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required AnalyticsViewTab tab,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 1. ANALYTICS & TRENDS VIEW (Problem Statement Item 7)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildTrendsView(BuildContext context, AppLocalizations l10n, Esp32Telemetry t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeframe selector bar
          _buildTimeframeBar(),
          const SizedBox(height: 16),

          // Executive Yield Forecast & Risk Header
          _buildYieldForecastCard(),
          const SizedBox(height: 16),

          // AI Agronomic Decision Support
          _buildDecisionSupportCard(),
          const SizedBox(height: 16),

          // Historical Soil Moisture Trend Chart
          _buildSoilMoistureTrendCard(t),
          const SizedBox(height: 16),

          // Temperature & Climate Trend Card
          _buildClimateTrendCard(t),
          const SizedBox(height: 16),

          // Water Conservation & Irrigation Impact
          _buildWaterConservationCard(),
          const SizedBox(height: 16),

          // Field-Level Section Performance Matrix (All 6 Zones)
          _buildSectionPerformanceMatrix(),
          const SizedBox(height: 16),

          // Pest & Disease Scouting Analytics
          _buildDiseaseScoutingAnalytics(),
        ],
      ),
    );
  }

  Widget _buildTimeframeBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bhagwa Orchard Analytics',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '3.5 Acres • Kharva, Gujarat Block 1',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        Row(
          children: ['7 Days', '30 Days', 'Season'].map((tf) {
            final isSel = _selectedTimeframe == tf;
            return GestureDetector(
              onTap: () => setState(() => _selectedTimeframe = tf),
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primaryGreen : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSel ? AppColors.primaryGreen : AppColors.borderLight,
                  ),
                ),
                child: Text(
                  tf,
                  style: TextStyle(
                    color: isSel ? Colors.white : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildYieldForecastCard() {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.trendingUp, color: AppColors.primaryGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Yield-Risk Forecast',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              StatusTag(
                label: 'Edge AI Projected',
                backgroundColor: AppColors.accentGreen.withValues(alpha: 0.15),
                textColor: AppColors.primaryGreen,
                fontSize: 11,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Projected Harvest',
                  value: '14.8 T/Ac',
                  subtext: '+12% vs Regional Avg',
                  subtextColor: AppColors.accentGreen,
                  icon: LucideIcons.sprout,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Yield Risk Index',
                  value: '8% Low',
                  subtext: 'Minimal Climate Risk',
                  subtextColor: AppColors.accentGreen,
                  icon: LucideIcons.shieldCheck,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Canopy Health (NDVI)',
                  value: '0.78',
                  subtext: 'High Crop Vigour',
                  subtextColor: AppColors.primaryGreen,
                  icon: LucideIcons.leaf,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Irrigation Efficiency',
                  value: '94%',
                  subtext: '70% Target Adherence',
                  subtextColor: Colors.blue[700]!,
                  icon: LucideIcons.droplets,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtext,
    required Color subtextColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              color: subtextColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionSupportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.sparkles, color: AppColors.primaryGreen, size: 18),
              SizedBox(width: 8),
              Text(
                'AI Decision-Support Insights',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            icon: LucideIcons.droplets,
            color: Colors.blue[700]!,
            title: 'Water Management',
            description:
                'Smart drip regulation kept root zones within 68–72% moisture this week, eliminating water stress across 85% of trees.',
          ),
          const SizedBox(height: 10),
          _buildInsightRow(
            icon: LucideIcons.bug,
            color: AppColors.accentOrange,
            title: 'Pest Alert (Section B1)',
            description:
                'Low-level aphid presence detected. Recommend early evening 2% Neem oil spray before colonies expand to Section B2.',
          ),
          const SizedBox(height: 10),
          _buildInsightRow(
            icon: LucideIcons.sun,
            color: const Color(0xFFD97706),
            title: 'Heat Stress Advisory',
            description:
                'Temperatures forecast to reach 34°C on Thursday. Drip pulse at 06:30 AM will buffer fruit rind against sun scald.',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSoilMoistureTrendCard(Esp32Telemetry t) {
    // 7-day demo moisture trend with 70% target marker
    final List<Map<String, dynamic>> dailyMoisture = [
      {'day': 'Mon', 'val': 42.0},
      {'day': 'Tue', 'val': 38.0},
      {'day': 'Wed', 'val': 70.0},
      {'day': 'Thu', 'val': 68.0},
      {'day': 'Fri', 'val': 54.0},
      {'day': 'Sat', 'val': 46.0},
      {'day': 'Sun', 'val': 69.0},
    ];

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.droplet, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '7-Day Soil Moisture Trend',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '🎯 Target: 70%',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Target 70% provides optimal cell expansion during pomegranate fruit development.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 18),

          // Visual Bar Chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: dailyMoisture.map((entry) {
              final val = entry['val'] as double;
              final isTargetMet = val >= 65.0 && val <= 75.0;
              final isDry = val < 40.0;
              final barColor = isTargetMet
                  ? AppColors.primaryGreen
                  : (isDry ? Colors.redAccent : Colors.blue[400]!);

              return Column(
                children: [
                  Text(
                    '${val.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: barColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 28,
                    height: (val * 1.0).clamp(15.0, 85.0),
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry['day'] as String,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendBullet(Colors.redAccent, 'Stress (<40%)'),
              _buildLegendBullet(AppColors.primaryGreen, 'Optimal Target (70%)'),
              _buildLegendBullet(Colors.blue[400]!, 'Good (>50%)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClimateTrendCard(Esp32Telemetry t) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.thermometerSun, color: AppColors.accentOrange, size: 18),
              SizedBox(width: 8),
              Text(
                'Microclimate & Thermal Comfort',
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
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Avg Temperature',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.dhtTempC != null ? '${t.dhtTempC!.toStringAsFixed(1)} °C' : '29.2 °C',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Safe: Max 36°C Limit',
                        style: TextStyle(color: AppColors.primaryGreen, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Relative Humidity',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.dhtHumidityPercent != null
                            ? '${t.dhtHumidityPercent!.toStringAsFixed(0)}%'
                            : '52%',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Low Fungal Risk (<70%)',
                        style: TextStyle(color: AppColors.primaryGreen, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterConservationCard() {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.leaf, color: AppColors.primaryGreen, size: 18),
              SizedBox(width: 8),
              Text(
                'Water Conservation Impact',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Water Applied',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 2),
                    const Text('18,400 L',
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Precision Drip Emitters',
                        style: TextStyle(color: Colors.blue[700], fontSize: 10)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.borderLight),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Water Saved vs Flood',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    SizedBox(height: 2),
                    Text('6,200 L',
                        style: TextStyle(
                            color: AppColors.primaryGreen, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('34% Conservation Gain',
                        style: TextStyle(color: AppColors.primaryGreen, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionPerformanceMatrix() {
    final zones = Plot.demoOrchard.zones;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.grid, color: AppColors.primaryGreen, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Field-Level Section Matrix',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '6 Sections',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: zones.map((zone) {
              final isWarning = zone.status == ZoneHealthStatus.diseaseWarning ||
                  zone.status == ZoneHealthStatus.stress;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: zone.statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: zone.statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        zone.id,
                        style: TextStyle(
                          color: zone.statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            zone.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            zone.activeConcern ?? 'Optimal Growth Conditions',
                            style: TextStyle(
                              color: isWarning ? zone.statusColor : AppColors.textSecondary,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${zone.soilMoisturePercent.toStringAsFixed(0)}% Moist',
                          style: TextStyle(
                            color: zone.soilMoisturePercent < 35
                                ? Colors.redAccent
                                : AppColors.primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          zone.statusLabel,
                          style: TextStyle(
                            color: zone.statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseScoutingAnalytics() {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.camera, color: AppColors.primaryGreen, size: 18),
              SizedBox(width: 8),
              Text(
                'Vision AI Scouting Summary',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Scans Logged',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    SizedBox(height: 2),
                    Text('48 Scans',
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Healthy Proportion',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    SizedBox(height: 2),
                    Text('75% Healthy',
                        style: TextStyle(
                            color: AppColors.primaryGreen, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Active Disease Detections: 15% Alternaria Leaf Spot • 10% Aphids',
            style: TextStyle(
              color: AppColors.accentOrange,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBullet(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 2. ADVISORY & ALERTS VIEW
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildAlertsView(BuildContext context, AppLocalizations l10n, Esp32Telemetry t) {
    final alerts = _generateDynamicAlerts(context, t);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Real-time hardware health badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _backend.isRealHardwareStreaming
                ? AppColors.primaryGreen.withValues(alpha: 0.1)
                : AppColors.accentOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _backend.isRealHardwareStreaming
                  ? AppColors.primaryGreen.withValues(alpha: 0.3)
                  : AppColors.accentOrange.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _backend.isRealHardwareStreaming ? LucideIcons.radio : LucideIcons.alertTriangle,
                size: 16,
                color: _backend.isRealHardwareStreaming ? AppColors.primaryGreen : AppColors.accentOrange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _backend.isRealHardwareStreaming
                      ? 'Live Sentinel Telemetry Stream Active (Node 1)'
                      : 'Sentinel Node Standby — Monitoring Thresholds',
                  style: TextStyle(
                    color: _backend.isRealHardwareStreaming
                        ? AppColors.primaryGreen
                        : AppColors.accentOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List of Alerts
        ...alerts.map((alert) => _buildAlertCard(context, alert)),
      ],
    );
  }

  Widget _buildAlertCard(BuildContext context, _AlertData alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: alert.borderColor),
        boxShadow: [
          BoxShadow(
            color: alert.borderColor.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: alert.badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(alert.icon, color: alert.badgeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.time,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              StatusTag(
                label: alert.severityLabel,
                backgroundColor: alert.badgeColor.withValues(alpha: 0.15),
                textColor: alert.badgeColor,
                fontSize: 10,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert.description,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.checkCircle2, color: alert.badgeColor, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.recommendation,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  List<_AlertData> _generateDynamicAlerts(BuildContext context, Esp32Telemetry t) {
    final List<_AlertData> list = [];

    // Wet Leaf / Pathogen alert
    if (t.waterDetected) {
      list.add(
        _AlertData(
          icon: LucideIcons.cloudRain,
          badgeColor: AppColors.lossText,
          borderColor: AppColors.lossBorder,
          title: 'High Pathogen Warning: Foliage Wet',
          time: 'Active Now',
          severityLabel: 'CRITICAL',
          description:
              'Water detected on leaf surfaces. Wet foliage at current temperatures accelerates Cercospora and Alternaria fungal spore germination.',
          recommendation:
              'Postpone all overhead irrigation. Inspect bottom leaves for brown necrotic spots.',
        ),
      );
    }

    // Soil Moisture Low
    final moisture = t.sn3000MoisturePercent ?? 27.0;
    if (moisture < 40.0) {
      list.add(
        _AlertData(
          icon: LucideIcons.droplets,
          badgeColor: AppColors.accentOrange,
          borderColor: AppColors.urgentBorder,
          title: 'Root-Zone Moisture Deficit (${moisture.toStringAsFixed(0)}%)',
          time: 'Recorded 15m ago',
          severityLabel: 'ATTENTION',
          description:
              'Soil moisture is at ${moisture.toStringAsFixed(0)}%, well below the 40% minimum threshold. Bhagwa fruit sizing requires steady moisture.',
          recommendation:
              'Run AI Smart Irrigation cycle (~35 min) to restore optimal 70% moisture.',
        ),
      );
    }

    // Disease Warning from Section B1
    list.add(
      _AlertData(
        icon: LucideIcons.alertTriangle,
        badgeColor: AppColors.accentOrange,
        borderColor: AppColors.borderLight,
        title: 'Section B1: Alternaria Symptoms Logged',
        time: 'Today 09:15 AM',
        severityLabel: 'WARNING',
        description:
            'Optical scout in Section B1 flagged dark brown spots with yellow halos on 25% of sampled pomegranate leaves.',
        recommendation:
            'Spray Mancozeb (0.25%) or Copper Oxychloride (0.3%). Maintain canopy aeration.',
      ),
    );

    // Weather Forecast Advisory
    list.add(
      _AlertData(
        icon: LucideIcons.sun,
        badgeColor: AppColors.primaryGreen,
        borderColor: AppColors.borderGreen,
        title: 'Optimal Spray Window Available',
        time: 'Tomorrow 06:00 AM',
        severityLabel: 'ADVISORY',
        description:
            'Wind speeds below 6 km/h and clear skies provide an ideal window for foliar nutrient and biological sprays.',
        recommendation:
            'Apply prophylactic Trichoderma viride or micronutrient spray before temperatures exceed 30°C.',
      ),
    );

    return list;
  }
}

class _AlertData {
  final IconData icon;
  final Color badgeColor;
  final Color borderColor;
  final String title;
  final String time;
  final String severityLabel;
  final String description;
  final String recommendation;

  const _AlertData({
    required this.icon,
    required this.badgeColor,
    required this.borderColor,
    required this.title,
    required this.time,
    required this.severityLabel,
    required this.description,
    required this.recommendation,
  });
}
