import '../models/detection_models.dart';

/// Implements the 3-state "Smart Capture" state machine.
///
/// Feed it a list of [DetectedObject]s on each YOLO frame (from the
/// `ultralytics_yolo` plugin's `onResult` callback) and act on the returned
/// [SmartCaptureAction].
///
/// ### States
/// - **Scanning** — Normal operation. Tracks the highest-confidence disease.
/// - **Lost Target** — Disease disappeared for [_lostThresholdFrames] frames.
///   Haptic fires so the farmer knows to move back.
/// - **Target Re-Acquired** — Same disease class came back. Auto-capture fires.
class SmartCaptureController {
  // ── Tunables ────────────────────────────────────────────────────────
  static const int _lostThresholdFrames = 5;
  static const double _diseaseConfidenceThreshold = 0.40;

  // ── Internal state ──────────────────────────────────────────────────
  SmartCaptureState _state = SmartCaptureState.scanning;
  int? _lastKnownClassIndex;
  double _lastKnownConfidence = 0.0;
  int _framesWithoutTarget = 0;
  bool _hasEverDetectedDisease = false;

  // ── Accessors ────────────────────────────────────────────────────────
  SmartCaptureState get state => _state;
  int? get lastKnownClassIndex => _lastKnownClassIndex;
  double get lastKnownConfidence => _lastKnownConfidence;

  // ── Core logic ────────────────────────────────────────────────────────

  /// Feed one frame's detections. Returns the action the screen should perform.
  SmartCaptureAction processFrame(List<DetectedObject> detections) {
    // Pick the highest-confidence disease in this frame.
    DetectedObject? bestDisease;
    for (final det in detections) {
      if (det.isDiseased && det.confidence >= _diseaseConfidenceThreshold) {
        if (bestDisease == null || det.confidence > bestDisease.confidence) {
          bestDisease = det;
        }
      }
    }

    switch (_state) {
      case SmartCaptureState.scanning:
        if (bestDisease != null) {
          _lastKnownClassIndex = bestDisease.classIndex;
          _lastKnownConfidence = bestDisease.confidence;
          _hasEverDetectedDisease = true;
          _framesWithoutTarget = 0;
        } else if (_hasEverDetectedDisease) {
          _framesWithoutTarget++;
          if (_framesWithoutTarget >= _lostThresholdFrames) {
            _state = SmartCaptureState.lostTarget;
            return SmartCaptureAction.triggerHaptic;
          }
        }
        return SmartCaptureAction.none;

      case SmartCaptureState.lostTarget:
        if (bestDisease != null && bestDisease.classIndex == _lastKnownClassIndex) {
          _lastKnownConfidence = bestDisease.confidence;
          _state = SmartCaptureState.targetReacquired;
          return SmartCaptureAction.autoCapture;
        }
        return SmartCaptureAction.none;

      case SmartCaptureState.targetReacquired:
        // Screen is performing capture — wait for reset().
        return SmartCaptureAction.none;
    }
  }

  /// Reset to Scanning state after a successful capture.
  void reset() {
    _state = SmartCaptureState.scanning;
    _lastKnownClassIndex = null;
    _lastKnownConfidence = 0.0;
    _framesWithoutTarget = 0;
    _hasEverDetectedDisease = false;
  }
}
