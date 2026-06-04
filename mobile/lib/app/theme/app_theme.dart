import 'package:flutter/material.dart';

class AppTheme {
  // 1. Definisikan variabel warna terlebih dahulu di sini
  static const Color navy = Color(0xFF0A192F);   // Ganti dengan kode Hex navy Anda
  static const Color white = Colors.white;        // Menggunakan warna putih bawaan Flutter
  static const Color orange = Color(0xFFFF6B35); // Ganti dengan kode Hex orange Anda
  static const Color seed = Color(0xFF0A192F);   // Ganti dengan warna utama/seed Anda

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
      colorScheme: ColorScheme.fromSeed(seedColor: seed),
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}