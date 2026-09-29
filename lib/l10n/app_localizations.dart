import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // App name and general
      'appName': 'SmartKheti',
      'settings': 'Settings',
      'language': 'Language',
      'selectLanguage': 'Select Language',
      'english': 'English',
      'hindi': 'हिंदी',
      'gujarati': 'ગુજરાતી',
      'comingSoon': 'Coming Soon — Work in Progress',

      // Navigation
      'home': 'Home',
      'myFarm': 'My Farm',
      'tasks': 'Tasks',
      'market': 'Advisory',
      'farmMap': 'Farm Map',
      'liveScan': 'Live Scan',
      'alerts': 'Alerts',
      'analytics': 'Analytics',
      'farmAnalytics': 'Farm Analytics',

      // Irrigation
      'irrigationControl': 'Smart Irrigation',
      'manualMode': 'Manual',
      'recommendedMode': 'Recommended',
      'automaticMode': 'Automatic',
      'irrigateNow': 'Irrigate Now',
      'delayIrrigation': 'Delay Irrigation',
      'soilMoistureOptimal': 'Soil Moisture Optimal',
      'soilSaturated': 'Soil Saturated',
      'sensorFault': 'Sensor Fault',
      'approveAndStart': 'Approve & Start',
      'emergencyStop': 'Emergency Stop',
      'targetMoisture': 'Target Moisture',
      'flowRate': 'Flow Rate',
      'failsafeActive': 'Failsafe Timer Active',
      'safetyLockedWetLeaf': 'Safety Lock: Foliage Wet',

      // Farm Map & Zoning
      'virtualZones': 'Virtual Zones',
      'zoneOverview': 'Zone Health Overview',
      'scoutedHealthy': 'Scouted Healthy',
      'scoutedDisease': 'Disease Symptoms',
      'liveHardwareNode': 'Live Hardware Node',
      'pendingScout': 'Pending Scout',
      'inspectZone': 'Inspect Zone',
      'pomegranate': 'Pomegranate',
      'pomegranateBhagwa': 'Pomegranate (Bhagwa)',

      // Mode Switcher
      'farmerMode': 'Farmer Mode',
      'expertMode': 'Expert Mode',
      'modeSimpleTooltip': 'Simple visual view for farmers',
      'modeExpertTooltip': 'Detailed sensor telemetry for experts',

      // Farmer Mode Simple Strings
      'everythingGreat': 'Everything is Great! 🌿',
      'everythingGreatDesc': 'Soil has good moisture and weather is clear. No watering needed today.',
      'soilThirsty': 'Soil is Thirsty 💧',
      'soilThirstyDesc': 'Soil is drying out. Water your pomegranate trees today.',
      'holdWatering': 'Hold Watering 🌧️',
      'holdWateringDesc': 'Leaves are wet from rain or dew. Hold watering to prevent crop disease.',
      'checkingSensors': 'Checking Sensors... 📡',
      'checkingSensorsDesc': 'Connecting to field sensor. Please check Node 1.',
      'startWateringNow': 'Start Watering (30 Min)',
      'scanLeavesNow': 'Scan Leaves for Disease',
      'waterField': 'Water Field',
      'seeFarmMap': 'See Farm Map',
      'advisoryAlertsSimple': 'Crop Advice & Alerts',
      'soilHealthy': 'Moist & Healthy',
      'soilDry': 'Dry / Needs Water',
      'cropProtected': 'Healthy & Thriving',
      'cropCheck': 'Check Leaves',

      // Home Screen
      'goodMorning': 'Good morning',
      'goodAfternoon': 'Good afternoon',
      'goodEvening': 'Good evening',
      'farmThriving': 'Your farm is thriving. Ready for today\'s tasks?',
      'weather': 'Microclimate (Node 1)',
      'farmHealth': 'Farm Health',
      'good': 'Good',
      'excellent': 'Excellent',
      'partlyCloudy': 'Partly Cloudy',
      'sunny': 'Sunny',
      'rainy': 'Rainy',
      'allSystemsGood': 'All systems good',
      'leafWetness': 'Leaf Wetness',
      'dsv': 'Disease Severity Value (DSV)',
      'nodeConnected': 'Node Connected (BLE)',
      'nodeDisconnected': 'Node Disconnected',
      'solenoidValve': '12V Solenoid Valve',
      'plots': 'plots',
      'autoIrrigation': 'Auto-irrigation',
      'farmTools': 'Farm Tools',
      'diseaseDetection': 'Disease Detection',
      'cropCare': 'Crop Care',
      'irrigation': 'Irrigation',
      'soilHealth': 'Soil Health',
      'marketPrices': 'Market Prices',
      'pestControl': 'Pest Control',

      // My Farm Screen
      'farmOverview': 'Farm Overview',
      'totalArea': 'Total Area',
      'acres': 'Acres',
      'activeCrops': 'Active Crops',
      'crops': 'Crops',
      'waterUsage': 'Water Usage',
      'liters': 'Liters',
      'yourPlots': 'Your Plots',
      'healthy': 'Healthy',
      'needsAttention': 'Needs Attention',
      'viewDetails': 'View Details',
      'addPlot': 'Add Plot',
      'wheat': 'Wheat',
      'rice': 'Rice',
      'cotton': 'Cotton',
      'sugarcane': 'Sugarcane',
      'tomato': 'Tomato',
      'potato': 'Potato',
      'onion': 'Onion',
      'groundnut': 'Groundnut',
      'northField': 'North Field',
      'southPlot': 'South Plot',
      'openValve': 'Open Valve',
      'autoTriggerDesc': 'Auto-triggers when soil moisture < 30%',
      'planted': 'Planted',
      'harvestIn': 'Harvest in',
      'days': 'days',

      // Tasks Screen
      'todaysTasks': 'Today\'s Tasks',
      'upcomingTasks': 'Upcoming Tasks',
      'completedTasks': 'Completed Tasks',
      'addTask': 'Add Task',
      'priority': 'Priority',
      'high': 'High',
      'medium': 'Medium',
      'low': 'Low',
      'dueToday': 'Due Today',
      'dueTomorrow': 'Due Tomorrow',
      'overdue': 'Overdue',
      'completed': 'Completed',
      'pending': 'Pending',
      'applyFertilizer': 'Apply Fertilizer',
      'checkIrrigation': 'Check Irrigation System',
      'pestInspection': 'Pest Inspection',
      'harvestWheat': 'Harvest Wheat',
      'soilTesting': 'Soil Testing',
      'waterPump': 'Water Pump',
      'pumpOn': 'Turn On',
      'pumpOff': 'Turn Off',

      // Advisory Screen
      'advisoryAlerts': 'Advisory & Alerts',
      'alertMoistureTitle': 'Moisture Threshold Reached',
      'alertMoistureDesc': 'Node 1 reported soil moisture below 30%. Solenoid Valve triggered automatically.',
      'alertDsvTitle': 'High DSV Warning',
      'alertDsvDesc': 'Disease Severity Value has increased to 4.5 in South Plot. Please use Tier-2 Edge Scanner for inspection.',
      'alertStableTitle': 'Farm Health Stable',
      'alertStableDesc': 'All nodes are reporting stable microclimates. No immediate action required.',
      'twoMinsAgo': '2 mins ago',
      'oneHourAgo': '1 hour ago',
      'yesterday': 'Yesterday',

      // Market Screen
      'marketOverview': 'Market Overview',
      'todayPrices': 'Today\'s Prices',
      'priceAlerts': 'Price Alerts',
      'trending': 'Trending',
      'perQuintal': 'per quintal',
      'perKg': 'per kg',
      'priceUp': 'Price Up',
      'priceDown': 'Price Down',
      'noChange': 'No Change',
      'buyNow': 'Buy Now',
      'sellNow': 'Sell Now',
      'commodities': 'Commodities',
      'grains': 'Grains',
      'vegetables': 'Vegetables',
      'fruits': 'Fruits',

      // Disease Detection Screen
      'aiPoweredDetection': 'Edge AI Detection (Tier-2)',
      'detectDiseaseDesc':
          'Identify plant diseases instantly using on-device Edge AI scanning',
      'chooseDetectionMethod': 'Scanner Options',
      'takePhoto': 'Scan with Edge AI',
      'usePhoneCamera': 'Use your phone camera (Tier-2 Scout)',
      'howItWorks': 'How It Works',
      'captureImage': 'Capture Image',
      'captureImageDesc': 'Take a photo of the affected plant or leaf',
      'aiAnalysis': 'On-Device AI Analysis',
      'aiAnalysisDesc': 'YOLOv8-Nano model analyzes the image locally',
      'getResults': 'Get Results',
      'getResultsDesc': 'Receive diagnosis and treatment recommendations',

      // Camera Detection Screen
      'noImageSelected': 'No image selected',
      'takePhotoOrSelect': 'Take a photo or select from gallery',
      'chooseFromGallery': 'Choose from Gallery',
      'analyzeImage': 'Analyze Image',
      'analyzing': 'Analyzing locally...',
      'retake': 'Retake',
      'remove': 'Remove',
      'tipsForBestResults': 'Tips for Tier-2 Scanning',
      'tip1': 'Hold camera 10-15cm away from the leaf',
      'tip2': 'Focus specifically on the underside (abaxial) of leaves',
      'tip3': 'Ensure good lighting for clear images',
      'tip4': 'Avoid blurry or shaky photos',
      'replace': 'Replace',

      // Analysis Result Screen
      'analysisResult': 'Analysis Result',
      'diseaseDetected': 'Disease Detected',
      'droneImage': 'Drone Image',
      'cameraPhoto': 'Camera Photo',
      'confidence': 'Confidence',
      'severity': 'Severity',
      'affected': 'Affected',
      'moderate': 'Moderate',
      'mild': 'Mild',
      'severe': 'Severe',
      'symptoms': 'Symptoms',
      'recommendedTreatment': 'Recommended Treatment',
      'preventionTips': 'Prevention Tips',
      'backToHome': 'Back to Home',
      'scanAnother': 'Scan Another',
      'reportSaved': 'Report saved!',

      // Disease names and descriptions
      'Alternaria': 'Alternaria',
      'Fungal Spot': 'Fungal Spot',
      'Bacterial Blight': 'Bacterial Blight',
      'Healthy': 'Healthy',
      'leafBlight': 'Leaf Blight',
      'leafBlightScientific': 'Alternaria alternata',
      'leafBlightDesc':
          'Leaf blight is a common fungal disease that causes brown spots and yellowing of leaves. It spreads rapidly in humid conditions and can significantly reduce crop yield if left untreated.',
      'symptom1': 'Brown irregular spots on leaves',
      'symptom2': 'Yellow halos around spots',
      'symptom3': 'Leaf curling and wilting',
      'symptom4': 'Premature leaf drop',
      'treatment1': 'Fungicide Application',
      'treatment1Desc': 'Apply copper-based fungicide every 7-10 days',
      'treatment2': 'Remove Infected Leaves',
      'treatment2Desc': 'Prune and dispose of infected plant parts',
      'treatment3': 'Improve Air Circulation',
      'treatment3Desc': 'Space plants properly to reduce humidity',
      'treatment4': 'Water Management',
      'treatment4Desc': 'Avoid overhead watering, water at soil level',
      'prevention1': 'Rotate crops annually',
      'prevention2': 'Use disease-resistant varieties',
      'prevention3': 'Maintain proper plant spacing',
      'prevention4': 'Remove plant debris after harvest',
    },

    // Hindi translations
    'hi': {
      // App name and general
      'appName': 'स्मार्टखेती',
      'settings': 'सेटिंग्स',
      'language': 'भाषा',
      'selectLanguage': 'भाषा चुनें',
      'english': 'English',
      'hindi': 'हिंदी',
      'gujarati': 'ગુજરાતી',
      'comingSoon': 'जल्द आ रहा है — कार्य प्रगति पर',

      // Navigation
      'home': 'होम',
      'myFarm': 'मेरा खेत',
      'tasks': 'कार्य',
      'market': 'सलाह',
      'farmMap': 'खेत का नक्शा',
      'liveScan': 'लाइव स्कैन',
      'alerts': 'अलर्ट',
      'analytics': 'एनालिटिक्स',
      'farmAnalytics': 'फार्म विश्लेषण',

      // Irrigation
      'irrigationControl': 'स्मार्ट सिंचाई',
      'manualMode': 'मैनुअल',
      'recommendedMode': 'सिफारिश',
      'automaticMode': 'स्वचालित',
      'irrigateNow': 'अभी सिंचाई करें',
      'delayIrrigation': 'सिंचाई टालें',
      'soilMoistureOptimal': 'मिट्टी की नमी सामान्य है',
      'soilSaturated': 'मिट्टी अत्यधिक गीली है',
      'sensorFault': 'सेंसर में खराबी',
      'approveAndStart': 'स्वीकार करें और शुरू करें',
      'emergencyStop': 'इमरजेंसी स्टॉप',
      'targetMoisture': 'लक्षित नमी',
      'flowRate': 'प्रवाह दर',
      'failsafeActive': 'सुरक्षा टाइमर सक्रिय',
      'safetyLockedWetLeaf': 'सुरक्षा लॉक: पत्तियां गीली हैं',

      // Farm Map & Zoning
      'virtualZones': 'वर्चुअल ज़ोन',
      'zoneOverview': 'ज़ोन स्वास्थ्य स्थिति',
      'scoutedHealthy': 'जांच में स्वस्थ',
      'scoutedDisease': 'रोग के लक्षण मिले',
      'liveHardwareNode': 'लाइव हार्डवेयर नोड',
      'pendingScout': 'जांच लंबित',
      'inspectZone': 'ज़ोन विवरण देखें',
      'pomegranate': 'अनार',
      'pomegranateBhagwa': 'अनार (भगवा)',

      // Mode Switcher
      'farmerMode': 'किसान मोड',
      'expertMode': 'विशेषज्ञ मोड',
      'modeSimpleTooltip': 'किसानों के लिए सरल दृश्य',
      'modeExpertTooltip': 'विशेषज्ञों के लिए विस्तृत सेंसर डेटा',

      // Farmer Mode Simple Strings
      'everythingGreat': 'सब कुछ बहुत अच्छा है! 🌿',
      'everythingGreatDesc': 'मिट्टी में अच्छी नमी है और मौसम साफ है। आज पानी देने की जरूरत नहीं है।',
      'soilThirsty': 'मिट्टी को पानी चाहिए 💧',
      'soilThirstyDesc': 'मिट्टी सूख रही है। आज अपने अनार के पेड़ों को पानी दें।',
      'holdWatering': 'सिंचाई रोकें 🌧️',
      'holdWateringDesc': 'पत्तियां गीली हैं। बीमारी से बचाव के लिए अभी पानी न दें।',
      'checkingSensors': 'सेंसर की जांच हो रही है... 📡',
      'checkingSensorsDesc': 'फील्ड सेंसर से कनेक्ट हो रहे हैं। कृपया नोड 1 जांचें।',
      'startWateringNow': 'पानी शुरू करें (30 मिनट)',
      'scanLeavesNow': 'पत्तियों में रोग जांचें',
      'waterField': 'खेत में पानी दें',
      'seeFarmMap': 'खेत का नक्शा देखें',
      'advisoryAlertsSimple': 'फसल सलाह व अलर्ट',
      'soilHealthy': 'नमी अच्छी है',
      'soilDry': 'सूखी / पानी चाहिए',
      'cropProtected': 'फसल सुरक्षित व स्वस्थ',
      'cropCheck': 'पत्तियां जांचें',

      // Home Screen
      'goodMorning': 'सुप्रभात',
      'goodAfternoon': 'शुभ दोपहर',
      'goodEvening': 'शुभ संध्या',
      'farmThriving': 'आपका खेत फल-फूल रहा है। आज के कार्यों के लिए तैयार हैं?',
      'weather': 'Microclimate (Node 1)',
      'farmHealth': 'खेत का स्वास्थ्य',
      'good': 'अच्छा',
      'excellent': 'उत्कृष्ट',
      'partlyCloudy': 'आंशिक बादल',
      'sunny': 'धूप',
      'rainy': 'बारिश',
      'allSystemsGood': 'सभी सिस्टम ठीक हैं',
      'leafWetness': 'पत्ती गीलापन',
      'dsv': 'रोग गंभीरता मान (DSV)',
      'nodeConnected': 'नोड जुड़ा (BLE)',
      'nodeDisconnected': 'नोड विच्छेद',
      'solenoidValve': '12V सोलेनॉइड वाल्व',
      'plots': 'प्लॉट',
      'autoIrrigation': 'ऑटो-सिंचाई',
      'farmTools': 'खेती के उपकरण',
      'diseaseDetection': 'रोग पहचान',
      'cropCare': 'फसल देखभाल',
      'irrigation': 'सिंचाई',
      'soilHealth': 'मिट्टी का स्वास्थ्य',
      'marketPrices': 'बाज़ार भाव',
      'pestControl': 'कीट नियंत्रण',

      // My Farm Screen
      'farmOverview': 'खेत का अवलोकन',
      'totalArea': 'कुल क्षेत्र',
      'acres': 'एकड़',
      'activeCrops': 'सक्रिय फसलें',
      'crops': 'फसलें',
      'waterUsage': 'पानी का उपयोग',
      'liters': 'लीटर',
      'yourPlots': 'आपके प्लॉट',
      'healthy': 'स्वस्थ',
      'needsAttention': 'ध्यान देने की जरूरत',
      'viewDetails': 'विवरण देखें',
      'addPlot': 'प्लॉट जोड़ें',
      'wheat': 'गेहूं',
      'rice': 'चावल',
      'cotton': 'कपास',
      'sugarcane': 'गन्ना',
      'tomato': 'टमाटर',
      'potato': 'आलू',
      'onion': 'प्याज',
      'groundnut': 'मूंगफली',
      'northField': 'उत्तर खेत',
      'southPlot': 'दक्षिण प्लॉट',
      'openValve': 'वाल्व खोलें',
      'autoTriggerDesc': 'मिट्टी की नमी 30% से कम होने पर स्वचालित',
      'planted': 'बोया गया',
      'harvestIn': 'कटाई में',
      'days': 'दिन',

      // Tasks Screen
      'todaysTasks': 'आज के कार्य',
      'upcomingTasks': 'आगामी कार्य',
      'completedTasks': 'पूर्ण कार्य',
      'addTask': 'कार्य जोड़ें',
      'priority': 'प्राथमिकता',
      'high': 'उच्च',
      'medium': 'मध्यम',
      'low': 'कम',
      'dueToday': 'आज देय',
      'dueTomorrow': 'कल देय',
      'overdue': 'बकाया',
      'completed': 'पूर्ण',
      'pending': 'लंबित',
      'applyFertilizer': 'खाद डालें',
      'checkIrrigation': 'सिंचाई प्रणाली जांचें',
      'pestInspection': 'कीट निरीक्षण',
      'harvestWheat': 'गेहूं की कटाई',
      'soilTesting': 'मिट्टी परीक्षण',
      'waterPump': 'पानी का पंप',
      'pumpOn': 'चालू करें',
      'pumpOff': 'बंद करें',

      // Advisory Screen
      'advisoryAlerts': 'सलाह और अलर्ट',
      'alertMoistureTitle': 'नमी सीमा पहुँची',
      'alertMoistureDesc': 'नोड 1 ने मिट्टी की नमी 30% से कम रिपोर्ट की। सोलेनॉइड वाल्व स्वचालित रूप से चालू हुआ।',
      'alertDsvTitle': 'उच्च DSV चेतावनी',
      'alertDsvDesc': 'दक्षिण प्लॉट में रोग गंभीरता मान 4.5 तक बढ़ गया है। कृपया निरीक्षण के लिए Tier-2 Edge Scanner का उपयोग करें।',
      'alertStableTitle': 'खेत स्वास्थ्य स्थिर',
      'alertStableDesc': 'सभी नोड्स स्थिर माइक्रोक्लाइमेट रिपोर्ट कर रहे हैं। तत्काल कोई कार्रवाई आवश्यक नहीं।',
      'twoMinsAgo': '2 मिनट पहले',
      'oneHourAgo': '1 घंटा पहले',
      'yesterday': 'कल',

      // Market Screen
      'marketOverview': 'बाज़ार का अवलोकन',
      'todayPrices': 'आज के भाव',
      'priceAlerts': 'मूल्य अलर्ट',
      'trending': 'ट्रेंडिंग',
      'perQuintal': 'प्रति क्विंटल',
      'perKg': 'प्रति किलो',
      'priceUp': 'भाव बढ़ा',
      'priceDown': 'भाव गिरा',
      'noChange': 'कोई बदलाव नहीं',
      'buyNow': 'अभी खरीदें',
      'sellNow': 'अभी बेचें',
      'commodities': 'वस्तुएं',
      'grains': 'अनाज',
      'vegetables': 'सब्जियां',
      'fruits': 'फल',

      // Disease Detection Screen
      'aiPoweredDetection': 'Edge AI पहचान (Tier-2)',
      'detectDiseaseDesc': 'ऑन-डिवाइस Edge AI स्कैनिंग से पौधों के रोगों की तुरंत पहचान करें',
      'chooseDetectionMethod': 'स्कैनर विकल्प',
      'takePhoto': 'Edge AI से स्कैन करें',
      'usePhoneCamera': 'अपने फोन कैमरे का उपयोग करें (Tier-2 Scout)',
      'howItWorks': 'यह कैसे काम करता है',
      'captureImage': 'छवि कैप्चर करें',
      'captureImageDesc': 'प्रभावित पौधे या पत्ती की फोटो लें',
      'aiAnalysis': 'ऑन-डिवाइस AI विश्लेषण',
      'aiAnalysisDesc': 'YOLOv8-Nano मॉडल स्थानीय रूप से छवि का विश्लेषण करता है',
      'getResults': 'परिणाम प्राप्त करें',
      'getResultsDesc': 'निदान और उपचार की सिफारिशें प्राप्त करें',

      // Camera Detection Screen
      'noImageSelected': 'कोई छवि चयनित नहीं',
      'takePhotoOrSelect': 'फोटो लें या गैलरी से चुनें',
      'chooseFromGallery': 'गैलरी से चुनें',
      'analyzeImage': 'छवि का विश्लेषण करें',
      'analyzing': 'स्थानीय रूप से विश्लेषण हो रहा है...',
      'retake': 'फिर से लें',
      'remove': 'हटाएं',
      'tipsForBestResults': 'Tier-2 स्कैनिंग के टिप्स',
      'tip1': 'कैमरे को पत्ती से 10-15 सेमी दूर रखें',
      'tip2': 'विशेष रूप से पत्तियों के निचले हिस्से पर ध्यान दें',
      'tip3': 'स्पष्ट छवियों के लिए अच्छी रोशनी सुनिश्चित करें',
      'tip4': 'धुंधली या हिलती हुई फोटो से बचें',
      'replace': 'बदलें',

      // Analysis Result Screen
      'analysisResult': 'विश्लेषण परिणाम',
      'diseaseDetected': 'रोग पाया गया',
      'droneImage': 'ड्रोन छवि',
      'cameraPhoto': 'कैमरा फोटो',
      'confidence': 'विश्वास',
      'severity': 'गंभीरता',
      'affected': 'प्रभावित',
      'moderate': 'मध्यम',
      'mild': 'हल्का',
      'severe': 'गंभीर',
      'symptoms': 'लक्षण',
      'recommendedTreatment': 'अनुशंसित उपचार',
      'preventionTips': 'रोकथाम के टिप्स',
      'backToHome': 'होम पर वापस',
      'scanAnother': 'एक और स्कैन करें',
      'reportSaved': 'रिपोर्ट सहेजी गई!',

      // Disease names and descriptions
      'Alternaria': 'अल्टरनेरिया (Alternaria)',
      'Fungal Spot': 'फंगल स्पॉट (Fungal Spot)',
      'Bacterial Blight': 'बैक्टीरियल ब्लाइट / तेळ्या',
      'Healthy': 'स्वस्थ (Healthy)',
      'leafBlight': 'पत्ती झुलसा रोग',
      'leafBlightScientific': 'अल्टरनेरिया अल्टरनेटा',
      'leafBlightDesc':
          'पत्ती झुलसा एक आम फफूंदी रोग है जो पत्तियों पर भूरे धब्बे और पीलापन पैदा करता है। यह आर्द्र परिस्थितियों में तेजी से फैलता है और इलाज न होने पर फसल की उपज को काफी कम कर सकता है।',
      'symptom1': 'पत्तियों पर भूरे अनियमित धब्बे',
      'symptom2': 'धब्बों के चारों ओर पीले घेरे',
      'symptom3': 'पत्ती का मुड़ना और मुरझाना',
      'symptom4': 'समय से पहले पत्ता गिरना',
      'treatment1': 'फफूंदनाशक अनुप्रयोग',
      'treatment1Desc': 'हर 7-10 दिनों में तांबा-आधारित फफूंदनाशक लगाएं',
      'treatment2': 'संक्रमित पत्तियां हटाएं',
      'treatment2Desc': 'संक्रमित पौधे के हिस्सों को काटें और निपटान करें',
      'treatment3': 'हवा का संचार बेहतर करें',
      'treatment3Desc': 'आर्द्रता कम करने के लिए पौधों को ठीक से रखें',
      'treatment4': 'पानी प्रबंधन',
      'treatment4Desc': 'ऊपर से पानी देने से बचें, मिट्टी के स्तर पर पानी दें',
      'prevention1': 'फसलों को सालाना घुमाएं',
      'prevention2': 'रोग-प्रतिरोधी किस्मों का उपयोग करें',
      'prevention3': 'उचित पौधे की दूरी बनाए रखें',
      'prevention4': 'फसल के बाद पौधे के मलबे को हटाएं',
    },

    // Gujarati translations
    'gu': {
      // App name and general
      'appName': 'સ્માર્ટખેતી',
      'settings': 'સેટિંગ્સ',
      'language': 'ભાષા',
      'selectLanguage': 'ભાષા પસંદ કરો',
      'english': 'English',
      'hindi': 'हिंदी',
      'gujarati': 'ગુજરાતી',
      'comingSoon': 'ટૂંક સમયમાં આવી રહ્યું છે — કાર્ય પ્રગતિ પર',

      // Navigation
      'home': 'હોમ',
      'myFarm': 'મારું ખેતર',
      'tasks': 'કાર્યો',
      'market': 'સલાહ',
      'farmMap': 'ખેતરનો નકશો',
      'liveScan': 'લાઇવ સ્કેન',
      'alerts': 'ચેતવણીઓ',
      'analytics': 'એનાલિટિક્સ',
      'farmAnalytics': 'ખેતર વિશ્લેષણ',

      // Irrigation
      'irrigationControl': 'સ્માર્ટ સિંચાઈ',
      'manualMode': 'મેન્યુઅલ',
      'recommendedMode': 'ભલામણ',
      'automaticMode': 'સ્વચાલિત',
      'irrigateNow': 'હમણાં સિંચાઈ કરો',
      'delayIrrigation': 'સિંચાઈ મુલતવી રાખો',
      'soilMoistureOptimal': 'જમીનમાં ભેજ યોગ્ય છે',
      'soilSaturated': 'જમીન વધુ પડતી ભીની છે',
      'sensorFault': 'સેન્સરમાં ખામી',
      'approveAndStart': 'મંજૂર કરો અને શરૂ કરો',
      'emergencyStop': 'ઇમરજન્સી સ્ટોપ',
      'targetMoisture': 'લક્ષ્ય ભેજ',
      'flowRate': 'પ્રવાહ દર',
      'failsafeActive': 'સેફ્ટી ટાઈમર સક્રિય',
      'safetyLockedWetLeaf': 'સુરક્ષા લૉક: પાંદડા ભીના છે',

      // Farm Map & Zoning
      'virtualZones': 'વર્ચ્યુઅલ ઝોન',
      'zoneOverview': 'ઝોન આરોગ્ય સ્થિતિ',
      'scoutedHealthy': 'તપાસમાં સ્વસ્થ',
      'scoutedDisease': 'રોગના લક્ષણો મળ્યા',
      'liveHardwareNode': 'લાઇવ હાર્ડવેર નોડ',
      'pendingScout': 'તપાસ બાકી',
      'inspectZone': 'ઝોનની વિગત જુઓ',
      'pomegranate': 'દાડમ',
      'pomegranateBhagwa': 'દાડમ (ભગવા)',

      // Mode Switcher
      'farmerMode': 'ખેડૂત મોડ',
      'expertMode': 'નિષ્ણાત મોડ',
      'modeSimpleTooltip': 'ખેડૂતો માટે સરળ દૃશ્ય',
      'modeExpertTooltip': 'નિષ્ણાતો માટે વિગતવાર સેન્સર ડેટા',

      // Farmer Mode Simple Strings
      'everythingGreat': 'બધું બરાબર છે! 🌿',
      'everythingGreatDesc': 'જમીનમાં સારો ભેજ છે અને હવામાન સાફ છે. આજે પાણીની જરૂર નથી.',
      'soilThirsty': 'જમીનને પાણી જોઈએ છે 💧',
      'soilThirstyDesc': 'જમીન સુકાઈ રહી છે. આજે તમારા દાડમના ઝાડને પાણી આપો.',
      'holdWatering': 'સિંચાઈ રોકો 🌧️',
      'holdWateringDesc': 'પાંદડા ભીના છે. રોગથી બચવા હમણાં પાણી ન આપો.',
      'checkingSensors': 'સેન્સર ચકાસી રહ્યાં છીએ... 📡',
      'checkingSensorsDesc': 'સેન્સર સાથે જોડાઈ રહ્યાં છીએ. કૃપા કરીને નોડ 1 તપાસો.',
      'startWateringNow': 'પાણી શરૂ કરો (30 મિનિટ)',
      'scanLeavesNow': 'પાંદડામાં રોગ તપાસો',
      'waterField': 'ખેતરમાં પાણી આપો',
      'seeFarmMap': 'ખેતરનો નકશો જુઓ',
      'advisoryAlertsSimple': 'પાક સલાહ અને ચેતવણી',
      'soilHealthy': 'ભેજ યોગ્ય છે',
      'soilDry': 'સૂકી / પાણી જોઈએ',
      'cropProtected': 'પાક સુરક્ષિત અને સ્વસ્થ',
      'cropCheck': 'પાંદડા તપાસો',

      // Home Screen
      'goodMorning': 'સુપ્રભાત',
      'goodAfternoon': 'શુભ બપોર',
      'goodEvening': 'શુભ સાંજ',
      'farmThriving': 'તમારું ખેતર ખીલી રહ્યું છે. આજના કાર્યો માટે તૈયાર છો?',
      'weather': 'Microclimate (Node 1)',
      'farmHealth': 'ખેતરનું સ્વાસ્થ્ય',
      'good': 'સારું',
      'excellent': 'ઉત્તમ',
      'partlyCloudy': 'આંશિક વાદળો',
      'sunny': 'તડકો',
      'rainy': 'વરસાદ',
      'allSystemsGood': 'બધી સિસ્ટમ્સ સારી છે',
      'leafWetness': 'પાન ભીનાશ',
      'dsv': 'રોગ ગંભીરતા મૂલ્ય (DSV)',
      'nodeConnected': 'નોડ જોડાયેલ (BLE)',
      'nodeDisconnected': 'નોડ વિચ્છેદ',
      'solenoidValve': '12V સોલેનોઇડ વાલ્વ',
      'plots': 'પ્લોટ',
      'autoIrrigation': 'ઓટો-સિંચાઈ',
      'farmTools': 'ખેતીના સાધનો',
      'diseaseDetection': 'રોગ ઓળખ',
      'cropCare': 'પાક સંભાળ',
      'irrigation': 'સિંચાઈ',
      'soilHealth': 'જમીનનું સ્વાસ્થ્ય',
      'marketPrices': 'બજાર ભાવ',
      'pestControl': 'જીવાત નિયંત્રણ',

      // My Farm Screen
      'farmOverview': 'ખેતર અવલોકન',
      'totalArea': 'કુલ વિસ્તાર',
      'acres': 'એકર',
      'activeCrops': 'સક્રિય પાક',
      'crops': 'પાક',
      'waterUsage': 'પાણીનો ઉપયોગ',
      'liters': 'લીટર',
      'yourPlots': 'તમારા પ્લોટ',
      'healthy': 'સ્વસ્થ',
      'needsAttention': 'ધ્યાન જરૂરી',
      'viewDetails': 'વિગતો જુઓ',
      'addPlot': 'પ્લોટ ઉમેરો',
      'wheat': 'ઘઉં',
      'rice': 'ચોખા',
      'cotton': 'કપાસ',
      'sugarcane': 'શેરડી',
      'tomato': 'ટામેટા',
      'potato': 'બટાકા',
      'onion': 'ડુંગળી',
      'groundnut': 'મગફળી',
      'northField': 'ઉત્તર ખેતર',
      'southPlot': 'દક્ષિણ પ્લોટ',
      'openValve': 'વાલ્વ ખોલો',
      'autoTriggerDesc': 'જમીનની ભેજ 30% થી ઓછી થાય ત્યારે સ્વચાલિત',
      'planted': 'વાવેતર',
      'harvestIn': 'લણણીમાં',
      'days': 'દિવસ',

      // Tasks Screen
      'todaysTasks': 'આજના કાર્યો',
      'upcomingTasks': 'આગામી કાર્યો',
      'completedTasks': 'પૂર્ણ કાર્યો',
      'addTask': 'કાર્ય ઉમેરો',
      'priority': 'અગ્રતા',
      'high': 'ઉચ્ચ',
      'medium': 'મધ્યમ',
      'low': 'ઓછી',
      'dueToday': 'આજે બાકી',
      'dueTomorrow': 'આવતીકાલે બાકી',
      'overdue': 'વિલંબિત',
      'completed': 'પૂર્ણ',
      'pending': 'બાકી',
      'applyFertilizer': 'ખાતર નાખો',
      'checkIrrigation': 'સિંચાઈ સિસ્ટમ તપાસો',
      'pestInspection': 'જીવાત તપાસ',
      'harvestWheat': 'ઘઉંની લણણી',
      'soilTesting': 'જમીન પરીક્ષણ',
      'waterPump': 'પાણીનો પંપ',
      'pumpOn': 'ચાલુ કરો',
      'pumpOff': 'બંધ કરો',

      // Advisory Screen
      'advisoryAlerts': 'સલાહ અને ચેતવણીઓ',
      'alertMoistureTitle': 'ભેજ સીમા પહોંચી',
      'alertMoistureDesc': 'નોડ 1 એ જમીનની ભેજ 30% થી ઓછી રિપોર્ટ કરી. સોલેનોઇડ વાલ્વ આપમેળે ચાલુ થયો.',
      'alertDsvTitle': 'ઉચ્ચ DSV ચેતવણી',
      'alertDsvDesc': 'દક્ષિણ પ્લોટમાં રોગ ગંભીરતા મૂલ્ય 4.5 સુધી વધ્યો છે. કૃપા કરી તપાસ માટે Tier-2 Edge Scanner નો ઉપયોગ કરો.',
      'alertStableTitle': 'ખેતર સ્વાસ્થ્ય સ્થિર',
      'alertStableDesc': 'બધા નોડ્સ સ્થિર માઇક્રોક્લાઇમેટ રિપોર્ટ કરી રહ્યા છે. તાત્કાલિક કોઈ કાર્યવાહી જરૂરી નથી.',
      'twoMinsAgo': '2 મિનિટ પહેલાં',
      'oneHourAgo': '1 કલાક પહેલાં',
      'yesterday': 'ગઈકાલે',

      // Market Screen
      'marketOverview': 'બજાર અવલોકન',
      'todayPrices': 'આજના ભાવ',
      'priceAlerts': 'ભાવ ચેતવણી',
      'trending': 'ટ્રેન્ડિંગ',
      'perQuintal': 'પ્રતિ ક્વિન્ટલ',
      'perKg': 'પ્રતિ કિલો',
      'priceUp': 'ભાવ વધ્યો',
      'priceDown': 'ભાવ ઘટ્યો',
      'noChange': 'કોઈ ફેરફાર નથી',
      'buyNow': 'અત્યારે ખરીદો',
      'sellNow': 'અત્યારે વેચો',
      'commodities': 'કોમોડિટીઝ',
      'grains': 'અનાજ',
      'vegetables': 'શાકભાજી',
      'fruits': 'ફળો',

      // Disease Detection Screen
      'aiPoweredDetection': 'Edge AI ઓળખ (Tier-2)',
      'detectDiseaseDesc': 'ઓન-ડિવાઈસ Edge AI સ્કેનિંગથી છોડના રોગોની તુરંત ઓળખ કરો',
      'chooseDetectionMethod': 'સ્કેનર વિકલ્પો',
      'takePhoto': 'Edge AI થી સ્કેન કરો',
      'usePhoneCamera': 'તમારા ફોન કેમેરાનો ઉપયોગ કરો (Tier-2 Scout)',
      'howItWorks': 'આ કેવી રીતે કામ કરે છે',
      'captureImage': 'છબી કેપ્ચર કરો',
      'captureImageDesc': 'અસરગ્રસ્ત છોડ અથવા પાનનો ફોટો લો',
      'aiAnalysis': 'ઓન-ડિવાઈસ AI વિશ્લેષણ',
      'aiAnalysisDesc': 'YOLOv8-Nano મોડેલ સ્થાનિક રીતે છબીનું વિશ્લેષણ કરે છે',
      'getResults': 'પરિણામ મેળવો',
      'getResultsDesc': 'નિદાન અને સારવારની ભલામણો મેળવો',

      // Camera Detection Screen
      'noImageSelected': 'કોઈ છબી પસંદ નથી',
      'takePhotoOrSelect': 'ફોટો લો અથવા ગેલેરીમાંથી પસંદ કરો',
      'chooseFromGallery': 'ગેલેરીમાંથી પસંદ કરો',
      'analyzeImage': 'છબીનું વિશ્લેષણ કરો',
      'analyzing': 'સ્થાનિક રીતે વિશ્લેષણ થઈ રહ્યું છે...',
      'retake': 'ફરીથી લો',
      'remove': 'દૂર કરો',
      'tipsForBestResults': 'Tier-2 સ્કેનિંગ માટે ટિપ્સ',
      'tip1': 'કેમેરાને પાનથી 10-15 સેમી દૂર રાખો',
      'tip2': 'ખાસ કરીને પાનના નીચેના ભાગ પર ધ્યાન આપો',
      'tip3': 'સ્પષ્ટ છબીઓ માટે સારી લાઇટિંગ સુનિશ્ચિત કરો',
      'tip4': 'ઝાંખા અથવા હલતા ફોટા ટાળો',
      'replace': 'બદલો',

      // Analysis Result Screen
      'analysisResult': 'વિશ્લેષણ પરિણામ',
      'diseaseDetected': 'રોગ મળ્યો',
      'droneImage': 'ડ્રોન છબી',
      'cameraPhoto': 'કેમેરા ફોટો',
      'confidence': 'વિશ્વાસ',
      'severity': 'ગંભીરતા',
      'affected': 'અસરગ્રસ્ત',
      'moderate': 'મધ્યમ',
      'mild': 'હળવું',
      'severe': 'ગંભીર',
      'symptoms': 'લક્ષણો',
      'recommendedTreatment': 'ભલામણ કરેલ સારવાર',
      'preventionTips': 'નિવારણ ટિપ્સ',
      'backToHome': 'હોમ પર પાછા',
      'scanAnother': 'બીજું સ્કેન કરો',
      'reportSaved': 'રિપોર્ટ સેવ થયો!',

      // Disease names and descriptions
      'Alternaria': 'અલ્ટરનેરિયા (Alternaria)',
      'Fungal Spot': 'ફંગલ સ્પોટ (Fungal Spot)',
      'Bacterial Blight': 'બેક્ટેરિયલ બ્લાઇટ / તેલિયા',
      'Healthy': 'તંદુરસ્ત (Healthy)',
      'leafBlight': 'પાન ઝુલસા રોગ',
      'leafBlightScientific': 'અલ્ટરનેરિયા અલ્ટરનેટા',
      'leafBlightDesc':
          'પાનનો ઝુલસો એક સામાન્ય ફૂગ રોગ છે જે પાન પર ભૂરા ડાઘ અને પીળાશ પેદા કરે છે. તે ભેજવાળી પરિસ્થિતિમાં ઝડપથી ફેલાય છે અને સારવાર ન થાય તો પાકની ઉપજ નોંધપાત્ર રીતે ઘટાડી શકે છે.',
      'symptom1': 'પાન પર ભૂરા અનિયમિત ડાઘ',
      'symptom2': 'ડાઘની આસપાસ પીળા વર્તુળો',
      'symptom3': 'પાન વળવું અને સુકાવું',
      'symptom4': 'સમય પહેલાં પાન ખરવું',
      'treatment1': 'ફૂગનાશક ઉપયોગ',
      'treatment1Desc': 'દર 7-10 દિવસે તાંબા-આધારિત ફૂગનાશક લગાવો',
      'treatment2': 'ચેપગ્રસ્ત પાન દૂર કરો',
      'treatment2Desc': 'ચેપગ્રસ્ત છોડના ભાગો કાપો અને નિકાલ કરો',
      'treatment3': 'હવાનું પરિભ્રમણ સુધારો',
      'treatment3Desc': 'ભેજ ઘટાડવા છોડને યોગ્ય રીતે ગોઠવો',
      'treatment4': 'પાણી વ્યવસ્થાપન',
      'treatment4Desc': 'ઉપરથી પાણી આપવાનું ટાળો, જમીન સ્તરે પાણી આપો',
      'prevention1': 'વાર્ષિક પાક ફેરવો',
      'prevention2': 'રોગ-પ્રતિરોધક જાતોનો ઉપયોગ કરો',
      'prevention3': 'યોગ્ય છોડ અંતર જાળવો',
      'prevention4': 'લણણી પછી છોડનો કચરો દૂર કરો',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Getters for all strings
  String get appName => translate('appName');
  String get settings => translate('settings');
  String get language => translate('language');
  String get selectLanguage => translate('selectLanguage');
  String get english => translate('english');
  String get hindi => translate('hindi');
  String get gujarati => translate('gujarati');
  String get comingSoon => translate('comingSoon');

  // Navigation
  String get home => translate('home');
  String get myFarm => translate('myFarm');
  String get tasks => translate('tasks');
  String get market => translate('market');
  String get farmMap => translate('farmMap');
  String get liveScan => translate('liveScan');
  String get alerts => translate('alerts');
  String get analytics => translate('analytics');
  String get farmAnalytics => translate('farmAnalytics');

  // Irrigation
  String get irrigationControl => translate('irrigationControl');
  String get manualMode => translate('manualMode');
  String get recommendedMode => translate('recommendedMode');
  String get automaticMode => translate('automaticMode');
  String get irrigateNow => translate('irrigateNow');
  String get delayIrrigation => translate('delayIrrigation');
  String get soilMoistureOptimal => translate('soilMoistureOptimal');
  String get soilSaturated => translate('soilSaturated');
  String get sensorFault => translate('sensorFault');
  String get approveAndStart => translate('approveAndStart');
  String get emergencyStop => translate('emergencyStop');
  String get targetMoisture => translate('targetMoisture');
  String get flowRate => translate('flowRate');
  String get failsafeActive => translate('failsafeActive');
  String get safetyLockedWetLeaf => translate('safetyLockedWetLeaf');

  // Farm Map & Zoning
  String get virtualZones => translate('virtualZones');
  String get zoneOverview => translate('zoneOverview');
  String get scoutedHealthy => translate('scoutedHealthy');
  String get scoutedDisease => translate('scoutedDisease');
  String get liveHardwareNode => translate('liveHardwareNode');
  String get pendingScout => translate('pendingScout');
  String get inspectZone => translate('inspectZone');
  String get pomegranate => translate('pomegranate');
  String get pomegranateBhagwa => translate('pomegranateBhagwa');

  // Mode Switcher
  String get farmerMode => translate('farmerMode');
  String get expertMode => translate('expertMode');
  String get modeSimpleTooltip => translate('modeSimpleTooltip');
  String get modeExpertTooltip => translate('modeExpertTooltip');

  // Farmer Mode Simple Strings
  String get everythingGreat => translate('everythingGreat');
  String get everythingGreatDesc => translate('everythingGreatDesc');
  String get soilThirsty => translate('soilThirsty');
  String get soilThirstyDesc => translate('soilThirstyDesc');
  String get holdWatering => translate('holdWatering');
  String get holdWateringDesc => translate('holdWateringDesc');
  String get checkingSensors => translate('checkingSensors');
  String get checkingSensorsDesc => translate('checkingSensorsDesc');
  String get startWateringNow => translate('startWateringNow');
  String get scanLeavesNow => translate('scanLeavesNow');
  String get waterField => translate('waterField');
  String get seeFarmMap => translate('seeFarmMap');
  String get advisoryAlertsSimple => translate('advisoryAlertsSimple');
  String get soilHealthy => translate('soilHealthy');
  String get soilDry => translate('soilDry');
  String get cropProtected => translate('cropProtected');
  String get cropCheck => translate('cropCheck');

  // Home Screen
  String get goodMorning => translate('goodMorning');
  String get goodAfternoon => translate('goodAfternoon');
  String get goodEvening => translate('goodEvening');
  String get farmThriving => translate('farmThriving');
  String get weather => translate('weather');
  String get farmHealth => translate('farmHealth');
  String get good => translate('good');
  String get excellent => translate('excellent');
  String get partlyCloudy => translate('partlyCloudy');
  String get sunny => translate('sunny');
  String get rainy => translate('rainy');
  String get allSystemsGood => translate('allSystemsGood');
  String get plots => translate('plots');
  String get autoIrrigation => translate('autoIrrigation');
  String get farmTools => translate('farmTools');
  String get diseaseDetection => translate('diseaseDetection');
  String get cropCare => translate('cropCare');
  String get irrigation => translate('irrigation');
  String get soilHealth => translate('soilHealth');
  String get marketPrices => translate('marketPrices');
  String get pestControl => translate('pestControl');

  // My Farm Screen
  String get farmOverview => translate('farmOverview');
  String get totalArea => translate('totalArea');
  String get acres => translate('acres');
  String get activeCrops => translate('activeCrops');
  String get crops => translate('crops');
  String get waterUsage => translate('waterUsage');
  String get liters => translate('liters');
  String get yourPlots => translate('yourPlots');
  String get healthy => translate('healthy');
  String get needsAttention => translate('needsAttention');
  String get viewDetails => translate('viewDetails');
  String get addPlot => translate('addPlot');
  String get wheat => translate('wheat');
  String get rice => translate('rice');
  String get cotton => translate('cotton');
  String get sugarcane => translate('sugarcane');
  String get tomato => translate('tomato');
  String get potato => translate('potato');
  String get onion => translate('onion');
  String get groundnut => translate('groundnut');
  String get northField => translate('northField');
  String get southPlot => translate('southPlot');
  String get openValve => translate('openValve');
  String get autoTriggerDesc => translate('autoTriggerDesc');
  String get planted => translate('planted');
  String get harvestIn => translate('harvestIn');
  String get days => translate('days');

  // Tasks Screen
  String get todaysTasks => translate('todaysTasks');
  String get upcomingTasks => translate('upcomingTasks');
  String get completedTasks => translate('completedTasks');
  String get addTask => translate('addTask');
  String get priority => translate('priority');
  String get high => translate('high');
  String get medium => translate('medium');
  String get low => translate('low');
  String get dueToday => translate('dueToday');
  String get dueTomorrow => translate('dueTomorrow');
  String get overdue => translate('overdue');
  String get completed => translate('completed');
  String get pending => translate('pending');
  String get applyFertilizer => translate('applyFertilizer');
  String get checkIrrigation => translate('checkIrrigation');
  String get pestInspection => translate('pestInspection');
  String get harvestWheat => translate('harvestWheat');
  String get soilTesting => translate('soilTesting');
  String get waterPump => translate('waterPump');
  String get pumpOn => translate('pumpOn');
  String get pumpOff => translate('pumpOff');

  // Advisory Screen
  String get advisoryAlerts => translate('advisoryAlerts');
  String get alertMoistureTitle => translate('alertMoistureTitle');
  String get alertMoistureDesc => translate('alertMoistureDesc');
  String get alertDsvTitle => translate('alertDsvTitle');
  String get alertDsvDesc => translate('alertDsvDesc');
  String get alertStableTitle => translate('alertStableTitle');
  String get alertStableDesc => translate('alertStableDesc');
  String get twoMinsAgo => translate('twoMinsAgo');
  String get oneHourAgo => translate('oneHourAgo');
  String get yesterday => translate('yesterday');

  // Market Screen
  String get marketOverview => translate('marketOverview');
  String get todayPrices => translate('todayPrices');
  String get priceAlerts => translate('priceAlerts');
  String get trending => translate('trending');
  String get perQuintal => translate('perQuintal');
  String get perKg => translate('perKg');
  String get priceUp => translate('priceUp');
  String get priceDown => translate('priceDown');
  String get noChange => translate('noChange');
  String get buyNow => translate('buyNow');
  String get sellNow => translate('sellNow');
  String get commodities => translate('commodities');
  String get grains => translate('grains');
  String get vegetables => translate('vegetables');
  String get fruits => translate('fruits');

  // Home & Node Getters
  String get leafWetness => translate('leafWetness');
  String get dsv => translate('dsv');
  String get nodeConnected => translate('nodeConnected');
  String get nodeDisconnected => translate('nodeDisconnected');
  String get solenoidValve => translate('solenoidValve');

  // Disease Detection Screen
  String get aiPoweredDetection => translate('aiPoweredDetection');
  String get aiDetectionDesc => translate('detectDiseaseDesc');
  String get detectDiseaseDesc => translate('detectDiseaseDesc');
  String get chooseDetectionMethod => translate('chooseDetectionMethod');
  String get takePhoto => translate('takePhoto');
  String get takePhotoDesc => translate('usePhoneCamera');
  String get usePhoneCamera => translate('usePhoneCamera');
  String get howItWorks => translate('howItWorks');
  String get captureImage => translate('captureImage');
  String get captureImageDesc => translate('captureImageDesc');
  String get aiAnalysis => translate('aiAnalysis');
  String get aiAnalysisDesc => translate('aiAnalysisDesc');
  String get getResults => translate('getResults');
  String get getResultsDesc => translate('getResultsDesc');

  // Camera Detection Screen
  String get noImageSelected => translate('noImageSelected');
  String get takePhotoOrSelect => translate('takePhotoOrSelect');
  String get chooseFromGallery => translate('chooseFromGallery');
  String get analyzeImage => translate('analyzeImage');
  String get analyzing => translate('analyzing');
  String get retake => translate('retake');
  String get remove => translate('remove');
  String get tipsForBestResults => translate('tipsForBestResults');
  String get tip1 => translate('tip1');
  String get tip2 => translate('tip2');
  String get tip3 => translate('tip3');
  String get tip4 => translate('tip4');
  String get replace => translate('replace');

  // Analysis Result Screen
  String get analysisResult => translate('analysisResult');
  String get diseaseDetected => translate('diseaseDetected');
  String get droneImage => translate('droneImage');
  String get cameraPhoto => translate('cameraPhoto');
  String get confidence => translate('confidence');
  String get severity => translate('severity');
  String get affected => translate('affected');
  String get moderate => translate('moderate');
  String get mild => translate('mild');
  String get severe => translate('severe');
  String get symptoms => translate('symptoms');
  String get recommendedTreatment => translate('recommendedTreatment');
  String get preventionTips => translate('preventionTips');
  String get backToHome => translate('backToHome');
  String get scanAnother => translate('scanAnother');
  String get reportSaved => translate('reportSaved');

  // Disease
  String get leafBlight => translate('leafBlight');
  String get leafBlightScientific => translate('leafBlightScientific');
  String get leafBlightDesc => translate('leafBlightDesc');
  String get symptom1 => translate('symptom1');
  String get symptom2 => translate('symptom2');
  String get symptom3 => translate('symptom3');
  String get symptom4 => translate('symptom4');
  String get treatment1 => translate('treatment1');
  String get treatment1Desc => translate('treatment1Desc');
  String get treatment2 => translate('treatment2');
  String get treatment2Desc => translate('treatment2Desc');
  String get treatment3 => translate('treatment3');
  String get treatment3Desc => translate('treatment3Desc');
  String get treatment4 => translate('treatment4');
  String get treatment4Desc => translate('treatment4Desc');
  String get prevention1 => translate('prevention1');
  String get prevention2 => translate('prevention2');
  String get prevention3 => translate('prevention3');
  String get prevention4 => translate('prevention4');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'gu'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
