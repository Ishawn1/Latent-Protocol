/// 5 phenological stage classes from pomegranate_growth_yolo26n_640_int8.tflite
/// Model labels: {0:bud, 1:flower, 2:early-fruit, 3:mid-growth, 4:mature}
enum GrowthStageClass {
  bud(0, 'Bud Initiation'),
  flower(1, 'Flowering'),
  earlyFruit(2, 'Early Fruit Set'),
  midGrowth(3, 'Mid-Growth / Sizing'),
  mature(4, 'Harvest Maturity');

  final int classIndex;
  final String displayName;
  const GrowthStageClass(this.classIndex, this.displayName);

  static GrowthStageClass fromIndex(int i) => GrowthStageClass.values.firstWhere(
        (e) => e.classIndex == i,
        orElse: () => GrowthStageClass.bud,
      );

  static GrowthStageClass fromName(String name) {
    final n = name.trim().toLowerCase();
    if (n.contains('bud')) return GrowthStageClass.bud;
    if (n.contains('flower')) return GrowthStageClass.flower;
    if (n.contains('early') || n.contains('early-fruit')) return GrowthStageClass.earlyFruit;
    if (n.contains('mid') || n.contains('mid-growth')) return GrowthStageClass.midGrowth;
    if (n.contains('mature') || n.contains('harvest')) return GrowthStageClass.mature;
    return GrowthStageClass.bud;
  }

  /// Resolves stage, preferring className over classIndex.
  static GrowthStageClass resolve({String? className, int? classIndex}) {
    if (className != null && className.trim().isNotEmpty) {
      return fromName(className);
    }
    if (classIndex != null) return fromIndex(classIndex);
    return GrowthStageClass.bud;
  }

  bool get isSpraySensitive => this == GrowthStageClass.flower || this == GrowthStageClass.mature;
}

// ---------------------------------------------------------------------------

class GrowthStageResult {
  final GrowthStageClass stage;
  final double confidencePercent;
  final int estimatedDaysToHarvest;
  final String phenologyNote;
  final String irrigationAdvisory;
  final String nutrientAdvisory;
  final String sprayCaution;

  const GrowthStageResult({
    required this.stage,
    required this.confidencePercent,
    required this.estimatedDaysToHarvest,
    required this.phenologyNote,
    required this.irrigationAdvisory,
    required this.nutrientAdvisory,
    required this.sprayCaution,
  });

  static GrowthStageResult fromDetection(int classIndex, double confidence) {
    final stage = GrowthStageClass.fromIndex(classIndex);
    final conf = (confidence * 100).clamp(0.0, 100.0);
    switch (stage) {
      // --------------------------------------------------------------- bud
      case GrowthStageClass.bud:
        return GrowthStageResult(
          stage: stage,
          confidencePercent: conf,
          estimatedDaysToHarvest: 150,
          phenologyNote:
              'Dormant buds initiating. Canopy pruning should be complete. '
              'This marks the start of the productive season. '
              'Adequate soil nutrients at this stage determine flowering intensity.',
          irrigationAdvisory:
              'Light irrigation (15–20 mm/week). '
              'Avoid waterlogging which delays bud break.',
          nutrientAdvisory:
              'Apply basal NPK dose (100:50:50 g N:P:K per tree). '
              'Soil drench of Zinc Sulphate (10 g/tree) improves bud vigour.',
          sprayCaution:
              'Safe to spray any fungicide or bactericide at this stage. '
              'No pollinator risk. Good time for preventive Bordeaux mixture.',
        );

      // --------------------------------------------------------- flowering
      case GrowthStageClass.flower:
        return GrowthStageResult(
          stage: stage,
          confidencePercent: conf,
          estimatedDaysToHarvest: 120,
          phenologyNote:
              'Peak flowering — the most critical growth window. '
              'Pomegranate is cross-pollinated; honeybee activity is essential '
              'for maximum fruit set. Water stress or waterlogging at this stage '
              'causes massive blossom drop.',
          irrigationAdvisory:
              'Maintain steady soil moisture (50–60%). '
              'Check SN-3000 sensor twice daily during peak bloom.',
          nutrientAdvisory:
              'Foliar spray Boron (1 g/L) + Calcium Nitrate (5 g/L) to improve '
              'fruit set and reduce blossom drop. '
              'Avoid high-nitrogen foliar sprays which promote vegetative growth.',
          sprayCaution:
              'CRITICAL: DO NOT spray broad-spectrum insecticides '
              'between 8 AM and 5 PM during flowering. '
              'Only spray fungicides or bio-agents after 6 PM to protect pollinators.',
        );

      // -------------------------------------------------------- early-fruit
      case GrowthStageClass.earlyFruit:
        return GrowthStageResult(
          stage: stage,
          confidencePercent: conf,
          estimatedDaysToHarvest: 90,
          phenologyNote:
              'Fruitlets at marble size. High cell division rate. '
              'Fruit drop management is critical; excessive crop load thins '
              'naturally but hand thinning doubles remaining fruit size.',
          irrigationAdvisory:
              'Increase irrigation to 25–30 mm/week. '
              'Maintain SN-3000 target zone 50–65% soil moisture.',
          nutrientAdvisory:
              'Foliar Monopotassium Phosphate (MKP 0:52:34) at 3 g/L. '
              'Promotes cell expansion and strengthens fruit wall.',
          sprayCaution:
              'Chemical sprays generally safe at this stage. '
              'Observe 21-day pre-harvest interval for systemic pesticides.',
        );

      // ------------------------------------------------------- mid-growth
      case GrowthStageClass.midGrowth:
        return GrowthStageResult(
          stage: stage,
          confidencePercent: conf,
          estimatedDaysToHarvest: 45,
          phenologyNote:
              'Fruit enlarging rapidly. Aril development and colour '
              'initiation ongoing. Irregular irrigation is the primary cause '
              'of fruit cracking/splitting at this stage.',
          irrigationAdvisory:
              'CRITICAL: Maintain very consistent soil moisture (55–70%). '
              'Sudden wet-dry cycles cause fruit splitting — the most damaging '
              'physiological disorder in pomegranate.',
          nutrientAdvisory:
              'Foliar Potassium Sulphate (SOP 0:0:50) at 5 g/L improves '
              'fruit colour and Brix. Calcium (CaNO3) sprays reduce cracking.',
          sprayCaution:
              'Pre-harvest interval strictly required. '
              'Avoid copper-based sprays — cause dark surface staining on rind.',
        );

      // ------------------------------------------------------- mature
      case GrowthStageClass.mature:
        return GrowthStageResult(
          stage: stage,
          confidencePercent: conf,
          estimatedDaysToHarvest: 7,
          phenologyNote:
              'Fruit at harvest maturity. Aril colour deep red/crimson. '
              'Rind turns yellow-red and gives a metallic sound when tapped. '
              'Harvest within 7–10 days to prevent over-ripening and cracking.',
          irrigationAdvisory:
              'Stop irrigation 5–7 days before harvest to improve '
              'fruit colour, Brix, and shelf life.',
          nutrientAdvisory:
              'No further nutrient applications. '
              'Foliar sprays at this stage can leave residue on the edible rind.',
          sprayCaution:
              'DO NOT apply any chemical pesticide at this stage. '
              'Pre-harvest interval for most compounds has NOT elapsed. '
              'Use only water-based washes if essential.',
        );
    }
  }
}
