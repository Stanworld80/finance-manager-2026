import 'package:flutter/material.dart';

enum AppStyle { defaults, banking, sky, pastel }

class AppTheme {
  static ThemeData getTheme(AppStyle style, Brightness brightness) {
    Color seedColor;

    switch (style) {
      case AppStyle.defaults:
        seedColor = Colors.blue;
        break;
      case AppStyle.banking:
        seedColor = const Color(0xFF0D47A1); // Deep Navy Blue
        break;
      case AppStyle.sky:
        seedColor = const Color(0xFF03A9F4); // Light Blue
        break;
      case AppStyle.pastel:
        seedColor = const Color(0xFFF48FB1); // Pink Pastel
        break;
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: brightness,
          ).copyWith(
            // Ensure high contrast for secondary text in dark mode
            onSurfaceVariant: brightness == Brightness.dark
                ? Colors
                      .grey
                      .shade200 // Brighter for dark mode
                : Colors.grey.shade700,
          ),
      // Enhance with aesthetics
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: brightness == Brightness.dark
            ? null
            : ColorScheme.fromSeed(seedColor: seedColor).primaryContainer,
      ),
      textTheme: const TextTheme(
        bodySmall: TextStyle(letterSpacing: 0.4),
        labelSmall: TextStyle(letterSpacing: 0.5),
      ),
    );
  }

  // Legacy accessors keeping default blue for now if needed,
  // but ideally we switch to using the provider.
  static ThemeData get lightTheme =>
      getTheme(AppStyle.defaults, Brightness.light);
  static ThemeData get darkTheme =>
      getTheme(AppStyle.defaults, Brightness.dark);
}
