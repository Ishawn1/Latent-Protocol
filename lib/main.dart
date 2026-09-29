import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/disease_detection/live_detection_screen.dart';
import 'screens/farm_map_screen.dart';
import 'screens/irrigation_screen.dart';
import 'screens/farm_analytics_screen.dart';
import 'widgets/esp32_status_sheet.dart';
import 'l10n/app_localizations.dart';
import 'services/esp_ap_polling_service.dart';
import 'services/alert_notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

void handleNotificationAction(String payload) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Pop any open modal bottom sheets or pushed secondary screens back to MainScreen
    navigatorKey.currentState?.popUntil((route) => route.isFirst);

    if (payload == 'action_irrigate') {
      mainScreenKey.currentState?.switchTab(3);
    } else if (payload == 'action_inspect') {
      mainScreenKey.currentState?.switchTab(1);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlertNotificationService.instance.initialize(
    onAction: (payload) {
      handleNotificationAction(payload);
    },
  );
  runApp(const SmartKhetiApp());
}

class SmartKhetiApp extends StatefulWidget {
  const SmartKhetiApp({super.key});

  static void setLocale(BuildContext context, Locale locale) {
    final state = context.findAncestorStateOfType<_SmartKhetiAppState>();
    state?.setLocale(locale);
  }

  @override
  State<SmartKhetiApp> createState() => _SmartKhetiAppState();
}

