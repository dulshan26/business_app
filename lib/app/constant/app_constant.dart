// lib/constants/app_constants.dart
import 'package:flutter/material.dart';

// App Colors
class AppColors {
  static const Color primary = Colors.teal;
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF757575);
  static const Color cardBackground = Colors.white;
  static const Color pendingStatus = Colors.orange;
  static const Color sentStatus = Colors.blue;
  static const Color cashCollectStatus = Colors.green;
  static const Color cancel = Colors.red;
  static const Color background = Color.fromARGB(192, 82, 81, 81);
}

// Text Styles
class AppTextStyles {
  static const TextStyle cardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle cardValue = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
}
