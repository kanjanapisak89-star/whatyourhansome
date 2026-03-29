import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  // Colors from the UI design
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color backgroundColor = Color(0xFF000000);
  static const Color cardBackground = Color(0xFF1A1A1A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF999999);
  static const Color accentGreen = Color(0xFF00D9A3);
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentGreen,
        surface: cardBackground,
      ),
      
      // Typography
      textTheme: TextTheme(
        // Post title
        headlineMedium: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          height: 1.3,
        ),
        // Post excerpt
        bodyLarge: TextStyle(
          fontSize: 14.sp,
          color: textSecondary,
          height: 1.5,
        ),
        // Author name
        bodyMedium: TextStyle(
          fontSize: 13.sp,
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        // Metadata (time, counts)
        bodySmall: TextStyle(
          fontSize: 12.sp,
          color: textSecondary,
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      
      // Icon theme
      iconTheme: IconThemeData(
        color: textSecondary,
        size: 20.sp,
      ),
      
      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardBackground,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11.sp),
        unselectedLabelStyle: TextStyle(fontSize: 11.sp),
      ),
    );
  }
}
