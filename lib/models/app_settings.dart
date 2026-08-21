import 'package:flutter/material.dart';

import 'display_mode.dart';

enum LogoPosition {
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight;

  String get label {
    switch (this) {
      case LogoPosition.topLeft:
        return 'Top Left';
      case LogoPosition.topCenter:
        return 'Top Center';
      case LogoPosition.topRight:
        return 'Top Right';
      case LogoPosition.bottomLeft:
        return 'Bottom Left';
      case LogoPosition.bottomCenter:
        return 'Bottom Center';
      case LogoPosition.bottomRight:
        return 'Bottom Right';
    }
  }
}

class AppSettings {
  final DisplayMode displayMode;
  final String passengerName;
  final String companyName;
  final String fontFamily;
  final Color textColor;
  final Color backgroundColor;
  final bool showCompanyName;
  final bool showLogo;
  final bool hapticFeedback;
  final bool keepScreenAwake;
  final double companyNameFontSize;
  final double passengerNameFontSize;

  // Business mode extras
  final String subtitle;
  final Color subtitleColor;
  final String subtitleFontFamily;
  final double subtitleFontSize;
  final double titleFontSize;
  final Color titleColor;
  final LogoPosition logoPosition;
  final double logoScale;

  // Custom logo
  final String? customLogoBase64;

  // Presentation mode extras
  final double autoAdvanceSeconds;

  const AppSettings({
    this.displayMode = DisplayMode.simple,
    this.passengerName = '',
    this.companyName = '',
    this.fontFamily = 'Inter',
    this.textColor = const Color(0xFFFFE14D), // Electric Sunset Yellow - bright & visible
    this.backgroundColor = const Color(0xFF0A0F2C), // Neon Ocean Dark Blue
    this.showCompanyName = false,
    this.showLogo = false,
    this.hapticFeedback = true,
    this.keepScreenAwake = true,
    this.companyNameFontSize = 24.0,
    this.passengerNameFontSize = 100.0,
    this.subtitle = '',
    this.subtitleColor = const Color(0xFF7FFFEF), // Neon Ocean Mint
    this.subtitleFontFamily = 'Inter',
    this.subtitleFontSize = 32.0,
    this.titleFontSize = 80.0,
    this.titleColor = const Color(0xFF00C6FF), // Neon Ocean Cyan - super bright
    this.logoPosition = LogoPosition.topCenter,
    this.logoScale = 1.0,
    this.customLogoBase64,
    this.autoAdvanceSeconds = 5.0,
  });

  AppSettings copyWith({
    DisplayMode? displayMode,
    String? passengerName,
    String? companyName,
    String? fontFamily,
    Color? textColor,
    Color? backgroundColor,
    bool? showCompanyName,
    bool? showLogo,
    bool? hapticFeedback,
    bool? keepScreenAwake,
    double? companyNameFontSize,
    double? passengerNameFontSize,
    String? subtitle,
    Color? subtitleColor,
    String? subtitleFontFamily,
    double? subtitleFontSize,
    double? titleFontSize,
    Color? titleColor,
    LogoPosition? logoPosition,
    double? logoScale,
    String? Function()? customLogoBase64,
    double? autoAdvanceSeconds,
  }) {
    return AppSettings(
      displayMode: displayMode ?? this.displayMode,
      passengerName: passengerName ?? this.passengerName,
      companyName: companyName ?? this.companyName,
      fontFamily: fontFamily ?? this.fontFamily,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showCompanyName: showCompanyName ?? this.showCompanyName,
      showLogo: showLogo ?? this.showLogo,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      companyNameFontSize: companyNameFontSize ?? this.companyNameFontSize,
      passengerNameFontSize: passengerNameFontSize ?? this.passengerNameFontSize,
      subtitle: subtitle ?? this.subtitle,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      subtitleFontFamily: subtitleFontFamily ?? this.subtitleFontFamily,
      subtitleFontSize: subtitleFontSize ?? this.subtitleFontSize,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      titleColor: titleColor ?? this.titleColor,
      logoPosition: logoPosition ?? this.logoPosition,
      logoScale: logoScale ?? this.logoScale,
      customLogoBase64: customLogoBase64 != null ? customLogoBase64() : this.customLogoBase64,
      autoAdvanceSeconds: autoAdvanceSeconds ?? this.autoAdvanceSeconds,
    );
  }
}
