import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: navy,
      onPrimary: white,
      secondary: orange,
      onSecondary: white,
      surface: white,
      onSurface: navy,
      error: Colors.red,
      onError: white,
      tertiary: orange,
      onTertiary: white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed),
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}