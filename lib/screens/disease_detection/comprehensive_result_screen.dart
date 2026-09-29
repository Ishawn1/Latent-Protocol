import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/detection_models.dart';
import '../../models/disease_models.dart';
import '../../models/pest_models.dart';
import '../../models/growth_models.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_header.dart';

/// Full 360-degree crop health result screen combining Disease + Pest + Growth.
class ComprehensiveResultScreen extends StatelessWidget {
  final String imagePath;

  /// Primary disease dossier (null = no disease or model unavailable).
  final DiseaseResult? diseaseResult;

  /// All pest detections passing the confidence threshold.
  final List<DetectedObject> pestDetections;

  /// All growth stage detections passing the confidence threshold.
  final List<DetectedObject> growthDetections;

  const ComprehensiveResultScreen({
    super.key,
    required this.imagePath,
    required this.diseaseResult,
    required this.pestDetections,
    required this.growthDetections,
  });

  // ── helpers ─────────────────────────────────────────────────────────

  /// Best-confidence pest detection (null if none found).
  DetectedObject? get _bestPest => pestDetections.isEmpty
      ? null
      : pestDetections.reduce((a, b) => a.confidence > b.confidence ? a : b);

  /// Best-confidence growth detection (null if none found).
  DetectedObject? get _bestGrowth => growthDetections.isEmpty
      ? null
      : growthDetections.reduce((a, b) => a.confidence > b.confidence ? a : b);

  PestResult? get _pestResult => _bestPest == null
      ? null
      : PestResult.fromDetection(_bestPest!.classIndex, _bestPest!.confidence);

  GrowthStageResult? get _growthResult => _bestGrowth == null
      ? null
      : GrowthStageResult.fromDetection(_bestGrowth!.classIndex, _bestGrowth!.confidence);

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

