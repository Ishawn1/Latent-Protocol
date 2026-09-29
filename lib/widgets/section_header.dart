import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A consistent section header used throughout the app.
///
/// Displays an icon + title row in the primary green style.
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final double fontSize;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.color,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primaryGreen;
    return Row(
      children: [
        Icon(icon, size: 20, color: effectiveColor),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              color: effectiveColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
