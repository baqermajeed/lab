import 'package:flutter/material.dart';

class AppColors {
  // ألوان عصرية وحديثة
  static const Color primary = Color(0xFF6366F1); // Indigo modern
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  
  static const Color secondary = Color(0xFF06B6D4); // Cyan modern
  static const Color secondaryLight = Color(0xFF22D3EE);
  
  static const Color background = Color(0xFFF8FAFC); // Light slate
  static const Color cardBackground = Colors.white;
  static const Color surfaceLight = Color(0xFFF1F5F9);
  
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color danger = Color(0xFFEF4444); // Red modern
  static const Color info = Color(0xFF3B82F6); // Blue
  
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color chipBackground = Color(0xFFEEF2FF);
  
  // تدرجات للخلفيات
  static const List<Color> backgroundGradient = [
    Color(0xFFF8FAFC),
    Color(0xFFEEF2FF),
    Color(0xFFE0E7FF),
  ];
  
  static const List<Color> cardGradient = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];
}

class UnitTypes {
  static const List<String> all = <String>[
    'zercon',
    'veneer',
    'e-max',
    'ceramic',
    'Custom Abutment',
    'Bar',
    'Pmma',
    'digital Scan body',
    'Finishing abutment',
    'Metal finishing',
    'Bar finishing',
    'Milling zircon',
    'Model printer',
    'Pmma printer',
    'Scan',
    'Opaque',
    'BMA',
    'DTX',
  ];
}

class AppText {
  static const String appTitle = 'مختبرات فرح';
  static const String casesTitle = 'الحالات المسجلة';
}

// إعدادات خارجية (املأها قبل البناء)
class AppConfig {
  // ضع رابط الويب آب من Apps Script هنا
  static const String webAppUrl = 'https://script.google.com/macros/s/AKfycbxoBRCaov5CWaHjyd-G9TKWDZovNTMF-zzIZP0gSet41ipxRdfgm_TGzzcJz2sevdjLtA/exec';
  // مفتاح بسيط للتحقق (?key=...)
  static const String webAppSecret = 'CHANGE_ME_SECRET_6kQ0tY4fD9rM1aZ7pB3xV2cN8uH5wJ0R3sT6yL1qP8';
}
