import 'package:flutter/material.dart';

const kDarkBackground = Color(0xFF1C1C1E);
const kCardBackground = Color(0xFF2C2C2E);

// Game Launcher Theme Colors
class GameColors {
  // Background gradient colors
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color primaryMid = Color(0xFF2D2D44);
  static const Color primaryLight = Color(0xFF3D3D5C);

  // Accent colors
  static const Color gold = Color(0xFFFFD700);
  static const Color orange = Color(0xFFFF8C00);
  static const Color green = Color(0xFF4CAF50);
  static const Color greenDark = Color(0xFF2E7D32);
  static const Color blue = Color(0xFF2196F3);
  static const Color blueDark = Color(0xFF1565C0);
  static const Color purple = Color(0xFF9C27B0);
  static const Color pink = Color(0xFFE91E63);
  static const Color red = Color(0xFFE53935);
  static const Color cyan = Color(0xFF00BCD4);

  // UI colors
  static const Color cardGreen = Color(0xFF43A047);
  static const Color cardBlue = Color(0xFF1E88E5);
  static const Color cardPurple = Color(0xFF7B1FA2);
  static const Color cardOrange = Color(0xFFFF9800);

  // Coin/gem colors
  static const Color coinYellow = Color(0xFFFFEB3B);
  static const Color gemPink = Color(0xFFFF4081);

  // Gradient for background
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A2E),
      Color(0xFF2D2351),
      Color(0xFF1A1A2E),
    ],
  );

  // Card gradients
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF66BB6A), Color(0xFF43A047), Color(0xFF2E7D32)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF42A5F5), Color(0xFF1E88E5), Color(0xFF1565C0)],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2), Color(0xFF6A1B9A)],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB74D), Color(0xFFFF9800), Color(0xFFF57C00)],
  );
}

final appDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: kDarkBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: kDarkBackground,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: kCardBackground,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: kDarkBackground,
  ),
  sliderTheme: const SliderThemeData(
    activeTrackColor: Colors.blue,
    thumbColor: Colors.blue,
    inactiveTrackColor: Colors.grey,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.blue;
      return Colors.grey;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.blue.withValues(alpha: 0.5);
      }
      return Colors.grey.withValues(alpha: 0.3);
    }),
  ),
);
