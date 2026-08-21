import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../utils/constants.dart';

/// Service to handle all Google AdMob operations (Interstitial + Banner Ads)
class AdService {
  // Singleton instance
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // State
  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isBannerAdLoaded => _isBannerAdLoaded;

  // Callbacks
  Function()? onInterstitialAdLoaded;
  Function(String error)? onInterstitialAdFailed;
  Function()? onInterstitialAdDismissed;
  Function()? onBannerAdLoaded;
  Function(String error)? onBannerAdFailed;

  // ═══════════════════════════════════════════
  // INITIALIZE SDK
  // ═══════════════════════════════════════════

  /// Initialize the Google Mobile Ads SDK.
  ///
  /// Requests App Tracking Transparency permission first. Apple requires the
  /// prompt to appear before any tracking data is collected, so the ads SDK is
  /// not touched until it resolves. Every path that starts ads goes through
  /// this method, which keeps the prompt on a single chokepoint.
  ///
  /// Must be called once the app is on screen — iOS silently discards the
  /// request while the app is still launching, which is why this is called
  /// from SplashController and not from main().
  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('AdService: Already initialized');
      return;
    }

    await _requestTrackingPermission();

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdService: Initialized successfully');
    } catch (e) {
      debugPrint('AdService: Failed to initialize - $e');
    }
  }

  /// Show the iOS tracking prompt if the user has not answered it yet.
  ///
  /// Apple only allows the prompt to be shown once, so this is a no-op after
  /// the first answer. No-op on Android, where the framework does not exist.
  /// Failures are swallowed: ads must still initialize if the prompt breaks.
  Future<void> _requestTrackingPermission() async {
    if (!Platform.isIOS) return;

    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status != TrackingStatus.notDetermined) {
        debugPrint('AdService: ATT already answered - $status');
        return;
      }

      // A short pause lets the splash screen finish presenting. Without it the
      // request can land while the app is still becoming active, and iOS drops
      // it without showing anything.
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final result = await AppTrackingTransparency.requestTrackingAuthorization();
      debugPrint('AdService: ATT result - $result');
    } catch (e) {
      debugPrint('AdService: ATT request failed - $e');
    }
  }

  // ═══════════════════════════════════════════
  // INTERSTITIAL AD
  // ═══════════════════════════════════════════

  /// Load an interstitial ad
  /// Call this to pre-load the next ad
  Future<void> loadInterstitialAd() async {
    debugPrint('AdService: loadInterstitialAd() called, isInitialized: $_isInitialized');

    if (!_isInitialized) {
      debugPrint('AdService: Cannot load ad - SDK not initialized');
      return;
    }

    // No usable interstitial unit configured — see AdUnitIds. Requesting one
    // anyway just fails with "Ad unit doesn't match format" on every launch.
    if (!AdUnitIds.isInterstitialConfigured) {
      debugPrint('AdService: Interstitial disabled - no interstitial ad unit configured');
      return;
    }

    // Don't load if one is already loaded
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      debugPrint('AdService: Interstitial ad already loaded');
      return;
    }

    await InterstitialAd.load(
      adUnitId: AdUnitIds.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AdService: Interstitial ad loaded');
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;

          // Set up full screen content callbacks
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('AdService: Interstitial ad dismissed');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
              onInterstitialAdDismissed?.call();
              // Pre-load next ad
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdService: Interstitial ad failed to show - ${error.message}');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
              // Try to load another ad
              loadInterstitialAd();
            },
          );

          onInterstitialAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: Interstitial ad failed to load - ${error.message}');
          _isInterstitialAdLoaded = false;
          _interstitialAd = null;
          onInterstitialAdFailed?.call(error.message);
        },
      ),
    );
  }

  /// Show the interstitial ad if loaded
  /// Returns true if ad was shown, false otherwise
  Future<bool> showInterstitialAd() async {
    if (!_isInterstitialAdLoaded || _interstitialAd == null) {
      debugPrint('AdService: No interstitial ad ready to show');
      return false;
    }

    try {
      await _interstitialAd!.show();
      debugPrint('AdService: Interstitial ad shown');
      return true;
    } catch (e) {
      debugPrint('AdService: Failed to show interstitial ad - $e');
      return false;
    }
  }

  /// Dispose the interstitial ad
  Future<void> disposeInterstitialAd() async {
    await _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdLoaded = false;
  }

  // ═══════════════════════════════════════════
  // BANNER AD
  // ═══════════════════════════════════════════

  /// Load a banner ad
  Future<void> loadBannerAd() async {
    debugPrint('AdService: loadBannerAd() called, isInitialized: $_isInitialized');

    if (!_isInitialized) {
      debugPrint('AdService: Cannot load banner ad - SDK not initialized');
      return;
    }

    // Don't load if one is already loaded
    if (_isBannerAdLoaded && _bannerAd != null) {
      debugPrint('AdService: Banner ad already loaded');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: AdUnitIds.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('AdService: Banner ad loaded');
          _isBannerAdLoaded = true;
          onBannerAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdService: Banner ad failed to load - ${error.message}');
          ad.dispose();
          _bannerAd = null;
          _isBannerAdLoaded = false;
          onBannerAdFailed?.call(error.message);
        },
      ),
    );

    await _bannerAd!.load();
  }

  /// Get the banner ad widget if loaded
  Widget? getBannerAdWidget() {
    if (!_isBannerAdLoaded || _bannerAd == null) {
      return null;
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  /// Dispose the banner ad
  Future<void> disposeBannerAd() async {
    await _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  // ═══════════════════════════════════════════
  // DISPOSE
  // ═══════════════════════════════════════════

  /// Dispose all ads and clean up
  Future<void> dispose() async {
    await disposeInterstitialAd();
    await disposeBannerAd();
    _isInitialized = false;
    debugPrint('AdService: Disposed');
  }
}
