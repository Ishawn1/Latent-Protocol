/// Severity of a detected disease.
enum DiseaseSeverity { mild, moderate, severe }

/// Result from an Edge AI disease analysis.
class DiseaseResult {
  final String nameKey;
  final String scientificNameKey;
  final String descriptionKey;
  final double confidencePercent;
  final DiseaseSeverity severity;
  final int affectedPercent;
  final List<String> symptomKeys;
  final List<Treatment> treatments;
  final List<String> preventionKeys;

  const DiseaseResult({
    required this.nameKey,
    required this.scientificNameKey,
    required this.descriptionKey,
    required this.confidencePercent,
    required this.severity,
    required this.affectedPercent,
    required this.symptomKeys,
    required this.treatments,
    required this.preventionKeys,
  });

  bool get isHealthy => nameKey.toLowerCase() == 'healthy';
  bool get isDiseased => !isHealthy;

  String get severityKey {
    switch (severity) {
      case DiseaseSeverity.mild:
        return 'mild';
      case DiseaseSeverity.moderate:
        return 'moderate';
      case DiseaseSeverity.severe:
        return 'severe';
    }
  }

  static DiseaseResult fromDetection(
    int classIndex,
    double confidence, {
    DiseaseSeverity? overrideSeverity,
    int? overrideAffectedPercent,
  }) {
    final sanitizedConfidence = (confidence * 100).clamp(0.0, 100.0);
    switch (classIndex) {
      case 0:
        return DiseaseResult(
          nameKey: 'Alternaria',
          scientificNameKey: 'Alternaria alternata',
          descriptionKey:
              'Alternaria causes dark brown to black circular spots with concentric rings on pomegranate foliage and fruit rind.',
          confidencePercent: sanitizedConfidence,
          severity: overrideSeverity ?? DiseaseSeverity.moderate,
          affectedPercent: overrideAffectedPercent?.clamp(0, 100) ?? 25,
          symptomKeys: [
            'Dark brown spots with concentric rings',
            'Yellow halos surrounding leaf spots',
            'Premature leaf and fruit drop'
          ],
          treatments: const [
            Treatment(
              nameKey: 'Fungicide Spray',
              descriptionKey:
                  'Apply Mancozeb (0.25%) or Copper Oxychloride (0.3%) at 10-14 day intervals.',
              iconName: 'science',
            ),
            Treatment(
              nameKey: 'Pruning & Sanitation',
              descriptionKey:
                  'Prune blighted twigs and burn fallen infected leaves.',
              iconName: 'scissors',
            ),
          ],
          preventionKeys: [
            'Avoid overhead sprinkler irrigation to keep the canopy dry',
            'Maintain proper row spacing to improve air circulation',
            'Apply prophylactic bio-agents like Trichoderma viride'
          ],
        );
      case 1:
        return DiseaseResult(
          nameKey: 'Fungal Spot',
          scientificNameKey:
              'Colletotrichum gloeosporioides / Cercospora punicae',
          descriptionKey:
              'Fungal complex (Anthracnose & Cercospora) causing circular dark brown sunken spots on leaves and fruit pericarp.',
          confidencePercent: sanitizedConfidence,
          severity: overrideSeverity ?? DiseaseSeverity.moderate,
          affectedPercent: overrideAffectedPercent?.clamp(0, 100) ?? 20,
          symptomKeys: [
            'Circular dark brown to black spots with grey centers',
            'Shot-hole appearance on maturing leaves',
            'Sunken necrotic lesions on fruit rind'
          ],
          treatments: const [
            Treatment(
              nameKey: 'Systemic Fungicide',
              descriptionKey:
                  'Spray Carbendazim 50 WP (0.1%) or Difenoconazole (0.05%) at first sight.',
              iconName: 'science',
            ),
            Treatment(
              nameKey: 'Bordeaux Mixture',
              descriptionKey:
                  'Apply 1% Bordeaux mixture spray after orchard pruning.',
              iconName: 'droplets',
            ),
          ],
          preventionKeys: [
            'Ensure rapid soil water drainage during monsoon periods',
            'Regularly inspect undersides (abaxial surface) of leaves',
            'Remove dried twig cankers during summer pruning'
          ],
        );
      case 2:
        return DiseaseResult(
          nameKey: 'Bacterial Blight',
          scientificNameKey: 'Xanthomonas axonopodis pv. punicae',
          descriptionKey:
              'Severe bacterial blight (Telya disease) causing angular water-soaked spots, nodal stem cankers, and characteristic fruit cracking.',
          confidencePercent: sanitizedConfidence,
          severity: overrideSeverity ?? DiseaseSeverity.severe,
          affectedPercent: overrideAffectedPercent?.clamp(0, 100) ?? 40,
          symptomKeys: [
            'Angular water-soaked leaf spots turning dark brown',
            'Black oily spots on fruit surface',
            'L-shaped and Y-shaped longitudinal fruit cracking',
            'Cankers on stems leading to branch dieback'
          ],
          treatments: const [
            Treatment(
              nameKey: 'Bactericide + Copper',
              descriptionKey:
                  'Spray Streptocycline (500 ppm) + Copper Oxychloride (0.25%) or 2-Bromo-2-nitropropane-1,3-diol (Bacterinol).',
              iconName: 'science',
            ),
            Treatment(
              nameKey: 'Paste Application',
              descriptionKey:
                  'Scrape stem cankers and paste with 10% Bordeaux paste or Copper paste.',
              iconName: 'scissors',
            ),
          ],
          preventionKeys: [
            'Plant certified disease-free, tissue-culture saplings',
            'Disinfect pruning secateurs in 1% sodium hypochlorite solution between trees',
            'Avoid field operations when tree foliage is wet',
            'Enforce quarantine on saplings from infected zones'
          ],
        );
      case 3:
      default:
        return DiseaseResult(
          nameKey: 'Healthy',
          scientificNameKey: 'Punica granatum',
          descriptionKey:
              'The pomegranate foliage and fruit appear healthy with robust green pigmentation and no visible signs of pathogen infection.',
          confidencePercent: sanitizedConfidence,
          severity: overrideSeverity ?? DiseaseSeverity.mild,
          affectedPercent: overrideAffectedPercent?.clamp(0, 100) ?? 0,
          symptomKeys: [
            'Uniform green foliage with healthy turgor',
            'Smooth fruit skin without necrotic spots or lesions',
            'Clean stem nodes and active shoot elongation'
          ],
          treatments: const [
            Treatment(
              nameKey: 'Preventive Monitoring',
              descriptionKey:
                  'Continue weekly visual scouting of foliage and Tier-1 microclimate readings.',
              iconName: 'leaf',
            ),
            Treatment(
              nameKey: 'Balanced Fertigation',
              descriptionKey:
                  'Maintain balanced nutrition with Zinc, Boron, and Calcium foliar sprays.',
              iconName: 'droplets',
            ),
          ],
          preventionKeys: [
            'Continue regular orchard hygiene and weed management',
            'Monitor soil moisture sensors to prevent root water stress',
            'Maintain prophylactic organic sprays like neem oil'
          ],
        );
    }
  }

