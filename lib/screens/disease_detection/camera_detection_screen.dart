import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/ai_model_registry.dart';
import '../../models/detection_models.dart';
import '../../models/disease_models.dart';
import 'comprehensive_result_screen.dart';

/// Carries a model inference result tagged by the producing lens.
/// [data] is null when the model failed or returned nothing.
typedef _TaggedResult = ({DetectionLens lens, Map<String, dynamic>? data});


class CameraDetectionScreen extends StatefulWidget {
  const CameraDetectionScreen({super.key});

  @override
  State<CameraDetectionScreen> createState() => _CameraDetectionScreenState();
}

class _CameraDetectionScreenState extends State<CameraDetectionScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;

  // ── Per-model state ──────────────────────────────────────────────────

  YOLO? _diseaseYolo;
  YOLO? _pestYolo;
  YOLO? _growthYolo;

  /// Tracks every YOLO instance currently being loaded.
  /// Prevents double-dispose if the widget is removed mid-load.
  final Set<YOLO> _pendingYolos = {};


  bool _isDisposed = false;


  // ── Lifecycle ────────────────────────────────────────────────────────


  @override
  void initState() {
    super.initState();
    _initModels();
  }

  Future<void> _initModels() async {
    await Future.wait([
      _loadModel(ModelRegistry.cropDisease),
      _loadModel(ModelRegistry.pest),
      _loadModel(ModelRegistry.cropGrowth),
    ]);
  }

  Future<void> _loadModel(AiModelConfig config) async {
    YOLO? yolo;
    try {
      yolo = YOLO(modelPath: config.assetPath, task: YOLOTask.detect);
      _pendingYolos.add(yolo);
      final loaded = await yolo.loadModel();

      // Widget was disposed while this model was loading — clean up the
      // inflight instance and do NOT call setState.
      if (_isDisposed) {
        _pendingYolos.remove(yolo);
        await yolo.dispose();
        return;
      }

      _pendingYolos.remove(yolo);

      if (loaded) {
        // Use _isDisposed as sole guard; mounted is not reliable post-async
        if (!_isDisposed) {
          setState(() {
            switch (config.lens) {
              case DetectionLens.disease:
                _diseaseYolo = yolo;
              case DetectionLens.pest:
                _pestYolo = yolo;
              case DetectionLens.growth:
                _growthYolo = yolo;
            }
          });
        }
      } else {
        debugPrint('[Camera] ${config.displayName} model failed to load.');
      }
    } catch (e) {
      debugPrint('[Camera] Error loading ${config.displayName} model: $e');
      if (yolo != null) {
        _pendingYolos.remove(yolo);
        if (!_isDisposed) await yolo.dispose();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Dispose all inflight instances first, then loaded ones
    for (final y in _pendingYolos) {
      y.dispose();
    }
    _pendingYolos.clear();
    _diseaseYolo?.dispose();
    _pestYolo?.dispose();
    _growthYolo?.dispose();
    super.dispose();
  }

  // ── Image picking ────────────────────────────────────────────────────

  Future<void> _pickFromCamera() async {
    if (_isAnalyzing) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null && !_isDisposed) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                  child: Text(
                      'Camera access denied. Please enable camera permission in settings.')),
            ],
          ),
          backgroundColor: AppColors.lossText,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isAnalyzing) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                  child: Text(
                      'Gallery access denied. Please enable storage permission in settings.')),
            ],
          ),
          backgroundColor: AppColors.lossText,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ── Analysis ─────────────────────────────────────────────────────────

  Future<void> _analyzeImage() async {
    if (_isAnalyzing || _selectedImage == null) return;

    // Validate file existence
    if (!await _selectedImage!.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected image file was moved or deleted. Please select again.'),
          backgroundColor: AppColors.lossText,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _selectedImage = null);
      return;
    }

    // Validate file size (< 25 MB)
    try {
      final fileSize = await _selectedImage!.length();
      if (fileSize > 25 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image file is too large (>25 MB). Please choose a smaller photo.'),
            backgroundColor: AppColors.lossText,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } catch (_) {}

    if (!mounted || _isDisposed) return;
    setState(() => _isAnalyzing = true);

    try {
      final Uint8List bytes = await _selectedImage!.readAsBytes();
      if (bytes.isEmpty) throw StateError('Image data is empty');
      if (_isDisposed) return;

      // ── Build tagged futures — order irrelevant as each carries its lens ──
      final List<Future<_TaggedResult>> futures = [];

      Future<_TaggedResult> safePredictDisease(Uint8List b) async {
        try {
          final r = await _diseaseYolo!.predict(
            b,
            confidenceThreshold: ModelRegistry.cropDisease.defaultStaticConfidence,
            iouThreshold: 0.45,
          );
          return (lens: DetectionLens.disease, data: r);
        } catch (_) {
          return (lens: DetectionLens.disease, data: null);
        }
      }

      Future<_TaggedResult> safePredictPest(Uint8List b) async {
        try {
          // Elevated to 0.50 to suppress INT8 background noise on non-crop objects
          final r = await _pestYolo!.predict(
            b,
            confidenceThreshold: ModelRegistry.pest.defaultStaticConfidence,
            iouThreshold: 0.45,
          );
          return (lens: DetectionLens.pest, data: r);
        } catch (_) {
          return (lens: DetectionLens.pest, data: null);
        }
      }

      Future<_TaggedResult> safePredictGrowth(Uint8List b) async {
        try {
          final r = await _growthYolo!.predict(
            b,
            confidenceThreshold: ModelRegistry.cropGrowth.defaultStaticConfidence,
            iouThreshold: 0.45,
          );
          return (lens: DetectionLens.growth, data: r);
        } catch (_) {
          return (lens: DetectionLens.growth, data: null);
        }
      }

      if (_diseaseYolo != null) futures.add(safePredictDisease(bytes));
      if (_pestYolo != null) futures.add(safePredictPest(bytes));   // always called
      if (_growthYolo != null) futures.add(safePredictGrowth(bytes));

      final List<_TaggedResult> taggedResults = await Future.wait(futures);
      if (_isDisposed) return;

      // ── Parse results by tag — immune to ordering ────────────────────
      final diseaseDetections = <DetectedObject>[];
      final pestDetections = <DetectedObject>[];
      final growthDetections = <DetectedObject>[];

      for (final tagged in taggedResults) {
        if (tagged.data == null) continue;
        final parsed = _parseDetections(tagged.data!, tagged.lens);
        switch (tagged.lens) {
          case DetectionLens.disease:
            diseaseDetections.addAll(parsed);
          case DetectionLens.pest:
            pestDetections.addAll(parsed);
          case DetectionLens.growth:
            growthDetections.addAll(parsed);
        }
      }

      // ── Build disease dossier ────────────────────────────────────────
      DiseaseResult? finalDiseaseResult;

      final diseased = diseaseDetections.where((d) => d.isDiseased && d.confidence >= 0.25).toList();
      final healthy = diseaseDetections.where((d) => !d.isDiseased && d.confidence >= 0.25).toList();

      if (diseased.isNotEmpty) {
        final best = diseased.reduce((a, b) => a.confidence > b.confidence ? a : b);
        double area = 0.0;
        for (final d in diseased) {
          area += d.boundingBox.width * d.boundingBox.height;
        }
        final affected = ((area * 120).clamp(5, 85)).round();
        final severity = (diseased.length >= 4 || affected >= 40)
            ? DiseaseSeverity.severe
            : (diseased.length >= 2 || affected >= 20)
                ? DiseaseSeverity.moderate
                : DiseaseSeverity.mild;

        finalDiseaseResult = DiseaseResult.fromDetection(
          best.classIndex,
          best.confidence,
          overrideSeverity: severity,
          overrideAffectedPercent: affected,
        );
      } else if (healthy.isNotEmpty) {
        final best = healthy.reduce((a, b) => a.confidence > b.confidence ? a : b);
        finalDiseaseResult = DiseaseResult.fromDetection(3, best.confidence);
      }

      // ── At least one model must have produced something ──────────────
      final bool anyDetection = finalDiseaseResult != null ||
          pestDetections.isNotEmpty ||
          growthDetections.isNotEmpty;

      if (!anyDetection) {
        if (!mounted) return;
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No crop foliage, pests, or growth stage identified. '
                    'Ensure good lighting and photograph leaves or fruit clearly.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.accentOrange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComprehensiveResultScreen(
            imagePath: _selectedImage!.path,
            diseaseResult: finalDiseaseResult,
            pestDetections: pestDetections,
            growthDetections: growthDetections,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[Camera] Error analyzing image: $e');
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to analyse image. Please try again.'),
          backgroundColor: AppColors.lossText,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// Parses a raw YOLO result map into typed [DetectedObject] instances
  /// tagged with the given [lens].
  List<DetectedObject> _parseDetections(Map<String, dynamic> raw, DetectionLens lens) {
    final results = <DetectedObject>[];
    final rawDetections = raw['detections'] as List?;
    final rawBoxes = raw['boxes'] as List?;
    final minConfidence = ModelRegistry.configFor(lens).defaultStaticConfidence;

    void addValidDetection(DetectedObject det) {
      if (!det.isValidBox || det.confidence < minConfidence) return;

      // Pest-specific false positive suppression:
      // Agricultural pests are localized insects on crop parts.
      // Reject oversized boxes covering entire persons, bags, or room backgrounds.
      if (lens == DetectionLens.pest) {
        final area = det.boundingBox.width * det.boundingBox.height;
        if (area > 0.40 || det.boundingBox.width > 0.80 || det.boundingBox.height > 0.80) {
          return; // Drop false positive
        }
      }

      results.add(det);
    }

    if (rawDetections != null && rawDetections.isNotEmpty) {
      for (final item in rawDetections) {
        if (item is Map) {
          final r = YOLOResult.fromMap(item);
          final det = DetectedObject.fromRaw(
            className: r.className,
            confidence: r.confidence,
            classIndex: r.classIndex,
            left: r.normalizedBox.left,
            top: r.normalizedBox.top,
            right: r.normalizedBox.right,
            bottom: r.normalizedBox.bottom,
            modelLens: lens,
          );
          addValidDetection(det);
        }
      }
    } else if (rawBoxes != null && rawBoxes.isNotEmpty) {
      for (final item in rawBoxes) {
        if (item is Map) {
          final cName = item['className']?.toString() ?? item['class']?.toString() ?? '';
          final conf = (item['confidence'] as num?)?.toDouble() ?? 0.0;
          final x1 = (item['x1_norm'] as num?)?.toDouble() ?? 0.0;
          final y1 = (item['y1_norm'] as num?)?.toDouble() ?? 0.0;
          final x2 = (item['x2_norm'] as num?)?.toDouble() ?? 1.0;
          final y2 = (item['y2_norm'] as num?)?.toDouble() ?? 1.0;
          final det = DetectedObject.fromRaw(
            className: cName,
            confidence: conf,
            left: x1,
            top: y1,
            right: x2,
            bottom: y2,
            modelLens: lens,
          );
          addValidDetection(det);
        }
      }
    }
    return results;
  }




  void _clearImage() {
    if (_isAnalyzing) return;
    setState(() {
      _selectedImage = null;
    });
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
          l10n.takePhoto,
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
            // Image Preview Area
            _buildImagePreview(l10n),
            const SizedBox(height: 24),

            // Action Buttons
            if (_selectedImage == null) ...[
              _buildCaptureOptions(l10n),
            ] else ...[
              _buildImageActions(l10n),
            ],

            const SizedBox(height: 24),

            // Tips Section
            _buildTipsSection(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedImage != null
              ? AppColors.accentGreen
              : AppColors.borderLight,
          width: _selectedImage != null ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _selectedImage != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (_isAnalyzing)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.analyzing,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    LucideIcons.image,
                    color: AppColors.primaryGreen,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noImageSelected,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.takePhotoOrSelect,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCaptureOptions(AppLocalizations l10n) {
    return Column(
      children: [
        // Camera Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _pickFromCamera,
            icon: const Icon(LucideIcons.camera, size: 20),
            label: Text(l10n.takePhoto),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Gallery Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isAnalyzing ? null : _pickFromGallery,
            icon: const Icon(LucideIcons.image, size: 20),
            label: Text(l10n.chooseFromGallery),
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

  Widget _buildImageActions(AppLocalizations l10n) {
    return Column(
      children: [
        // Analyze Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _analyzeImage,
            icon: const Icon(LucideIcons.scan, size: 20),
            label: Text(_isAnalyzing ? l10n.analyzing : l10n.analyzeImage),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Action Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isAnalyzing ? null : _pickFromCamera,
                icon: const Icon(LucideIcons.camera, size: 18),
                label: Text(l10n.retake),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.borderLight),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isAnalyzing ? null : _clearImage,
                icon: const Icon(LucideIcons.trash2, size: 18),
                label: Text(l10n.remove),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.lossText,
                  side: const BorderSide(color: AppColors.lossText),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTipsSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.weatherTagBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.lightbulb,
                color: AppColors.weatherTagText,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.tipsForBestResults,
                style: const TextStyle(
                  color: AppColors.weatherTagText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem(l10n.tip1),
          _buildTipItem(l10n.tip2),
          _buildTipItem(l10n.tip3),
          _buildTipItem(l10n.tip4),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.check,
            color: AppColors.weatherTagText,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
