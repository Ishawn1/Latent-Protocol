/// Identifies which inference lens is active in Live Detection
/// and which model produced a given [DetectedObject].
enum DetectionLens {
  disease,
  pest,
  growth,
}

/// Configuration for a single on-device YOLO26n TFLite model.
class AiModelConfig {
  /// Which inference pipeline this model belongs to.
  final DetectionLens lens;

  /// Flutter asset path for the .tflite file.
  final String assetPath;

  /// Human-readable name shown in the UI lens selector.
  final String displayName;

  /// If true this model is ALWAYS executed regardless of selected crop.
  /// The general pest model carries this flag.
  final bool alwaysActive;

  /// Default confidence threshold for real-time live video inference.
  final double defaultLiveConfidence;

  /// Default confidence threshold for high-res static photo analysis.
  final double defaultStaticConfidence;

  const AiModelConfig({
    required this.lens,
    required this.assetPath,
    required this.displayName,
    this.alwaysActive = false,
    required this.defaultLiveConfidence,
    required this.defaultStaticConfidence,
  });
}

/// Central model registry.
///
/// When a new crop is added (e.g. tomato), create a new [AiModelConfig]
/// for [DetectionLens.disease] and [DetectionLens.growth] and swap them
/// in [ModelRegistry.cropDisease] / [ModelRegistry.cropGrowth].
/// The pest model ([alwaysActive] = true) never changes.
class ModelRegistry {
  ModelRegistry._();

  // -- Crop-specific models (currently Pomegranate) ----------------------

  /// Pomegranate foliar disease -- 4 classes:
  ///   0: Alternaria, 1: Fungal Spot, 2: Bacterial Blight, 3: Healthy
  static const cropDisease = AiModelConfig(
    lens: DetectionLens.disease,
    assetPath: 'assets/models/pomegranate_yolo26n_416_int8.tflite',
    displayName: 'Disease',
    defaultLiveConfidence: 0.40,
    defaultStaticConfidence: 0.25,
  );

  /// Pomegranate phenological growth stages -- 5 classes:
  ///   0: bud, 1: flower, 2: early-fruit, 3: mid-growth, 4: mature
  static const cropGrowth = AiModelConfig(
    lens: DetectionLens.growth,
    assetPath: 'assets/models/pomegranate_growth_yolo26n_640_int8.tflite',
    displayName: 'Growth',
    defaultLiveConfidence: 0.45,
    defaultStaticConfidence: 0.35,
  );

  // -- Universal model (always executed, crop-agnostic) ------------------

  /// General crop pest detector (YOLO26s INT8, 640x640, 100 epochs) -- 9 classes:
  ///   0: grub, 1: red spider, 2: aphids, 3: Locustoidea,
  ///   4: Thrips, 5: whitefly, 6: Prodenia litura,
  ///   7: mango hopper, 8: jassids
  ///
  /// YOLO26s provides 3.5x capacity and achieves 0.49 validation classification
  /// loss with peak F1 at 0.40. Optimal operational confidence is 0.45 live / 0.40 static.
  static const pest = AiModelConfig(
    lens: DetectionLens.pest,
    assetPath: 'assets/models/pest_yolo26s_int8.tflite',
    displayName: 'Pest',
    alwaysActive: true,
    defaultLiveConfidence: 0.45,
    defaultStaticConfidence: 0.40,
  );

  /// All 3 lenses in the order shown in the UI pill bar.
  static const List<AiModelConfig> lenses = [cropDisease, pest, cropGrowth];

  /// Look up configuration by [DetectionLens].
  static AiModelConfig configFor(DetectionLens lens) =>
      lenses.firstWhere((m) => m.lens == lens);
}