  /// Demo result for UI display while AI model is WIP.
  static const demo = DiseaseResult(
    nameKey: 'leafBlight',
    scientificNameKey: 'leafBlightScientific',
    descriptionKey: 'leafBlightDesc',
    confidencePercent: 94.5,
    severity: DiseaseSeverity.moderate,
    affectedPercent: 25,
    symptomKeys: ['symptom1', 'symptom2', 'symptom3', 'symptom4'],
    treatments: [
      Treatment(
        nameKey: 'treatment1',
        descriptionKey: 'treatment1Desc',
        iconName: 'science',
      ),
      Treatment(
        nameKey: 'treatment2',
        descriptionKey: 'treatment2Desc',
        iconName: 'scissors',
      ),
      Treatment(
        nameKey: 'treatment3',
        descriptionKey: 'treatment3Desc',
        iconName: 'wind',
      ),
      Treatment(
        nameKey: 'treatment4',
        descriptionKey: 'treatment4Desc',
        iconName: 'droplets',
      ),
    ],
    preventionKeys: [
      'prevention1',
      'prevention2',
      'prevention3',
      'prevention4',
    ],
  );
}

/// A recommended treatment for a detected disease.
class Treatment {
  final String nameKey;
  final String descriptionKey;
  final String iconName;

  const Treatment({
    required this.nameKey,
    required this.descriptionKey,
    required this.iconName,
  });
}
