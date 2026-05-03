import 'package:flutter/material.dart';

class AppStyles {
  // --- RENK PALETİ ---
  static const Color primaryGreen = Color(0xFF4A5D4E); // Ana Renk
  static const Color accentPeach = Color(0xFFE29578); // Vurgu Rengi
  static const Color softenerBlue = Color(0xFFEDF6F9); // Yumuşatıcı Renk
  static const Color textDeepBlue = Color(0xFF264653); // Metin Rengi

  // --- GENEL TEMA AYARLARI ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: softenerBlue,
      primaryColor: primaryGreen,

      // AppBar Teması
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // Buton Teması
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPeach,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // Giriş Alanları (TextField) Teması
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        labelStyle: const TextStyle(color: textDeepBlue),
      ),
    );
  }

  // --- ÖZEL TEXT STİLLERİ (Sayfalarda kullanmak için) ---
  static const TextStyle titleStyle = TextStyle(
    color: textDeepBlue,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle brandLogoStyle = TextStyle(
    color: Colors.white,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  );
}
