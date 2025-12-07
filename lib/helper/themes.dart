import 'package:flutter/material.dart';

// Helper to generate theme-related properties from a base color.
class ThemeHelper {
  final Color accentColor;

  ThemeHelper(this.accentColor);

  /// Generates a lighter or slightly hue-shifted color from the base accent color.
  Color get lightAccent {
    final hsl = HSLColor.fromColor(accentColor);
    // Increase lightness by 15%. Clamp between 0.0 and 1.0.
    final lighterHsl =
        hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0));
    return lighterHsl.toColor();
  }

  /// A primary gradient using the accent color.
  LinearGradient get primaryGradient => LinearGradient(
        colors: [accentColor, lightAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// A decoration for creating a "glassmorphism" effect.
  /// Note: This requires a Stack with a BackdropFilter for the blur effect.
  /// This decoration provides the semi-transparent background color.
  BoxDecoration get glassBackgroundDecoration => BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30), // For nav bar
      );

  /// A palette of colors derived from the accent color for use in charts.
  List<Color> get chartColors => [
        accentColor,
        lightAccent,
        HSLColor.fromColor(accentColor)
            .withSaturation((HSLColor.fromColor(accentColor).saturation - 0.2)
                .clamp(0.0, 1.0))
            .toColor(),
        HSLColor.fromColor(accentColor)
            .withHue((HSLColor.fromColor(accentColor).hue + 30.0) % 360.0)
            .toColor(),
        HSLColor.fromColor(accentColor)
            .withLightness((HSLColor.fromColor(accentColor).lightness - 0.1)
                .clamp(0.0, 1.0))
            .toColor(),
      ];
}

class AppTheme {
  static final Color _seedColor = Colors.deepPurple;
  static final Color _darkSeedColor = Colors.teal;

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor:
        const Color(0xFFE0E5EC), // Soft light background for neomorphism
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    cardTheme: CardThemeData(
      elevation: 0, // Neomorphism has no elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: const Color(0xFFE0E5EC),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor:
        const Color(0xFF2C2F33), // Darker background for neomorphism
    colorScheme: ColorScheme.fromSeed(
      seedColor: _darkSeedColor,
      brightness: Brightness.dark,
    ),
    cardTheme: CardThemeData(
      elevation: 0, // Neomorphism has no elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: const Color(0xFF2C2F33),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
