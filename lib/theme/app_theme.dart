import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primaryGreen = Color(0xFF0F5C40);
  static const Color accentGreen = Color(0xFF0B9C54);
  static const Color darkGreen = Color(0xFF285334);

  // Accent colors
  static const Color accentOrange = Color(0xFFFF8A00);
  static const Color accentOrangeHover = Color(0xFFE67A00);

  // Background colors
  static const Color background = Color(0xFFF4F6E5);
  static const Color cardBackground = Colors.white;
  static const Color iconBackground = Color(0xFFF2F0E6);

  // Weather card
  static const Color weatherCardBg = Color(0xFFF4F7F9);
  static const Color weatherTagBg = Color(0xFFFEF3C7);
  static const Color weatherTagText = Color(0xFFB45309);

  // Farm health card
  static const Color farmHealthBg = Color(0xFFF0FDF4);
  static const Color farmHealthTagBg = Color(0xFFDCFCE7);
  static const Color farmHealthTagText = Color(0xFF166534);

  // Water pump control
  static const Color waterPumpBg = Color(0xFFF0F4F8);
  static const Color waterPumpButton = Color(0xFF2563EB);

  // Task colors
  static const Color urgentBg = Color(0xFFFFF5F5);
  static const Color urgentBorder = Color(0xFFFCA5A5);
  static const Color urgentTagBg = Color(0xFFFFE4E6);
  static const Color urgentTagText = Color(0xFFE11D48);
  static const Color urgentText = Color(0xFFB91C1C);

  static const Color mediumTagBg = Color(0xFFFEF3C7);
  static const Color mediumTagText = Color(0xFFD97706);

  // Market colors
  static const Color gainBg = Color(0xFFECFDF5);
  static const Color gainBorder = Color(0xFFD1FAE5);
  static const Color gainText = Color(0xFF16A34A);
  static const Color gainDarkText = Color(0xFF166534);

  static const Color lossBg = Color(0xFFFFF1F2);
  static const Color lossBorder = Color(0xFFFFE4E6);
  static const Color lossText = Color(0xFFDC2626);
  static const Color lossDarkText = Color(0xFF9F1239);

  // Text colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Border colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderBlue = Color(0xFFBFDBFE);
  static const Color borderGreen = Color(0xFFBBF7D0);

  // Coming Soon / disabled
  static const Color disabledOverlay = Color(0x33000000);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
        secondary: AppColors.accentOrange,
        surface: AppColors.cardBackground,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: IconThemeData(color: AppColors.textSecondary),
        titleTextStyle: TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: AppColors.accentOrange,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

/// Custom scroll behavior to hide scrollbar.
class NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // No scrollbar
  }
}

/// Shows a "Coming Soon" SnackBar for WIP features.
void showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Row(
        children: [
          Icon(Icons.construction, color: Colors.white, size: 20),
          SizedBox(width: 12),
          Text('Coming Soon — Work in Progress'),
        ],
      ),
      backgroundColor: AppColors.accentOrange,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}
