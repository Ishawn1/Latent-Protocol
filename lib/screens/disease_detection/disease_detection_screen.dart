import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_header.dart';
import 'camera_detection_screen.dart';
import 'live_detection_screen.dart';


class DiseaseDetectionScreen extends StatelessWidget {
  const DiseaseDetectionScreen({super.key});

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
          l10n.diseaseDetection,
          style: const TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.borderLight,
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            _buildHeaderInfo(l10n),
            const SizedBox(height: 24),

            // Detection Options
            _buildDetectionOptions(context, l10n),
            const SizedBox(height: 24),

            // How it works section
            _buildHowItWorks(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.accentGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.aiPoweredDetection,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.aiDetectionDesc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              LucideIcons.scan,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionOptions(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: LucideIcons.settings,
          title: l10n.chooseDetectionMethod,
        ),
        const SizedBox(height: 16),
        // Live Scan — real-time YOLO detection with Smart Capture
        SizedBox(
          width: double.infinity,
          child: _buildOptionCard(
            context: context,
            icon: LucideIcons.scan,
            title: 'Live Scan',
            description: 'Real-time AI detection with Smart Capture',
            color: AppColors.accentGreen,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LiveDetectionScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Take Photo — original gallery/camera flow
        SizedBox(
          width: double.infinity,
          child: _buildOptionCard(
            context: context,
            icon: LucideIcons.camera,
            title: l10n.takePhoto,
            description: l10n.takePhotoDesc,
            color: AppColors.accentOrange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CameraDetectionScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(icon: LucideIcons.helpCircle, title: l10n.howItWorks),
        const SizedBox(height: 16),
        _buildStepItem(
          number: '1',
          title: l10n.captureImage,
          description: l10n.captureImageDesc,
          icon: LucideIcons.camera,
        ),
        const SizedBox(height: 12),
        _buildStepItem(
          number: '2',
          title: l10n.aiAnalysis,
          description: l10n.aiAnalysisDesc,
          icon: LucideIcons.brain,
        ),
        const SizedBox(height: 12),
        _buildStepItem(
          number: '3',
          title: l10n.getResults,
          description: l10n.getResultsDesc,
          icon: LucideIcons.clipboardCheck,
        ),
      ],
    );
  }

  Widget _buildStepItem({
    required String number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return AppCard(
      borderRadius: 12,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            icon,
            color: AppColors.primaryGreen.withValues(alpha: 0.5),
            size: 24,
          ),
        ],
      ),
    );
  }
}
