// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Colori istituzionali AGESCI Bari 10 (Rosso primario, Blu secondario)
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color primaryRedDark = Color(0xFFEF5350);
  static const Color secondaryBlue = Color(0xFF1565C0);
  static const Color secondaryBlueDark = Color(0xFF42A5F5);

  // Colori distintivi per le Branche
  static const Color brancoYellow = Color(0xFFFBC02D); // L/C
  static const Color repartoGreen = Color(0xFF2E7D32); // E/G
  static const Color clanRed = Color(0xFFC62828);      // R/S
  static const Color cocaPurple = Color(0xFF6A1B9A);   // Comunità Capi

  // Stati semantici
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFEF6C00);
  static const Color error = Color(0xFFC62828);

  // Superfici Light & Dark
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Colors.white;
  static const Color darkBackground = Color(0xFF0F141C);
  static const Color darkSurface = Color(0xFF1A222D);
}