import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00FFFF);

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.grey[100],
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: primaryColor,
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    cardColor: Colors.white,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black87),
      titleMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    ),
    useMaterial3: true,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF121212),
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryColor,
      surface: Color(0xFF1E1E1E),
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardColor: const Color(0xFF1E1E1E),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    useMaterial3: true,
  );
}
