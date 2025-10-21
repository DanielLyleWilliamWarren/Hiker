import 'package:flutter/material.dart';

/// Application color palette
/// Define all brand and UI colors in one place for consistent use throughout the app
class AppColors {
  // Primary Colors
  static const Color primaryEarth = Color(0xFF002E40);
  static const Color primaryStone = Color(0xFFAD9C70);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color primaryBlack = Color(0xFF000000);

  // Alternate Colors
  static const Color alternate = Color(0xFF505050);
  static const Color alternateDisabled = Color(0xFFB5B5B5);

  // Secondary Colors - Nature Palette
  static const Color secondaryLichen = Color(0xFF99B096);
  static const Color secondarySky = Color(0xFF7391BF);
  static const Color secondarySea = Color(0xFF528791);
  static const Color secondaryGrass = Color(0xFF8CB052);
  static const Color secondaryHaze = Color(0xFFD48080);

  // Secondary Colors - Earth Palette
  static const Color secondaryClay = Color(0xFFB87D33);
  static const Color secondaryAmber = Color(0xFFF0A845);
  static const Color secondarySand = Color(0xFFC4BD9C);
  static const Color secondaryRock = Color(0xFFA8A8A1);
  static const Color secondaryEarth = Color(0xFF998A82);
  static const Color secondarySlate = Color(0xFF808082);

  // Secondary Color - Accent
  static const Color secondaryRed = Color(0xFFEB5757);

  // Monochrome Colors
  static const Color monoBlack = Color(0xFF252525);
  static const Color monoGrey1 = Color(0xFFE1E1E1);
  static const Color monoGrey2 = Color(0xFFE5E5E5);
  static const Color monoGrey3 = Color(0xFFB5B5B5);
  static const Color monoGrey4 = Color(0xFF505050);

  // State Colors
  static const Color stateSuccess = Color(0xFF007B40);
  static const Color stateError = Color(0xFFF03D3E);
  static const Color stateWarn = Color(0xFFF0A845);
}

/// Extension method to easily access colors from BuildContext
extension AppColorsExtension on BuildContext {
  AppColors get colors => AppColors();
}

// Usage examples:
// 
// Direct access:
// Container(color: AppColors.primaryEarth)
//
// With context extension:
// Container(color: context.colors.primaryEarth)
//
// In TextStyle:
// Text('Hello', style: TextStyle(color: AppColors.primaryStone))