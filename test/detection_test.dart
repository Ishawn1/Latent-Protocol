import 'package:flutter_test/flutter_test.dart';
import 'package:smartkheti/models/detection_models.dart';
import 'package:smartkheti/models/disease_models.dart';

void main() {
  group('DiseaseClass tests', () {
    test('fromName resolves standard names', () {
      expect(DiseaseClass.fromName('Alternaria'), DiseaseClass.alternaria);
      expect(DiseaseClass.fromName('Fungal_Spot'), DiseaseClass.fungalSpot);
      expect(DiseaseClass.fromName('fungal spot'), DiseaseClass.fungalSpot);
      expect(DiseaseClass.fromName('Bacterial_Blight'), DiseaseClass.bacterialBlight);
      expect(DiseaseClass.fromName('bacterial blight'), DiseaseClass.bacterialBlight);
      expect(DiseaseClass.fromName('Healthy'), DiseaseClass.healthy);
      expect(DiseaseClass.fromName('healthy'), DiseaseClass.healthy);
    });

    test('fromName resolves numeric index strings', () {
      expect(DiseaseClass.fromName('0'), DiseaseClass.alternaria);
      expect(DiseaseClass.fromName('1'), DiseaseClass.fungalSpot);
      expect(DiseaseClass.fromName('2'), DiseaseClass.bacterialBlight);
      expect(DiseaseClass.fromName('3'), DiseaseClass.healthy);
      expect(DiseaseClass.fromName('class 0'), DiseaseClass.alternaria);
      expect(DiseaseClass.fromName('class_1'), DiseaseClass.fungalSpot);
      expect(DiseaseClass.fromName('class 2'), DiseaseClass.bacterialBlight);
      expect(DiseaseClass.fromName('class 3'), DiseaseClass.healthy);
    });

    test('resolve bypasses ultralytics_yolo classIndex: 0 bug', () {
      // In ultralytics_yolo 0.6.14, single-image inference hardcodes classIndex to 0.
      // resolve must prioritize the actual className string.
      expect(
        DiseaseClass.resolve(className: 'Bacterial_Blight', classIndex: 0),
        DiseaseClass.bacterialBlight,
      );
      expect(
        DiseaseClass.resolve(className: 'Fungal_Spot', classIndex: 0),
        DiseaseClass.fungalSpot,
      );
      expect(
        DiseaseClass.resolve(className: 'Healthy', classIndex: 0),
        DiseaseClass.healthy,
      );
      expect(
        DiseaseClass.resolve(className: 'Alternaria', classIndex: 0),
        DiseaseClass.alternaria,
      );
    });

    test('resolve falls back to classIndex if className is empty', () {
      expect(DiseaseClass.resolve(className: '', classIndex: 1), DiseaseClass.fungalSpot);
      expect(DiseaseClass.resolve(className: null, classIndex: 2), DiseaseClass.bacterialBlight);
      expect(DiseaseClass.resolve(className: '   ', classIndex: 3), DiseaseClass.healthy);
    });
  });

  group('DetectedObject.fromRaw tests', () {
    test('clamps bounds and handles inverted coordinates', () {
      final obj = DetectedObject.fromRaw(
        className: 'Bacterial_Blight',
        confidence: 0.85,
        left: 0.8,
        top: 0.6,
        right: 0.2, // inverted
        bottom: 0.1, // inverted
      );

      expect(obj.diseaseClass, DiseaseClass.bacterialBlight);
      expect(obj.boundingBox.left, 0.2);
      expect(obj.boundingBox.top, 0.1);
      expect(obj.boundingBox.right, 0.8);
      expect(obj.boundingBox.bottom, 0.6);
      expect(obj.isValidBox, true);
    });

    test('filters out degenerate 0-area boxes', () {
      final degenerate = DetectedObject.fromRaw(
        className: 'Alternaria',
        confidence: 0.9,
        left: 0.5,
        top: 0.5,
        right: 0.5,
        bottom: 0.5,
      );
      expect(degenerate.isValidBox, false);
    });
  });

  group('DiseaseResult dynamic severity & affected percentage', () {
    test('accepts override values without changing baselines for defaults', () {
      final defaultRes = DiseaseResult.fromDetection(2, 0.75);
      expect(defaultRes.severity, DiseaseSeverity.severe);
      expect(defaultRes.affectedPercent, 40);

      final dynamicRes = DiseaseResult.fromDetection(
        2,
        0.75,
        overrideSeverity: DiseaseSeverity.mild,
        overrideAffectedPercent: 12,
      );
      expect(dynamicRes.severity, DiseaseSeverity.mild);
      expect(dynamicRes.affectedPercent, 12);
      expect(dynamicRes.confidencePercent, closeTo(75.0, 0.01));
    });

    test('sanitizes confidence and affected percentages', () {
      final res = DiseaseResult.fromDetection(
        0,
        1.25, // > 1.0
        overrideAffectedPercent: 120, // > 100
      );
      expect(res.confidencePercent, 100.0);
      expect(res.affectedPercent, 100);
    });
  });
}
