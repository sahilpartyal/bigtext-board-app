import 'dart:io';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════
// LEGAL URLs
// ═══════════════════════════════════════════
// Required by App Store Guideline 3.1.2: both links must be reachable from the
// screen where a subscription is purchased, and both must match the URLs
// entered in App Store Connect.
class LegalUrls {
  static const String privacyPolicy = 'https://sahilpartyal.github.io/bigtext-privacy/';

  // Apple's standard EULA. Permitted in place of writing our own terms.
  static const String termsOfUse =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
}

// ═══════════════════════════════════════════
// AD UNIT IDs
// ═══════════════════════════════════════════
class AdUnitIds {
  // Test IDs for development (safe to use, won't violate policies)
  static const String testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const String testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const String testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';

  // Production IDs (replace with your real IDs from AdMob console)
  //
  // NOTE: prodInterstitialIos currently points at the *banner* unit, because
  // no interstitial unit exists in the AdMob account yet. AdMob rejects that
  // request with "Ad unit doesn't match format", so interstitials are disabled
  // via isInterstitialConfigured below. Create an Interstitial ad unit in the
  // AdMob console, paste its ID here, and interstitials switch back on by
  // themselves — no other code needs to change.
  static const String prodInterstitialIos = 'ca-app-pub-3514291097789357/5685681330';
  static const String prodInterstitialAndroid = '';
  static const String prodBannerIos = 'ca-app-pub-3514291097789357/5685681330';
  static const String prodBannerAndroid = 'ca-app-pub-3514291097789357/8512670592';

  // TODO: Change to false for production release
  static const bool isTestMode = false;

  // Helper to get the correct interstitial ID based on platform and environment
  static String get interstitialAdUnitId {
    if (Platform.isIOS) {
      return isTestMode ? testInterstitialIos : prodInterstitialIos;
    } else {
      return isTestMode ? testInterstitialAndroid : prodInterstitialAndroid;
    }
  }

  // Helper to get the correct banner ID based on platform and environment
  static String get bannerAdUnitId {
    if (Platform.isIOS) {
      return isTestMode ? testBannerIos : prodBannerIos;
    } else {
      return isTestMode ? testBannerAndroid : prodBannerAndroid;
    }
  }

  /// Whether a usable interstitial ad unit is configured for this platform.
  ///
  /// Guards against two states that make every interstitial request fail:
  /// an empty ID (Android has none), and an ID that is really the banner unit
  /// (iOS today). Both produce errors on every launch and never show an ad,
  /// so it is better not to ask at all.
  ///
  /// Fills itself in: paste a real interstitial unit ID above and this returns
  /// true again.
  static bool get isInterstitialConfigured {
    final id = interstitialAdUnitId;
    if (id.isEmpty) return false;
    // A single AdMob unit only serves one format, so an ID shared with the
    // banner cannot also be an interstitial. Test IDs are exempt — Google's
    // demo units are genuinely distinct per format.
    if (!isTestMode && id == bannerAdUnitId) return false;
    return true;
  }
}

// ═══════════════════════════════════════════
// PRODUCT IDs (In-App Purchases)
// ═══════════════════════════════════════════
class ProductIds {
  // iOS product IDs (App Store Connect)
  static const String _monthlyIos = 'bigtext_pro_month_';
  static const String _yearlyIos = 'bigtext_pro_year_';

  // Android product IDs (Google Play Console)
  static const String _monthlyAndroid = 'bigtext_pro_month_';
  static const String _yearlyAndroid = 'bigtext_pro_year_';

  // Lifetime is the same on both platforms
  static const String lifetime = 'bigtext_pro_lifetime';

  // Platform-specific getters
  static String get monthly => Platform.isIOS ? _monthlyIos : _monthlyAndroid;
  static String get yearly => Platform.isIOS ? _yearlyIos : _yearlyAndroid;

  static Set<String> get all => {monthly, yearly, lifetime};
  static Set<String> get subscriptions => {monthly, yearly};
}


enum SubscriptionType {
  free,
  monthly,
  yearly,
  lifetime;

  bool get isPro => this != free;

  static SubscriptionType fromProductId(String? productId) {
    if (productId == ProductIds.monthly) {
      return SubscriptionType.monthly;
    } else if (productId == ProductIds.yearly) {
      return SubscriptionType.yearly;
    } else if (productId == ProductIds.lifetime) {
      return SubscriptionType.lifetime;
    } else {
      return SubscriptionType.free;
    }
  }
}


class FreeTierLimits {
  static const int maxFonts = 4;
  static const int maxColors = 6;
  static const int maxRecentMessages = 10;
  static const bool canUseLogo = false;
  static const bool canUseBusinessMode = true;      // All modes FREE
  static const bool canUsePresentationMode = true;  // All modes FREE
  static const bool showAds = true;                 // Free users see ads
}

class ProTierLimits {
  static const int maxFonts = 12;
  static const int maxColors = 15;
  static const int maxRecentMessages = 50;
  static const bool canUseLogo = true;
  static const bool canUseBusinessMode = true;
  static const bool canUsePresentationMode = true;
  static const bool showAds = false;  // Pro users don't see ads
}

const kMaxRecentMessages = 50;
const kAutoSaveDebounceMs = 2000;
const kControlsHideSeconds = 3;

// Pinch-to-zoom bounds for the main display text. Kept identical to the font
// size sliders in the settings screen so the two controls agree.
const kMinDisplayFontSize = 20.0;
const kMaxDisplayFontSize = 300.0;

const kPresetColors = [
  // Basic
  Color(0xFFFFFFFF),  // 0: White
  Color(0xFF000000),  // 1: Black
  // Electric Sunset
  Color(0xFFFF3C00),  // 2: Electric Sunset - Orange Red
  Color(0xFFFF9A00),  // 3: Electric Sunset - Amber
  Color(0xFFFFE14D),  // 4: Electric Sunset - Yellow
  // Neon Ocean
  Color(0xFF0D3B8C),  // 5: Neon Ocean - Navy Blue
  Color(0xFF0070FF),  // 6: Neon Ocean - Blue
  Color(0xFF00C6FF),  // 7: Neon Ocean - Cyan
  Color(0xFF7FFFEF),  // 8: Neon Ocean - Mint
  // Tropical Pop
  Color(0xFFFF005C),  // 9: Tropical Pop - Hot Pink
  Color(0xFFA855F7),  // 10: Tropical Pop - Purple
  Color(0xFFCCFF00),  // 11: Tropical Pop - Lime
];

const kFontFamilies = [
  'Inter',
  'Roboto',
  'Merriweather',
  'Open Sans',
  'Lato',
  'Montserrat',
  'Poppins',
  'Playfair Display',
  'Oswald',
  'Nunito',
  'Bebas Neue',
  'Anton',
];

const kAllFontFamilies = [
  'Inter',
  'Roboto',
  'Merriweather',
  'Open Sans',
  'Lato',
  'Playfair Display',
  'Montserrat',
  'Oswald',
  'Raleway',
  'Poppins',
  'Nunito',
  'Ubuntu',
  'Bebas Neue',
  'Anton',
];
