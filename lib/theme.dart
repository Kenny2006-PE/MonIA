import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales
  static const Color primaryDark = Color(0xFF0D1015); // Cooler dark background
  static const Color cardDark = Color(0xFF1E2128); // Cooler slightly lighter cards
  static const Color accentGreen = Color(0xFF10B981);
  
  // Colores secundarios
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color borderLight = Color(0xFF2A2D35); // Subtle border

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      primaryColor: accentGreen,
      
      // Configuración de texto
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
