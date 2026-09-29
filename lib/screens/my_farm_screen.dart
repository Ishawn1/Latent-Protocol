import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/farm_models.dart';
import '../services/esp32_backend_service.dart';
import '../widgets/app_card.dart';
import '../widgets/status_tag.dart';

class MyFarmScreen extends StatelessWidget {
  const MyFarmScreen({super.key});

  // Demo plot data — aligned to Pomegranate orchard
  static const _demoPlot = Plot.demoOrchard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final backend = Esp32BackendService.instance;

    return ListenableBuilder(
      listenable: backend,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Add Plot Button
              _buildHeader(context, l10n),
              const SizedBox(height: 20),

              // Summary Stats
              _buildSummaryStats(l10n),
              const SizedBox(height: 20),

              // Water Pump Control
              _buildWaterPumpControl(context, l10n, backend),
              const SizedBox(height: 20),

              // Plot Details Card
              _buildPlotDetailsCard(context, l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.myFarm,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.farmOverview,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => showComingSoon(context),
          icon: const Icon(LucideIcons.plus, size: 16),
          label: Text(l10n.addPlot),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStats(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: AppCard(
            child: Column(
              children: [
                const Text(
                  '3.7',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.totalArea} (${l10n.acres})',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppCard(
            child: Column(
              children: [
                const Text(
                  '2',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.yourPlots,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaterPumpControl(
    BuildContext context,
    AppLocalizations l10n,
    Esp32BackendService backend,
  ) {
    final isOpen = backend.isValveOpen;
    final remaining = backend.remainingValveSeconds;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOpen ? Colors.blue.withValues(alpha: 0.06) : AppColors.waterPumpBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen ? Colors.blue : AppColors.borderBlue.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
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
              Row(
                children: [
                  Icon(
                    LucideIcons.zap,
                    size: 18,
                    color: isOpen ? Colors.blue[600] : Colors.blue[400],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.solenoidValve,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              StatusTag(
                label: isOpen ? 'OPEN (${remaining ~/ 60}m ${remaining % 60}s)' : 'CLOSED',
                backgroundColor: isOpen ? Colors.blue.withValues(alpha: 0.15) : const Color(0xFFE5E7EB),
                textColor: isOpen ? Colors.blue[800]! : AppColors.textSecondary,
                fontSize: 10,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isOpen
                ? 'Valve active on ESP32-S3. Failsafe timer will auto-shutoff to prevent flooding.'
                : l10n.autoTriggerDesc,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPumpCard(
                  context,
                  l10n.northField,
                  l10n,
                  backend,
                  isControllable: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPumpCard(
                  context,
                  l10n.southPlot,
                  l10n,
                  backend,
                  isControllable: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.borderBlue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.waterUsage} (Flow Rate):',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  isOpen ? 'Valve Open (${remaining}s left)' : '0 L/min (Idle)',
                  style: TextStyle(
                    color: isOpen ? Colors.blue[700] : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPumpCard(
    BuildContext context,
    String fieldName,
    AppLocalizations l10n,
    Esp32BackendService backend, {
    required bool isControllable,
  }) {
    final isOpen = isControllable && backend.isValveOpen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                fieldName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            StatusTag(
              label: isOpen ? 'Active' : l10n.pumpOff,
              backgroundColor: isOpen ? Colors.blue.withValues(alpha: 0.15) : const Color(0xFFE5E7EB),
              textColor: isOpen ? Colors.blue[800]! : AppColors.textSecondary,
              fontSize: 11,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              if (!isControllable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Zone 2 valve is on secondary expansion board.'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              if (isOpen) {
                backend.closeValve();
              } else {
                backend.openValve(durationMinutes: 30);
              }
            },
            icon: Icon(LucideIcons.power, size: 16, color: Colors.white),
            label: Text(isOpen ? 'Close Valve' : l10n.openValve),
            style: ElevatedButton.styleFrom(
              backgroundColor: isOpen ? Colors.redAccent : AppColors.waterPumpButton,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlotDetailsCard(BuildContext context, AppLocalizations l10n) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.northField,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              StatusTag(
                label: l10n.healthy,
                backgroundColor: AppColors.farmHealthTagBg,
                textColor: AppColors.farmHealthTagText,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow('${l10n.crops}:', l10n.wheat),
          const SizedBox(height: 12),
          _buildDetailRow(
              '${l10n.totalArea}:', '${_demoPlot.areaAcres} ${l10n.acres}'),
          const SizedBox(height: 12),
          _buildDetailRow('${l10n.planted}:', _demoPlot.plantedDate),
          const SizedBox(height: 12),
          _buildDetailRow(
            '${l10n.harvestIn}:',
            '${_demoPlot.harvestDaysRemaining} ${l10n.days}',
            isHighlight: true,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.droplets,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${l10n.irrigation}:',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                _demoPlot.lastIrrigation ?? '-',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showComingSoon(context),
                  icon: const Icon(LucideIcons.activity, size: 16),
                  label: Text(l10n.viewDetails),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showComingSoon(context),
                  icon: const Icon(LucideIcons.settings, size: 16),
                  label: Text(l10n.settings),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? AppColors.accentOrange : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
