import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import '../../models/ai_model_registry.dart';
import '../../models/detection_models.dart';
import '../../models/disease_models.dart';
import '../../models/pest_models.dart';
import '../../models/growth_models.dart';
import '../../theme/app_theme.dart';

/// Full-screen live camera detection powered by the official ultralytics_yolo
/// plugin. The native Kotlin side handles the full pipeline:
///   Camera → resize → Float32 → TFLite inference → overlay rendering
///
/// Dart only receives a [List<DetectionResult>] per frame via [onResult].
class LiveDetectionScreen extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onBackToHome;

  const LiveDetectionScreen({
    super.key,
    this.isActive = true,
    this.onBackToHome,
  });

  @override
  State<LiveDetectionScreen> createState() => _LiveDetectionScreenState();
}

class _LiveDetectionScreenState extends State<LiveDetectionScreen> {
  // ── Active lens state ────────────────────────────────────────────────
  DetectionLens _activeLens = DetectionLens.disease;

  /// Tracks which lens model is actually confirmed loaded in the native layer.
  DetectionLens _loadedLens = DetectionLens.disease;

  /// Blocks re-entrancy during lens transitions.
  bool _isSwitchingLens = false;

  /// Safety watchdog timer to prevent UI lockup if native callback drops.
  Timer? _switchTimeoutTimer;
  bool _isDetailSheetOpen = false;

  final _controller = YOLOViewController();

  // ValueNotifier for scoped bottom bar updates (eliminates screen-wide rebuilds)
  late final ValueNotifier<List<DetectedObject>> _detectionsNotifier =
      ValueNotifier<List<DetectedObject>>([]);

  DateTime _lastUiUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const _minUiUpdateInterval =
      Duration(milliseconds: 100); // 10 Hz UI refresh cap

  AiModelConfig get _activeLensConfig => ModelRegistry.configFor(_activeLens);

  String get _activeModelAsset => _activeLensConfig.assetPath;

  Color get _lensAccent {
    switch (_activeLens) {
      case DetectionLens.disease:
        return AppColors.lossText;
      case DetectionLens.pest:
        return AppColors.accentOrange;
      case DetectionLens.growth:
        return AppColors.waterPumpButton;
    }
  }

  // ── Lens switching (in-place native swap) ─────────────────────────────

