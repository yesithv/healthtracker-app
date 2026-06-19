import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0D48A0);
  static const Color backgroundColor = Color(0xFFF4F6F9);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      textTheme: GoogleFonts.interTextTheme(),
    );
  }
}
