import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/disease_models.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_header.dart';

class AnalysisResultScreen extends StatelessWidget {
  final String imagePath;
  final String sourceType;
  final DiseaseResult result;

  const AnalysisResultScreen({
    super.key,
    required this.imagePath,
    required this.sourceType,
    required this.result,
  });

  DiseaseResult get _result => result;

  IconData _treatmentIcon(String iconName) {
    switch (iconName) {
      case 'science':
        return Icons.science_outlined;
      case 'scissors':
        return LucideIcons.scissors;
      case 'wind':
        return LucideIcons.wind;
      case 'droplets':
        return LucideIcons.droplets;
      default:
        return LucideIcons.leaf;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Text(
          l10n.analysisResult,
          style: const TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.reportSaved),
                  backgroundColor: AppColors.accentGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            icon: const Icon(LucideIcons.download,
                color: AppColors.textPrimary),
            tooltip: 'Save Report',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderLight, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and Detection Result
            _buildImageSection(l10n),
            const SizedBox(height: 20),

            // Disease Info Card
            _buildDiseaseInfoCard(l10n),
            const SizedBox(height: 20),

            // Symptoms Section
            _buildSymptomsSection(l10n),
            const SizedBox(height: 20),

            // Treatment Section
            _buildTreatmentSection(l10n),
            const SizedBox(height: 20),

            // Prevention Tips
            _buildPreventionSection(l10n),
            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.file(
              File(imagePath),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  color: AppColors.cardBackground,
                  child: const Center(
                    child: Icon(
                      LucideIcons.image,
                      size: 60,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _result.isHealthy
                      ? AppColors.accentGreen
                      : AppColors.lossText,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _result.isHealthy
                          ? LucideIcons.checkCircle
                          : LucideIcons.alertTriangle,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _result.isHealthy
                          ? l10n.healthy
                          : l10n.diseaseDetected,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sourceType == 'drone'
                          ? LucideIcons.plane
                          : LucideIcons.camera,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sourceType == 'drone'
                          ? l10n.droneImage
                          : l10n.cameraPhoto,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseInfoCard(AppLocalizations l10n) {
    final statusColor = _result.isHealthy ? AppColors.accentGreen : AppColors.lossText;
    final statusIcon = _result.isHealthy ? LucideIcons.shieldCheck : LucideIcons.bug;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate(_result.nameKey),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.translate(_result.scientificNameKey),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatChip(
                label: l10n.confidence,
                value: '${_result.confidencePercent.toStringAsFixed(1)}%',
                color: AppColors.accentGreen,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                label: l10n.severity,
                value: _result.isHealthy
                    ? l10n.good
                    : l10n.translate(_result.severityKey),
                color: _result.isHealthy
                    ? AppColors.accentGreen
                    : AppColors.accentOrange,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                label: l10n.affected,
                value: '${_result.affectedPercent}%',
                color: _result.isHealthy
                    ? AppColors.accentGreen
                    : AppColors.lossText,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.translate(_result.descriptionKey),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsSection(AppLocalizations l10n) {
    if (_result.symptomKeys.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildSection(
      title: _result.isHealthy ? 'Observations' : l10n.symptoms,
      icon: _result.isHealthy ? LucideIcons.checkCircle : LucideIcons.alertCircle,
      child: Column(
        children: _result.symptomKeys
            .map((key) => _buildListItem(
                l10n.translate(key),
                _result.isHealthy ? AppColors.accentGreen : AppColors.lossText))
            .toList(),
      ),
    );
  }

  Widget _buildTreatmentSection(AppLocalizations l10n) {
    return _buildSection(
      title: l10n.recommendedTreatment,
      icon: LucideIcons.stethoscope,
      child: Column(
        children: _result.treatments.map((treatment) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.farmHealthBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGreen),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _treatmentIcon(treatment.iconName),
                    color: AppColors.accentGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate(treatment.nameKey),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.translate(treatment.descriptionKey),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreventionSection(AppLocalizations l10n) {
    return _buildSection(
      title: l10n.preventionTips,
      icon: LucideIcons.shield,
      child: Column(
        children: _result.preventionKeys
            .map((key) => _buildListItem(
                l10n.translate(key), AppColors.waterPumpButton))
            .toList(),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(icon: icon, title: title, fontSize: 16),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildListItem(String text, Color bulletColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: bulletColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: const Icon(LucideIcons.home, size: 20),
            label: Text(l10n.backToHome),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(LucideIcons.scan, size: 20),
            label: Text(l10n.scanAnother),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
