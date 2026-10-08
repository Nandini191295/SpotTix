import 'package:flutter/material.dart';

class AppColors {
  // ✅ Your existing theme colors (unchanged)
  static const Color purple = Color.fromRGBO(138, 0, 255, 1);
  static const Color lightBackground = Color.fromRGBO(242, 231, 254, 1);

  // ✅ Common UI Colors (added)
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70; 

  // Optional secondary/accent colors (use if needed in project)
  static const Color secondary = Color.fromRGBO(0, 180, 216, 1); // teal-blue
  static const Color accent = Color.fromRGBO(255, 107, 107, 1); // soft red/pink

  // ✅ Text Colors
  static const Color textPrimary = Color.fromRGBO(30, 30, 30, 1);     // near black
  static const Color textSecondary = Color.fromRGBO(107, 114, 128, 1); // grey

  // ✅ Success / Status Colors (for KYC, badges, etc.)
  static const Color success = Color.fromRGBO(76, 175, 80, 1);          // green
  static const Color successLight = Color.fromRGBO(224, 238, 224, 1);   // light green bg

  // ✅ Rating star color
  static const Color star = Colors.amberAccent;

  // ✅ Shadow
  static const Color shadow = Colors.black12;
}
