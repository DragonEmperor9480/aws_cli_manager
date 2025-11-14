import 'package:flutter/material.dart';

class AppTheme {
  // Kiro-inspired brand colors
  static const Color primaryPurple = Color(0xFF6366F1); // Kiro purple
  static const Color primaryBlue = Color(0xFF3B82F6); // Kiro blue
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentPink = Color(0xFFEC4899);
  
  // Service colors
  static const Color iamColor = Color(0xFF8B5CF6); // Purple
  static const Color s3Color = Color(0xFF10B981); // Green
  static const Color cloudwatchColor = Color(0xFFF59E0B); // Amber
  static const Color settingsColor = Color(0xFF6366F1); // Indigo
  
  // Additional service colors
  static const Color ec2Color = Color(0xFFEF4444); // Red
  static const Color lambdaColor = Color(0xFFF97316); // Orange
  static const Color rdsColor = Color(0xFF14B8A6); // Teal
  static const Color vpcColor = Color(0xFF3B82F6); // Blue
  
  // Neutral colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  
  // Status colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundLight,
      cardTheme: const CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: borderColor),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardBackground,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryPurple,
          side: const BorderSide(color: primaryPurple),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
    );
  }
}
