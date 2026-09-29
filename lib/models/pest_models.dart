/// 9 general pest classes from pest_yolo26n_640_int8.tflite
/// Model labels: {0:grub, 1:red spider, 2:aphids, 3:Locustoidea,
///                4:Thrips, 5:whitefly, 6:Prodenia litura, 7:mango hopper, 8:jassids}
enum PestClass {
  grub(0, 'Grub / White Grub'),
  redSpider(1, 'Red Spider Mite'),
  aphids(2, 'Aphids'),
  locustoidea(3, 'Locust / Grasshopper'),
  thrips(4, 'Thrips'),
  whitefly(5, 'Whitefly'),
  prodenia(6, 'Prodenia litura (Cutworm)'),
  mangoHopper(7, 'Leafhopper / Mango Hopper'),
  jassids(8, 'Jassids (Leafhoppers)');

  final int classIndex;
  final String displayName;
  const PestClass(this.classIndex, this.displayName);

  static PestClass fromIndex(int i) => PestClass.values.firstWhere(
        (e) => e.classIndex == i,
        orElse: () => PestClass.aphids,
      );

  static PestClass fromName(String name) {
    final n = name.trim().toLowerCase();
    for (final p in PestClass.values) {
      if (n.contains(p.displayName.toLowerCase().split(' ').first)) return p;
    }
    if (n.contains('grub')) return PestClass.grub;
    if (n.contains('spider') || n.contains('mite')) return PestClass.redSpider;
    if (n.contains('aphid')) return PestClass.aphids;
    if (n.contains('locust') || n.contains('grasshop')) return PestClass.locustoidea;
    if (n.contains('thrip')) return PestClass.thrips;
    if (n.contains('white') || n.contains('fly')) return PestClass.whitefly;
    if (n.contains('prodenia') || n.contains('cutworm')) return PestClass.prodenia;
    if (n.contains('hopper')) return PestClass.mangoHopper;
    if (n.contains('jassid') || n.contains('leafhopper')) return PestClass.jassids;
    return PestClass.aphids; // safe fallback
  }

  /// Resolves pest class, preferring className over classIndex.
  static PestClass resolve({String? className, int? classIndex}) {
    if (className != null && className.trim().isNotEmpty) {
      return fromName(className);
    }
    if (classIndex != null) return fromIndex(classIndex);
    return PestClass.aphids;
  }
}

// ---------------------------------------------------------------------------

class PestTreatment {
  final String name;
  final String description;
  final String iconName; // matches _treatmentIcon() in result screens
  const PestTreatment({
    required this.name,
    required this.description,
    required this.iconName,
  });
}

// ---------------------------------------------------------------------------

class PestResult {
  final PestClass pest;
  final double confidencePercent;
  final String description;
  final List<String> damageSigns;
  final List<PestTreatment> organicControls;
  final List<PestTreatment> chemicalControls;
  final List<String> ipmNotes;

  const PestResult({
    required this.pest,
    required this.confidencePercent,
    required this.description,
    required this.damageSigns,
    required this.organicControls,
    required this.chemicalControls,
    required this.ipmNotes,
  });