  // ── build ────────────────────────────────────────────────────────────

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
        title: const Text(
          '360° Crop Diagnosis',
          style: TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
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
            // ── Image header ─────────────────────────────────────────
            _buildImageHeader(),
            const SizedBox(height: 20),

            // ── Disease section ──────────────────────────────────────
            _buildDiseaseSection(l10n),
            const SizedBox(height: 16),

            // ── Pest section ─────────────────────────────────────────
            _buildPestSection(),
            const SizedBox(height: 16),

            // ── Growth stage section ─────────────────────────────────
            _buildGrowthSection(),
            const SizedBox(height: 16),

            // ── Integrated IPM advisory ──────────────────────────────
            _buildIpmAdvisory(),
            const SizedBox(height: 24),

            // ── Actions ──────────────────────────────────────────────
            _buildActions(context, l10n),
          ],
        ),
      ),
    );
  }

  // ── Image header ──────────────────────────────────────────────────────

  Widget _buildImageHeader() {
    final disease = diseaseResult;
    final pest = _pestResult;
    final growth = _growthResult;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
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
              errorBuilder: (_, __, ___) => Container(
                width: double.infinity,
                height: 200,
                color: AppColors.cardBackground,
                child: const Center(
                  child: Icon(LucideIcons.image, size: 60, color: AppColors.textSecondary),
                ),
              ),
            ),
            // Tag strip at top-right
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (disease != null)
                    _buildTag(
                      disease.isHealthy ? '✅ Healthy' : '🌿 ${disease.nameKey}',
                      disease.isHealthy ? AppColors.accentGreen : AppColors.lossText,
                    ),
                  if (pest != null) ...[
                    const SizedBox(height: 6),
                    _buildTag('🐛 ${pest.pest.displayName}', AppColors.accentOrange),
                  ],
                  if (growth != null) ...[
                    const SizedBox(height: 6),
                    _buildTag('🍎 ${growth.stage.displayName}', AppColors.waterPumpButton),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ── Disease section ───────────────────────────────────────────────────

  Widget _buildDiseaseSection(AppLocalizations l10n) {
    final disease = diseaseResult;
    if (disease == null) {
      return _buildUnavailableCard('Disease', 'Disease model unavailable for this scan.', LucideIcons.bug);
    }

    final statusColor = disease.isHealthy ? AppColors.accentGreen : AppColors.lossText;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: disease.isHealthy ? LucideIcons.shieldCheck : LucideIcons.bug,
            title: '🌿 Disease Analysis',
            fontSize: 16,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(disease.isHealthy ? LucideIcons.shieldCheck : LucideIcons.alertTriangle,
                    color: statusColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disease.nameKey,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      disease.scientificNameKey,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              _buildStatPill('${disease.confidencePercent.toStringAsFixed(0)}%', 'Conf.', statusColor),
            ],
          ),
          if (disease.isDiseased) ...[
            const SizedBox(height: 12),
            Text(
              disease.descriptionKey,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 12),
            ...disease.treatments.map((t) => _buildTreatmentRow(t.nameKey, t.descriptionKey, t.iconName)),
          ],
        ],
      ),
    );
  }

  // ── Pest section ──────────────────────────────────────────────────────

  Widget _buildPestSection() {
    final pest = _pestResult;
    if (pest == null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(icon: LucideIcons.bug, title: '🐛 Pest Analysis', fontSize: 16),
            const SizedBox(height: 14),
            Row(
              children: const [
                Icon(LucideIcons.checkCircle, color: AppColors.accentGreen, size: 20),
                SizedBox(width: 10),
                Text('No insect pests detected above threshold.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(icon: LucideIcons.bug, title: '🐛 Pest Detected', fontSize: 16),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.bug, color: AppColors.accentOrange, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pest.pest.displayName,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                    Text('Confidence: ${pest.confidencePercent.toStringAsFixed(0)}%',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(pest.description,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 12),
          if (pest.damageSigns.isNotEmpty) ...[
            const Text('Damage Signs',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...pest.damageSigns.map((s) => _buildBulletItem(s, AppColors.accentOrange)),
            const SizedBox(height: 10),
          ],
          const Text('Organic Controls',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...pest.organicControls.map((t) => _buildTreatmentRow(t.name, t.description, t.iconName)),
          const SizedBox(height: 8),
          const Text('Chemical Controls',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...pest.chemicalControls.map((t) => _buildTreatmentRow(t.name, t.description, t.iconName)),
          if (pest.ipmNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('IPM Notes',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...pest.ipmNotes.map((n) => _buildBulletItem(n, AppColors.waterPumpButton)),
          ],
        ],
      ),
    );
  }

  // ── Growth stage section ──────────────────────────────────────────────

  Widget _buildGrowthSection() {
    final growth = _growthResult;
    if (growth == null) {
      return _buildUnavailableCard('Growth Stage', 'No growth stage identified in this image.', LucideIcons.sprout);
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(icon: LucideIcons.sprout, title: '🍎 Growth Stage', fontSize: 16),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.waterPumpButton.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.sprout, color: AppColors.waterPumpButton, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(growth.stage.displayName,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                    Text('≈ ${growth.estimatedDaysToHarvest} days to harvest',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              _buildStatPill('${growth.confidencePercent.toStringAsFixed(0)}%', 'Conf.',
                  AppColors.waterPumpButton),
            ],
          ),
          const SizedBox(height: 12),
          Text(growth.phenologyNote,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 12),
          _buildAdvisoryChip(LucideIcons.droplets, 'Irrigation', growth.irrigationAdvisory, AppColors.waterPumpButton),
          const SizedBox(height: 8),
          _buildAdvisoryChip(LucideIcons.leaf, 'Nutrition', growth.nutrientAdvisory, AppColors.accentGreen),
          const SizedBox(height: 8),
          _buildAdvisoryChip(LucideIcons.alertTriangle, 'Spray Caution', growth.sprayCaution,
              growth.stage.isSpraySensitive ? AppColors.lossText : AppColors.accentOrange),
        ],
      ),
    );
  }

  // ── IPM Advisory ──────────────────────────────────────────────────────

  Widget _buildIpmAdvisory() {
    final pest = _pestResult;
    final growth = _growthResult;

    // Generate cross-model advisory only when both pest and growth are available
    if (pest == null && growth == null) return const SizedBox.shrink();

    final List<String> advisories = [];

    if (pest != null && growth != null) {
      // Cross-reference: pest type × growth stage
      if (growth.stage.isSpraySensitive && pest.pest == PestClass.thrips) {
        advisories.add(
            '⚠️ Thrips detected during ${growth.stage.displayName}: Spray Spinetoram ONLY after 6 PM. '
            'Morning sprays will kill honeybees essential for fruit set.');
      } else if (growth.stage == GrowthStageClass.mature) {
        advisories.add(
            '🚫 ${pest.pest.displayName} detected but crop is at Harvest Maturity. '
            'DO NOT apply chemical pesticides — pre-harvest interval has not elapsed. '
            'Use only physical removal or biological agents.');
      } else if (growth.stage == GrowthStageClass.flower) {
        advisories.add(
            '⚠️ ${pest.pest.displayName} detected during Flowering stage. '
            'Apply pesticides only after 5 PM to protect honeybee pollinators. '
            'Prefer Bt-based bio-agents over synthetic insecticides.');
      } else {
        advisories.add(
            'Treat ${pest.pest.displayName} promptly. '
            'Current growth stage (${growth.stage.displayName}) is safe for standard IPM protocols.');
      }
    }

    if (pest != null && pest.pest == PestClass.thrips) {
      advisories.add('Monitor sticky trap counts weekly — thrips populations can triple in 5 days under heat stress.');
    }

    if (growth != null && growth.stage == GrowthStageClass.midGrowth) {
      advisories.add('Maintain consistent soil moisture now — any wet-dry cycle variation >15% causes fruit cracking.');
    }

    if (advisories.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: LucideIcons.flaskConical,
            title: 'Integrated IPM Advisory',
            fontSize: 16,
          ),
          const SizedBox(height: 14),
          ...advisories.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.alertCircle, color: AppColors.accentOrange, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(a,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            icon: const Icon(LucideIcons.home, size: 20),
            label: Text(l10n.backToHome),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.scan, size: 20),
            label: Text(l10n.scanAnother),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared sub-widgets ────────────────────────────────────────────────

  Widget _buildTreatmentRow(String name, String desc, String iconName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.farmHealthBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGreen),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_treatmentIcon(iconName), color: AppColors.accentGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(desc,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisoryChip(IconData icon, String label, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(text,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildUnavailableCard(String title, String message, IconData icon) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(message,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
