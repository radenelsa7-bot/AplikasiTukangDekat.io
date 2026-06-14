import 'package:flutter/material.dart';

class AppTheme {
  // 1. Definisikan variabel warna terlebih dahulu di sini
  static const Color navy = Color(0xFF0A192F);
  static const Color cream = Color(0xFFF7F0E3);
  static const Color orange = Color(0xFFFF6B35);
  static const Color white = Colors.white;
  static const Color seed = navy;

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: navy,
        onPrimary: white,
        secondary: orange,
        onSecondary: white,
        surface: cream,
        onSurface: navy,
        background: cream,
        onBackground: navy,
        error: Colors.red,
        onError: white,
        tertiary: orange,
        onTertiary: white,
      ),
      scaffoldBackgroundColor: cream,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: navy,
        foregroundColor: white,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: navy,
        displayColor: navy,
      ),
    );
  }
}
