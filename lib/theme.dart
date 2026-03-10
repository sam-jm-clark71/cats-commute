import 'package:flutter/material.dart';

class AppTheme {
  static const Color sage = Color(0xFF7B9E87);
  static const Color sageLight = Color(0xFFD4E6DA);
  static const Color sageDark = Color(0xFF4A6B55);
  static const Color warmWhite = Color(0xFFF9F7F4);
  static const Color softGrey = Color(0xFF8A8A8A);

  static const Color cycleGreen = Color(0xFF4A7C59);
  static const Color tubeBlue = Color(0xFF003B8E);
  static const Color unclearAmber = Color(0xFFC8892B);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: sage,
          brightness: Brightness.light,
          surface: warmWhite,
        ),
        scaffoldBackgroundColor: warmWhite,
        appBarTheme: const AppBarTheme(
          backgroundColor: warmWhite,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE8E8E8), width: 1),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF555555),
            height: 1.5,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            color: Color(0xFF8A8A8A),
            letterSpacing: 0.4,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: sage,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: sageDark,
            side: const BorderSide(color: sage, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      );
}
