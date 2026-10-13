import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'MedAlert';

  static const Color redDark = Color(0xFF8B0000);
  static const Color redPrimary = Color(0xFFD7263D);
  static const Color redBright = Color(0xFFFF4D4D);
  static const Color redDeep = Color(0xFF6A040F);

  static const Color primaryColor = redPrimary;
  static const Color dangerColor = redPrimary;
  static const Color warningColor = Color(0xFFF4A259);

  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [redDeep, redPrimary, redBright],
  );

  static BoxDecoration gradientBox({double radius = 16}) => BoxDecoration(
        gradient: redGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: redPrimary.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static const List<String> appointmentTypes = [
    'Checkup',
    'Vaccination',
    'Prenatal',
    'Dental',
  ];

  static const List<String> announcementCategories = [
    'general',
    'outbreak',
    'vaccination_drive',
    'schedule_change',
  ];
}
