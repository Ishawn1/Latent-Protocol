import 'dart:ui';
import 'ai_model_registry.dart';

/// The 4 disease classes the YOLO26n model detects.
///
/// Classes 0–2 are diseases; class 3 is healthy.
enum DiseaseClass {
  alternaria('Alternaria', 0),
  fungalSpot('Fungal Spot', 1),
  bacterialBlight('Bacterial Blight', 2),
  healthy('Healthy', 3);

  final String displayName;
  final int classIndex;
  const DiseaseClass(this.displayName, this.classIndex);

  static DiseaseClass fromIndex(int idx) => DiseaseClass.values.firstWhere(
        (e) => e.classIndex == idx,
        orElse: () => DiseaseClass.healthy,
      );

  static DiseaseClass fromName(String name) {
    final trimmed = name.trim();
    // Support numeric index strings e.g. "0", "1", "class 0", "class_1"
    final classNumMatch =
        RegExp(r'^(?:class[_\s]*)?(\d+)$', caseSensitive: false)
            .firstMatch(trimmed);
    if (classNumMatch != null) {
      final idx = int.tryParse(classNumMatch.group(1) ?? '');
      if (idx != null && idx >= 0 && idx < DiseaseClass.values.length) {
        return DiseaseClass.fromIndex(idx);
      }
    }

    final normalized =
        trimmed.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    if (normalized.contains('alternaria')) return DiseaseClass.alternaria;
    if (normalized.contains('fungal') ||
        normalized.contains('cercospora') ||
        normalized.contains('anthracnose') ||
        normalized.contains('spot')) {
      return DiseaseClass.fungalSpot;
    }
    if (normalized.contains('bacterial') ||
        normalized.contains('blight') ||
        normalized.contains('telya')) {
      return DiseaseClass.bacterialBlight;
    }
    if (normalized.contains('health')) {
      return DiseaseClass.healthy;
    }
    return DiseaseClass.healthy;
  }

  /// Resolves class prioritizing className because single-image predictions in
  /// ultralytics_yolo 0.6.14 contain a bug where classIndex is hardcoded to 0.
  static DiseaseClass resolve({String? className, int? classIndex}) {
    if (className != null && className.trim().isNotEmpty) {
      return fromName(className);
    }
    if (classIndex != null &&
        classIndex >= 0 &&
        classIndex < DiseaseClass.values.length) {
      return fromIndex(classIndex);
    }
    return DiseaseClass.healthy;
  }

  bool get isDiseased => classIndex < 3;
}

/// States of the Smart-Capture state machine.
enum SmartCaptureState {
  /// Actively scanning — boxes drawn by native overlay.
  scanning,

  /// A disease was tracked but the camera moved away.
  lostTarget,

  /// Same disease re-acquired — auto-capture triggered.
  targetReacquired,
}

/// Actions the SmartCaptureController asks the screen to perform.
enum SmartCaptureAction { none, triggerHaptic, autoCapture }

/// A single YOLO detection, mapped from the ultralytics_yolo result type.
class DetectedObject {
  final int classIndex;
  final String className;
  final double confidence;

  /// Bounding box in normalized [0,1] coordinates.
  final Rect boundingBox;

  /// Which model produced this detection — used for colour-coding overlays
  /// and routing results to the correct dossier (disease / pest / growth).
  /// Defaults to [DetectionLens.disease] to preserve all existing call sites.
  final DetectionLens modelLens;

  const DetectedObject({
    required this.classIndex,
    required this.className,
    required this.confidence,
    required this.boundingBox,
    this.modelLens = DetectionLens.disease,
  });

  /// Creates a [DetectedObject] from raw coordinates.
  ///
  /// [modelLens] identifies which model produced this detection so the result
  /// screen can look up the correct agronomic dossier (disease / pest / growth).
  /// Defaults to [DetectionLens.disease] to preserve existing callers.
  factory DetectedObject.fromRaw({
    required String className,
    required double confidence,
    int? classIndex,
    required double left,
    required double top,
    required double right,
    required double bottom,
    DetectionLens modelLens = DetectionLens.disease,
  }) {
    // Resolve the class through DiseaseClass (disease lens only).
    // Pest and growth lenses store the raw classIndex/className directly.
    final int resolvedIndex;
    final String resolvedName;
    if (modelLens == DetectionLens.disease) {
      final d =
          DiseaseClass.resolve(className: className, classIndex: classIndex);
      resolvedIndex = d.classIndex;
      resolvedName = d.displayName;
    } else {
      resolvedIndex = classIndex ?? 0;
      resolvedName = className.isNotEmpty ? className : classIndex.toString();
    }

    final clLeft = left.clamp(0.0, 1.0);
    final clTop = top.clamp(0.0, 1.0);
    final clRight = right.clamp(0.0, 1.0);
    final clBottom = bottom.clamp(0.0, 1.0);

    final rect = Rect.fromLTRB(
      clLeft <= clRight ? clLeft : clRight,
      clTop <= clBottom ? clTop : clBottom,
      clLeft <= clRight ? clRight : clLeft,
      clTop <= clBottom ? clBottom : clTop,
    );

    return DetectedObject(
      classIndex: resolvedIndex,
      className: resolvedName,
      confidence: confidence.clamp(0.0, 1.0),
      boundingBox: rect,
      modelLens: modelLens,
    );
  }

  DiseaseClass get diseaseClass => DiseaseClass.fromIndex(classIndex);
  bool get isDiseased => classIndex < 3;
  bool get isValidBox => boundingBox.width > 0 && boundingBox.height > 0;
}

/// Metadata for an image captured by the auto-capture flow.
class CapturedDiseaseImage {
  final String fullImagePath;
  final String className;
  final double confidence;
  final DateTime timestamp;

  const CapturedDiseaseImage({
    required this.fullImagePath,
    required this.className,
    required this.confidence,
    required this.timestamp,
  });
}
