import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Colors.blue,
      onPrimary: Colors.white,
      secondary: Colors.orange,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.blue,
      error: Colors.red,
      onError: Colors.white,
      tertiary: Colors.orange,
      onTertiary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}