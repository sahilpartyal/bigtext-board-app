import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/services/ad_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../utils/constants.dart';

class SplashController extends GetxController {
  SplashController({required this.storageService});

  final StorageService storageService;
  final AdService _adService = AdService();

  @override
  void onReady() {
    super.onReady();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    // Wait for splash animation
    await Future<void>.delayed(const Duration(seconds: 2));

    // Check if user is Pro (no ads for Pro users)
    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool('isPro') ?? false;

    if (!isPro) {
      // Requests the App Tracking Transparency prompt, then starts the ads
      // SDK. The app is on screen by now, which is what iOS requires for the
      // prompt to appear at all.
      await _adService.init();

      // The interstitial has to be requested explicitly. Nothing else loads
      // one this early — AdProvider only runs once the home screen builds,
      // which is after this point.
      await _adService.loadInterstitialAd();

      // Only wait when an ad could actually arrive. With no interstitial unit
      // configured this loop would hold every launch on the splash for three
      // seconds waiting for something that is never coming.
      if (AdUnitIds.isInterstitialConfigured) {
        debugPrint('SplashController: Waiting for ad to load...');
        for (int i = 0; i < 6; i++) {
          if (_adService.isInterstitialAdLoaded) break;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    if (!isPro && _adService.isInterstitialAdLoaded) {
      // Show interstitial ad before navigating
      debugPrint('SplashController: Showing interstitial ad before home');

      // Set callback to navigate after ad is dismissed
      _adService.onInterstitialAdDismissed = () {
        debugPrint('SplashController: Ad dismissed, navigating to home');
        Get.offAllNamed(AppRoutes.home);
      };

      final shown = await _adService.showInterstitialAd();
      if (!shown) {
        // Ad failed to show, navigate directly
        debugPrint('SplashController: Ad not shown, navigating to home');
        Get.offAllNamed(AppRoutes.home);
      }
    } else {
      // Pro user or ad not ready, navigate directly
      debugPrint('SplashController: Navigating to home (isPro: $isPro, adReady: ${_adService.isInterstitialAdLoaded})');
      Get.offAllNamed(AppRoutes.home);
    }
  }
}