  /// Build a full agronomic dossier from model output.
  static PestResult fromDetection(int classIndex, double confidence) {
    final pest = PestClass.fromIndex(classIndex);
    final conf = (confidence * 100).clamp(0.0, 100.0);
    switch (pest) {
      // ------------------------------------------------------------------ grub
      case PestClass.grub:
        return PestResult(
          pest: pest,
          confidencePercent: conf,
          description:
              'White grubs (larvae of Holotrichia spp.) feed on pomegranate roots, '
              'causing sudden wilting of entire branches. Adult beetles emerge '
              'during June–July and feed on foliage at night.',
          damageSigns: const [
            'Sudden wilting of one or more branches',
            'Roots eaten off below soil surface',
            'C-shaped white larvae found in root zone',
          ],
          organicControls: const [
            PestTreatment(
              name: 'Metarhizium anisopliae',
              description: 'Soil drench with 5 g/L of fungal bioagent at root zone at planting.',
              iconName: 'leaf',
            ),
            PestTreatment(
              name: 'Light Traps',
              description: 'Install at dusk during June–July to capture adult beetles.',
              iconName: 'droplets',
            ),
          ],
          chemicalControls: const [
            PestTreatment(
              name: 'Chlorpyrifos 20 EC',
              description: '2.5 ml/L soil drench around trunk base; repeat after 30 days.',
              iconName: 'science',
            ),
          ],
          ipmNotes: const [
            'Deep summer ploughing (May) exposes pupae to birds and lethal sunlight',
            'Avoid raw animal dung manure which harbors eggs',
            'Do not intercrop with groundnut or soybean — alternative grub hosts',
          ],
        );

      // -------------------------------------------------- red spider mite
      case PestClass.redSpider:
        return PestResult(
          pest: pest,
          confidencePercent: conf,
          description:
              'Red spider mites (Tetranychus urticae) colonise the abaxial leaf '
              'surface, sucking cell contents. Populations explode in hot, dry '
              'weather (>35 °C, <40% RH).',
          damageSigns: const [
            'Fine webbing on undersides of leaves',
            'Bronze-yellow stippling on upper leaf surface',
            'Leaf desiccation and premature drop under heavy infestation',
          ],
          organicControls: const [
            PestTreatment(
              name: 'Neem Oil Spray',
              description: '3 ml/L neem oil + 0.5 ml/L liquid soap as a contact acaricide.',
              iconName: 'leaf',
            ),
            PestTreatment(
              name: 'Water Misting',
              description: 'Regular overhead misting reduces mite populations under hot dry conditions.',
              iconName: 'droplets',
            ),
          ],
          chemicalControls: const [
            PestTreatment(
              name: 'Hexythiazox 5.45 EC',
              description: '1 ml/L; highly effective on eggs and nymphs. Repeat after 21 days.',
              iconName: 'science',
            ),
          ],
          ipmNotes: const [
            'Avoid excessive nitrogen fertilizer — succulent foliage favors mite reproduction',
            'Predatory mite Phytoseiulus persimilis can be released as biocontrol',
          ],
        );

      // ----------------------------------------------------------- aphids
      case PestClass.aphids:
        return PestResult(
          pest: pest,
          confidencePercent: conf,
          description:
              'Aphids (Aphis punicae) cluster on young terminal shoots causing '
              'leaf curling, sticky honeydew, and sooty mold. Spread by ants '
              'tending aphid colonies and by wind.',
          damageSigns: const [
            'Curled, distorted tender shoot tips',
            'Sticky honeydew coating upper leaf surfaces',
            'Black sooty mold growth on honeydew',
          ],
          organicControls: const [
            PestTreatment(
              name: 'NSKE Spray',
              description: '5% Neem Seed Kernel Extract spray at first sighting of colonies.',
              iconName: 'leaf',
            ),
            PestTreatment(
              name: 'Neem Oil + Soap',
              description: '3 ml/L neem oil + 0.5 ml/L soap; disrupts wax coat on aphid body.',
              iconName: 'droplets',
            ),
          ],
          chemicalControls: const [
            PestTreatment(
              name: 'Acetamiprid 20 SP',
              description: '0.2 g/L water spray. Pre-harvest interval: 21 days.',
              iconName: 'science',
            ),
          ],
          ipmNotes: const [
            'Release Chrysoperla carnea (lacewing) @ 50,000 eggs/acre as biocontrol',
            'Prune heavily colonised shoot tips and destroy',
            'Manage ant colonies — ants protect aphids from natural enemies',
          ],
        );

      // -------------------------------------------------------- locustoidea
      case PestClass.locustoidea:
        return PestResult(
          pest: pest,
          confidencePercent: conf,
          description:
              'Locusts and grasshoppers cause severe defoliation during outbreak years. '
              'Migrating swarms can strip entire orchards within hours.',
          damageSigns: const [
            'Ragged, large bites on leaf margins',
            'Complete defoliation of branches',
            'Egg pods in soil near orchard boundaries',
          ],
          organicControls: const [
            PestTreatment(
              name: 'Metarhizium acridum',
              description: 'Bio-pesticide spray (Green Muscle) targeted at hoppers. '
                  'Effective within 7–14 days of application.',
              iconName: 'leaf',
            ),
          ],
          chemicalControls: const [
            PestTreatment(
              name: 'Malathion 50 EC',
              description: '2 ml/L aerial or ground spray during early morning hours.',
              iconName: 'science',
            ),
          ],
          ipmNotes: const [
            'Report locust sightings to the State Plant Protection department immediately',
            'Coordinate with neighboring farms for area-wide management',
          ],
        );

      // ------------------------------------------------------------ thrips
      case PestClass.thrips:
        return PestResult(
          pest: pest,
          confidencePercent: conf,
          description:
              'Thrips (Scirtothrips dorsalis) cause silvery-white scarring on the '
              'fruit rind and upward leaf curling. Peak infestation during hot dry '
              'months (March–May) and post-monsoon (October–November).',
          damageSigns: const [
            'Silver-white scraping / corky scars on fruit rind',
            'Upward curling of young terminal leaves',
            'Flower drop under heavy infestation',
          ],
          organicControls: const [
            PestTreatment(
              name: 'Blue / Yellow Sticky Traps',
              description: '15–20 traps per acre at canopy height. Replace every 10 days.',
              iconName: 'leaf',
            ),
            PestTreatment(
              name: 'NSKE + Neem Oil',
              description: '5% NSKE + 3 ml/L neem oil spray at first sign of infestation.',
              iconName: 'droplets',
            ),
          ],
          chemicalControls: const [
            PestTreatment(
              name: 'Spinetoram 11.7 SC',
              description: '1 ml/L water; repeat after 15 days. Pre-harvest interval: 7 days.',
              iconName: 'science',
            ),
          ],
          ipmNotes: const [
            'Spray ONLY after 6 PM during flowering to protect honeybee pollinators',
            'Avoid broad-spectrum insecticides during 8 AM – 5 PM when bees are active',
            'Monitor traps weekly and record counts to track infestation trends',
          ],
        );

      // ---------------------------------------------------------- whitefly
      case PestClass.whitefly:
        return PestResult(
          pest: pest,
          confidencePercent: conf,
          description:
              'Whitefly nymphs (Bemisia tabaci / Trialeurodes vaporariorum) suck '
              'leaf sap from the abaxial surface, causing chlorosis and transmitting '
              'viral diseases like Tomato Yellow Leaf Curl Virus.',
          damageSigns: const [
            'Yellow chlorotic patches on older leaves',
            'White waxy powder / nymphal scales on leaf undersides',
            'Sooty mold growing on honeydew',
          ],
          organicControls: const [
            PestTreatment(
              name: 'Yellow Sticky Traps',
              description: '15–20 per acre placed at crop canopy level.',
              iconName: 'leaf',
            ),
          ],
          chemicalControls: const [
            PestTreatment(
              name: 'Buprofezin 25 SC',
              description: '1.5 ml/L; IGR targeting nymphal stages. '
                  'Do not spray during flowering. PHI: 14 days.',
              iconName: 'science',
            ),
          ],
          ipmNotes: const [
            'Reflective silver mulch film reduces whitefly landing rate by ~40%',
            'Avoid excessive nitrogen fertilization — lush foliage attracts whitefly',
            'Remove and destroy severely infected leaves',
          ],
        );

      // ---------------------------------------------------------- prodenia
      case PestClass.prodenia:
        return PestResult(
          pest: pest,
          confidencePercent: conf,
          description:
              'Prodenia litura (tobacco cutworm / army worm) larvae feed '
              'nocturnally on foliage. Young larvae skeletonize leaves; '
              'older larvae eat large holes.',
          damageSigns: const [
            'Skeletonized leaves with transparent epidermis',
            'Irregular large holes in older leaves',
            'Caterpillar faecal pellets on leaf surfaces',
          ],
          organicControls: const [
            PestTreatment(
              name: 'Pheromone Traps',
              description: 'Install Spodoptera litura lure traps (10–12/acre) for mass trapping.',
              iconName: 'leaf',
            ),
            PestTreatment(
              name: 'Bacillus thuringiensis',
              description: 'Bt kurstaki spray (2 g/L) targets early-instar larvae.',
              iconName: 'droplets',
            ),
          ],
          chemicalControls: const [
            PestTreatment(
              name: 'Chlorantraniliprole 18.5 SC',
              description: '0.3 ml/L spray; highly effective on young larvae. PHI: 14 days.',
              iconName: 'science',
            ),
          ],
          ipmNotes: const [
            'Apply sprays in early morning or late evening when larvae are active',
            'Deep ploughing after harvest exposes pupae to soil predators',
          ],
        );

      // ------------------------------------------------------- mango hopper
      case PestClass.mangoHopper:
        return PestResult(
          pest: pest,
          confidencePercent: conf,
          description:
              'Leafhoppers / mango hoppers (Amrasca devastans) suck sap from leaves, '
              'causing marginal leaf burn (hopperburn). Nymphs are particularly '
              'damaging on young crop foliage.',
          damageSigns: const [
            'Marginal leaf burn (brown scorching of leaf edges)',
            'Leaf curl and puckering',
            'Reduced plant vigour and stunting',
          ],
          organicControls: const [
            PestTreatment(
              name: 'Neem Oil Spray',
              description: '3 ml/L neem oil + soap solution; repels and disrupts nymph feeding.',
              iconName: 'leaf',
            ),
          ],
          chemicalControls: const [
            PestTreatment(
              name: 'Imidacloprid 17.8 SL',
              description: '0.3 ml/L as foliar spray at first sign. PHI: 21 days.',
              iconName: 'science',
            ),
          ],
          ipmNotes: const [
            'Avoid excessive use of nitrogen fertilizers',
            'Intercrop with coriander or fennel to attract parasitic wasps',
          ],
        );

      // ----------------------------------------------------------- jassids
      case PestClass.jassids:
        return PestResult(
          pest: pest,
          confidencePercent: conf,
          description:
              'Jassids (Empoasca spp.) are small wedge-shaped leafhoppers that '
              'damage crops by toxicogenic feeding — saliva blocks phloem, '
              'causing characteristic V-shaped yellowing at leaf tips.',
          damageSigns: const [
            'V-shaped yellowing starting at leaf tip ("jassid curl")',
            'Leaf margins curling downward',
            'Reduced photosynthesis and plant stunting',
          ],
          organicControls: const [
            PestTreatment(
              name: 'NSKE Spray',
              description: '5% Neem Seed Kernel Extract spray at early infestation.',
              iconName: 'leaf',
            ),
          ],
          chemicalControls: const [
            PestTreatment(
              name: 'Thiamethoxam 25 WG',
              description: '0.3 g/L foliar spray. PHI: 21 days. Do not apply near water bodies.',
              iconName: 'science',
            ),
          ],
          ipmNotes: const [
            'Hairy / pubescent leaf varieties show natural resistance to jassids',
            'Avoid planting near cotton which is a primary jassid reservoir host',
          ],
        );
    }
  }
}