class _SmartKhetiAppState extends State<SmartKhetiApp> {
  Locale _locale = const Locale('en');

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'SmartKheti',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: _locale,
      supportedLocales: const [
        Locale('en'), // English
        Locale('hi'), // Hindi
        Locale('gu'), // Gujarati
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: NoScrollbarBehavior(),
          child: child!,
        );
      },
      home: MainScreen(key: mainScreenKey),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final Set<int> _loadedTabs = {0};
  final _pollingService = EspApPollingService.instance;

  @override
  void initState() {
    super.initState();
    // Start polling the ESP32 AP immediately on launch.
    // Safe to call even if phone is not yet connected to the ESP32 Wi-Fi —
    // it will keep retrying until the farmer connects.
    _pollingService.startPolling();
    _pollingService.addListener(_onPollingUpdate);

    // Register notification deep-link handler and flush any cold-start pending actions
    AlertNotificationService.instance.setActionHandler(handleNotificationAction);
  }

  void switchTab(int index) {
    _onTabTapped(index);
  }

  @override
  void dispose() {
    _pollingService.removeListener(_onPollingUpdate);
    _pollingService.stopPolling();
    super.dispose();
  }

  void _onPollingUpdate() {
    if (mounted) setState(() {});
  }

  Widget _buildScreen(int index) {
    if (!_loadedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return LiveDetectionScreen(
          isActive: _currentIndex == 1,
          onBackToHome: () => setState(() => _currentIndex = 0),
        );
      case 2:
        return const FarmMapScreen();
      case 3:
        return const IrrigationScreen();
      case 4:
        return const FarmAnalyticsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _loadedTabs.add(index);
    });
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const LanguageSelectorSheet(),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.user, color: AppColors.primaryGreen, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suresh Bhai',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Kharva, Gujarat • Field Node 1',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.borderLight),
              const SizedBox(height: 12),
              _buildProfileRow(LucideIcons.user, 'Farmer Name', 'Suresh Bhai'),
              _buildProfileRow(LucideIcons.mapPin, 'Village / Location', 'Kharva, Gujarat'),
              _buildProfileRow(LucideIcons.sprout, 'Farm Name', 'Bhagwa Orchard Block 1'),
              _buildProfileRow(LucideIcons.trees, 'Primary Crop', 'Pomegranate (Bhagwa Variety)'),
              _buildProfileRow(LucideIcons.map, 'Farm Size', '3.5 Acres (Drip Irrigated)'),
              _buildProfileRow(LucideIcons.cpu, 'IoT Hub', 'ESP32-S3 Node 1 (Online)'),
              _buildProfileRow(LucideIcons.shieldCheck, 'Edition', 'SIH 2026 Edge AI Prototype'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Farmer-facing banner shown when the ESP32 AP is not yet reachable.
  Widget _buildConnectionBanner({
    required bool isReconnecting,
    required String errorHint,
  }) {
    final color = isReconnecting ? AppColors.accentOrange : AppColors.primaryGreen;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _PulsingDot(color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReconnecting
                      ? 'Reconnecting to field unit\u2026'
                      : 'Connect to SmartKheti Wi-Fi',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isReconnecting
                      ? 'Move closer to the field unit or check power.'
                      : 'Go to Wi-Fi Settings \u2192 tap \u201cSmartKheti-Node1\u201d',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!isReconnecting)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                        'Open Wi-Fi Settings on your phone and connect to SmartKheti-Node1'),
                    backgroundColor: AppColors.primaryGreen,
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(
                      label: 'OK',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              child: const Text('How?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _currentIndex == 0
          ? AppBar(
              backgroundColor: AppColors.cardBackground,
              elevation: 0,
              title: Text(
                l10n.appName,
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                // Language Selector Button
                _buildAppBarButton(
                  icon: LucideIcons.languages,
                  onPressed: _showLanguageSelector,
                  tooltip: 'Change Language',
                ),
                // ESP32 Hardware Diagnostics
                _buildAppBarButton(
                  icon: LucideIcons.cpu,
                  onPressed: () => Esp32StatusSheet.show(context),
                  tooltip: 'Node Status',
                ),
                // Profile Details
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _buildAppBarButton(
                    icon: LucideIcons.user,
                    onPressed: () => _showProfileSheet(context),
                    tooltip: 'Farmer Profile',
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: AppColors.borderLight,
                  height: 1,
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          // ── Farmer connection banner ────────────────────────────────────
          // Shows ONLY on Home tab when the phone is not yet connected to the SmartKheti Wi-Fi AP.
          if (_currentIndex == 0)
            ListenableBuilder(
              listenable: _pollingService,
              builder: (context, _) {
                if (_pollingService.isConnected) return const SizedBox.shrink();
                final hasEverConnected = (_pollingService.totalPacketsReceived > 0);
                return _buildConnectionBanner(
                  isReconnecting: hasEverConnected,
                  errorHint: _pollingService.lastError,
                );
              },
            ),
          // ── Main tab screens ────────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: List.generate(5, _buildScreen),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(l10n),
    );
  }

  Widget _buildAppBarButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.iconBackground,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Icon(
            icon,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: LucideIcons.home,
                label: l10n.home,
                index: 0,
              ),
              _buildNavItem(
                icon: LucideIcons.scan,
                label: l10n.liveScan,
                index: 1,
              ),
              _buildNavItem(
                icon: LucideIcons.map,
                label: l10n.farmMap,
                index: 2,
              ),
              _buildNavItem(
                icon: LucideIcons.droplets,
                label: l10n.irrigation,
                index: 3,
              ),
              _buildNavItem(
                icon: LucideIcons.barChart3,
                label: l10n.analytics,
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentOrange.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color:
                  isActive ? AppColors.accentOrange : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color:
                    isActive ? AppColors.accentOrange : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Language Selector Bottom Sheet
class LanguageSelectorSheet extends StatelessWidget {
  const LanguageSelectorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.languages,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.selectLanguage,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderLight),
          // Language Options
          _buildLanguageOption(
            context: context,
            code: 'en',
            name: 'English',
            nativeName: 'English',
            flag: '🇺🇸',
          ),
          _buildLanguageOption(
            context: context,
            code: 'hi',
            name: 'Hindi',
            nativeName: 'हिंदी',
            flag: '🇮🇳',
          ),
          _buildLanguageOption(
            context: context,
            code: 'gu',
            name: 'Gujarati',
            nativeName: 'ગુજરાતી',
            flag: '🇮🇳',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String code,
    required String name,
    required String nativeName,
    required String flag,
  }) {
    final currentLocale = Localizations.localeOf(context);
    final isSelected = currentLocale.languageCode == code;

    return InkWell(
      onTap: () {
        SmartKhetiApp.setLocale(context, Locale(code));
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.farmHealthBg : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppColors.borderLight.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nativeName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Animated pulsing dot used in the connection status banner.
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