  Future<void> _switchLens(DetectionLens lens) async {
    if (lens == _activeLens || _isSwitchingLens) return;

    _switchTimeoutTimer?.cancel();

    setState(() {
      _isSwitchingLens = true;
      _activeLens = lens;
      _detectionsNotifier.value = []; // clear stale detections immediately
    });

    // Proactively apply lens confidence threshold to native layer
    _controller
        .setConfidenceThreshold(_activeLensConfig.defaultLiveConfidence)
        .catchError((_) {});

    // Safety timeout: if native onModelLoad or onModelError is never invoked,
    // unlock UI and rollback to currently confirmed loaded lens.
    _switchTimeoutTimer = Timer(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      if (_isSwitchingLens) {
        setState(() {
          _isSwitchingLens = false;
          _activeLens = _loadedLens;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lens switch timed out. Reverted to previous lens.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void didUpdateWidget(LiveDetectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive && !_isDetailSheetOpen) {
        _controller.resume();
      } else {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _switchTimeoutTimer?.cancel();
    _detectionsNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════
  //  DETECTION CALLBACK
  // ══════════════════════════════════════════════════════════════════

  void _onResult(List<YOLOResult> rawResults) {
    if (!mounted || !widget.isActive || _isDetailSheetOpen) return;

    final now = DateTime.now();
    if (now.difference(_lastUiUpdateTime) < _minUiUpdateInterval) {
      return; // Drop intermediate frame to prevent UI thread saturation
    }
    _lastUiUpdateTime = now;

    final currentLens = _activeLens;
    final threshold =
        ModelRegistry.configFor(currentLens).defaultLiveConfidence;

    final detections = <DetectedObject>[];
    for (final r in rawResults) {
      if (r.confidence < threshold) continue;

      final box = r.normalizedBox;
      if (box.width <= 0 || box.height <= 0) continue;

      // Pest-specific false positive suppression:
      // Agricultural pests are localized insects on crop parts.
      // Reject oversized boxes covering entire persons, bags, or room backgrounds.
      if (currentLens == DetectionLens.pest) {
        final area = box.width * box.height;
        if (area > 0.40 || box.width > 0.80 || box.height > 0.80) {
          continue; // Drop background/person/bag false positive
        }
      }

      if (currentLens == DetectionLens.disease) {
        final cls = DiseaseClass.resolve(
          className: r.className,
          classIndex: r.classIndex,
        );
        detections.add(DetectedObject(
          classIndex: cls.classIndex,
          className: cls.displayName,
          confidence: r.confidence,
          boundingBox: box,
          modelLens: currentLens,
        ));
      } else {
        detections.add(DetectedObject(
          classIndex: r.classIndex,
          className: r.className,
          confidence: r.confidence,
          boundingBox: box,
          modelLens: currentLens,
        ));
      }
    }

    _detectionsNotifier.value = detections;
  }

  // ══════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Native YOLO camera + overlay (single persistent view, in-place model switch)
          YOLOView(
            modelPath: _activeModelAsset,
            task: YOLOTask.detect,
            controller: _controller,
            confidenceThreshold: _activeLensConfig.defaultLiveConfidence,
            iouThreshold: 0.45,
            onResult: _onResult,
            onModelLoad: (path, task) {
              _switchTimeoutTimer?.cancel();
              if (!mounted) return;
              if (path == _activeModelAsset) {
                setState(() {
                  _loadedLens = _activeLens;
                  _isSwitchingLens = false;
                });
                _controller
                    .setConfidenceThreshold(
                        _activeLensConfig.defaultLiveConfidence)
                    .catchError((_) {});
              }
            },
            onModelError: (error, path, task) {
              _switchTimeoutTimer?.cancel();
              if (!mounted) return;
              setState(() {
                _activeLens = _loadedLens;
                _isSwitchingLens = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Failed to load lens model. Reverted to previous lens.'),
                  backgroundColor: AppColors.lossText,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          // ── Scanning line with RepaintBoundary & active pause ────
          _ScanLineOverlay(isActive: widget.isActive),

          // ── Top bar ───────────────────────────────────────────────
          _buildTopBar(),

          // ── Lens toggle pill bar ──────────────────────────────────
          _buildLensSelector(),

          // ── Bottom info bar (listens strictly to _detectionsNotifier) ─
          ValueListenableBuilder<List<DetectedObject>>(
            valueListenable: _detectionsNotifier,
            builder: (context, detections, _) {
              return _buildBottomBar(detections);
            },
          ),
        ],
      ),
    );
  }

  // ── Lens selector pill bar ───────────────────────────────────

  Widget _buildLensSelector() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 64,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _lensTab(
                    DetectionLens.disease, '🌿', 'Disease', AppColors.lossText),
                _lensTab(
                    DetectionLens.pest, '🐛', 'Pest', AppColors.accentOrange),
                _lensTab(DetectionLens.growth, '🍎', 'Growth',
                    AppColors.waterPumpButton),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _lensTab(DetectionLens lens, String emoji, String label, Color color) {
    final isActive = _activeLens == lens;
    return Expanded(
      child: GestureDetector(
        onTap: _isSwitchingLens ? null : () => _switchLens(lens),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSwitchingLens && isActive) ...[
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
              ] else ...[
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          right: 16,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else if (widget.onBackToHome != null) {
                  widget.onBackToHome!();
                }
              },
              icon: const Icon(LucideIcons.arrowLeft,
                  color: Colors.white, size: 22),
              tooltip: 'Back',
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'Live Scan',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
            ),
            _buildStatusChip(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.scan, color: AppColors.accentGreen, size: 14),
          SizedBox(width: 6),
          Text(
            'Scanning',
            style: TextStyle(
              color: AppColors.accentGreen,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────

  Widget _buildBottomBar(List<DetectedObject> detections) {
    final hasDiseaseDetection = detections.any((d) => d.isDiseased);
    final best = detections.isEmpty
        ? null
        : detections.reduce((a, b) => a.confidence > b.confidence ? a : b);

    // Colour scheme adapts to the active lens
    final Color barColor;
    if (_activeLens == DetectionLens.disease) {
      barColor =
          hasDiseaseDetection ? AppColors.lossText : AppColors.accentGreen;
    } else {
      barColor = _lensAccent;
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: 16,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: best == null
            ? const SizedBox.shrink()
            : GestureDetector(
                onTap: () => _showDetectionDetails(context, best),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: barColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _activeLens == DetectionLens.disease
                            ? (hasDiseaseDetection
                                ? LucideIcons.alertCircle
                                : LucideIcons.checkCircle)
                            : (_activeLens == DetectionLens.pest
                                ? LucideIcons.bug
                                : LucideIcons.sprout),
                        color: barColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              best.className,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              'Tap for prevention & treatments ℹ️',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: barColor.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(best.confidence * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              LucideIcons.chevronRight,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  CLICK-TO-DETAIL MODAL BOTTOM SHEET
  // ══════════════════════════════════════════════════════════════════

  void _showDetectionDetails(BuildContext context, DetectedObject detection) {
    if (_isDetailSheetOpen) return;
    _isDetailSheetOpen = true;
    _controller.pause();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (modalCtx) {
        if (detection.modelLens == DetectionLens.pest ||
            _activeLens == DetectionLens.pest) {
          return _buildPestDetailSheet(modalCtx, detection);
        } else if (detection.modelLens == DetectionLens.growth ||
            _activeLens == DetectionLens.growth) {
          return _buildGrowthDetailSheet(modalCtx, detection);
        } else {
          return _buildDiseaseDetailSheet(modalCtx, detection);
        }
      },
    ).whenComplete(() {
      if (mounted) {
        _isDetailSheetOpen = false;
        if (widget.isActive) {
          _controller.resume();
        }
      }
    });
  }

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

  Widget _buildDiseaseDetailSheet(BuildContext ctx, DetectedObject detection) {
    final cls = DiseaseClass.resolve(
      className: detection.className,
      classIndex: detection.classIndex,
    );
    final disease =
        DiseaseResult.fromDetection(cls.classIndex, detection.confidence);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Grab handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (disease.isHealthy
                                    ? AppColors.accentGreen
                                    : AppColors.lossText)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            disease.isHealthy
                                ? LucideIcons.checkCircle2
                                : LucideIcons.alertTriangle,
                            color: disease.isHealthy
                                ? AppColors.primaryGreen
                                : AppColors.lossText,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                disease.nameKey,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                disease.scientificNameKey,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x,
                              color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Confidence and Severity row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (disease.isHealthy
                                    ? AppColors.primaryGreen
                                    : AppColors.lossText)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'AI Confidence: ${(disease.confidencePercent).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: disease.isHealthy
                                  ? AppColors.primaryGreen
                                  : AppColors.lossText,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!disease.isHealthy)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Severity: ${disease.severityKey.toUpperCase()}',
                              style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        disease.descriptionKey,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Symptoms
                    if (disease.symptomKeys.isNotEmpty) ...[
                      const Text(
                        'Observed Symptoms',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...disease.symptomKeys.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(LucideIcons.dot,
                                    size: 16, color: AppColors.lossText),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Recommended Treatments
                    if (disease.treatments.isNotEmpty) ...[
                      const Text(
                        'Recommended Treatments & Dosage',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...disease.treatments.map(
                        (t) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(_treatmentIcon(t.iconName),
                                    color: AppColors.primaryGreen, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.nameKey,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      t.descriptionKey,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Prevention Tips
                    if (disease.preventionKeys.isNotEmpty) ...[
                      const Text(
                        'Long-term Prevention & Cultural Control',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...disease.preventionKeys.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Icon(LucideIcons.checkCircle2,
                                    size: 15, color: AppColors.accentGreen),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Back to Live Camera',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPestDetailSheet(BuildContext ctx, DetectedObject detection) {
    final pestClass = PestClass.resolve(
      className: detection.className,
      classIndex: detection.classIndex,
    );
    final pest =
        PestResult.fromDetection(pestClass.classIndex, detection.confidence);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(LucideIcons.bug,
                              color: AppColors.accentOrange, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pest.pest.displayName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Detected Pomegranate Insect Pest',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x,
                              color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.shieldAlert,
                              size: 14, color: AppColors.accentOrange),
                          const SizedBox(width: 6),
                          Text(
                            'AI Match: ${pest.confidencePercent.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppColors.accentOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        pest.description,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (pest.damageSigns.isNotEmpty) ...[
                      const Text(
                        'Damage Symptoms on Crop',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...pest.damageSigns.map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(LucideIcons.alertCircle,
                                    size: 15, color: Colors.redAccent),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(d,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    if (pest.organicControls.isNotEmpty) ...[
                      const Text(
                        'Organic & Biological Controls',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...pest.organicControls.map(
                        (ctrl) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.accentGreen
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ctrl.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen)),
                              const SizedBox(height: 3),
                              Text(ctrl.description,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (pest.chemicalControls.isNotEmpty) ...[
                      Text(
                        'Chemical Treatments (CIBRC Approved)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...pest.chemicalControls.map(
                        (ctrl) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ctrl.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo)),
                              const SizedBox(height: 3),
                              Text(ctrl.description,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (pest.ipmNotes.isNotEmpty) ...[
                      const Text(
                        'Integrated Pest Management (IPM)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...pest.ipmNotes.map(
                        (n) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(LucideIcons.checkCheck,
                                    size: 15, color: AppColors.accentGreen),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(n,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentOrange,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Back to Live Camera',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrowthDetailSheet(BuildContext ctx, DetectedObject detection) {
    final stageClass = GrowthStageClass.resolve(
      className: detection.className,
      classIndex: detection.classIndex,
    );
    final stage = GrowthStageResult.fromDetection(
        stageClass.classIndex, detection.confidence);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.90,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.waterPumpButton
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(LucideIcons.sprout,
                              color: AppColors.waterPumpButton, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stage.stage.displayName,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                  '~${stage.estimatedDaysToHarvest} days to harvest window',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x,
                              color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Phenological Overview',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(stage.phenologyNote,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Irrigation Advisory
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.droplets,
                                  size: 16, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Stage Irrigation Requirement',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.blue)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(stage.irrigationAdvisory,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  height: 1.35)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nutrient Advisory
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.leaf,
                                  size: 16, color: AppColors.primaryGreen),
                              SizedBox(width: 8),
                              Text('Nutrient & Fertigation Focus',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.primaryGreen)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(stage.nutrientAdvisory,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  height: 1.35)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Spray Caution
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.shieldAlert,
                                  size: 16, color: Color(0xFFD97706)),
                              SizedBox(width: 8),
                              Text('Pollinator & Spray Caution',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFFD97706))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(stage.sprayCaution,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  height: 1.35)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.waterPumpButton,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Back to Live Camera',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  SCAN LINE — subtle animated sweep while in Scanning state
// ══════════════════════════════════════════════════════════════════════

class _ScanLineOverlay extends StatefulWidget {
  final bool isActive;
  const _ScanLineOverlay({this.isActive = true});

  @override
  State<_ScanLineOverlay> createState() => _ScanLineOverlayState();
}

class _ScanLineOverlayState extends State<_ScanLineOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _anim.repeat();
    }
  }

  @override
  void didUpdateWidget(_ScanLineOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _anim.repeat();
      } else {
        _anim.stop();
      }
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              painter: _ScanLinePainter(progress: _anim.value),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  _ScanLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.accentGreen.withValues(alpha: 0.5),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y - 2, size.width, 4));
    canvas.drawRect(Rect.fromLTWH(0, y - 2, size.width, 4), paint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.progress != progress;
}
