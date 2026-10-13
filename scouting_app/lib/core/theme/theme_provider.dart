import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);

  void toggleTheme() {
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
    } else if (state == ThemeMode.dark) {
      state = ThemeMode.light;
    } else {
      // If it's system, we switch to the opposite of what the system currently is.
      // But for simplicity in a toggle, we can just force it to one or the other.
      // A better way is to explicitly set light or dark.
      state = ThemeMode.dark; // Defaulting to dark if toggling from system initially
    }
  }

  void setTheme(ThemeMode mode) {
    state = mode;
  }
}
