import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/services/ad_service.dart';

// ═══════════════════════════════════════════
// AD STATE
// ═══════════════════════════════════════════

class AdState {
  final bool isInitialized;
  final bool isAdReady;
  final bool isBannerAdReady;
  final String? error;
  final int actionCount;

  const AdState({
    this.isInitialized = false,
    this.isAdReady = false,
    this.isBannerAdReady = false,
    this.error,
    this.actionCount = 0,
  });

  AdState copyWith({
    bool? isInitialized,
    bool? isAdReady,
    bool? isBannerAdReady,
    String? error,
    bool clearError = false,
    int? actionCount,
  }) {
    return AdState(
      isInitialized: isInitialized ?? this.isInitialized,
      isAdReady: isAdReady ?? this.isAdReady,
      isBannerAdReady: isBannerAdReady ?? this.isBannerAdReady,
      error: clearError ? null : (error ?? this.error),
      actionCount: actionCount ?? this.actionCount,
    );
  }
}

/// How many actions before showing an interstitial ad
/// Set to 1 for testing, change to 3+ for production
const int kActionsBeforeAd = 1;

// ═══════════════════════════════════════════
// AD PROVIDER
// ═══════════════════════════════════════════

final adProvider = NotifierProvider<AdNotifier, AdState>(AdNotifier.new);

class AdNotifier extends Notifier<AdState> {
  late final AdService _adService;

  @override
  AdState build() {
    _adService = AdService();
    _setupCallbacks();
    // Delay initialization to avoid reading uninitialized providers
    Future.microtask(() => _initializeIfNeeded());
    return const AdState();
  }

  void _setupCallbacks() {
    _adService.onInterstitialAdLoaded = () {
      state = state.copyWith(
        isAdReady: true,
        clearError: true,
      );
    };

    _adService.onInterstitialAdFailed = (error) {
      state = state.copyWith(
        isAdReady: false,
        error: error,
      );
    };

    _adService.onInterstitialAdDismissed = () {
      state = state.copyWith(isAdReady: false);
    };

    _adService.onBannerAdLoaded = () {
      state = state.copyWith(
        isBannerAdReady: true,
        clearError: true,
      );
    };

    _adService.onBannerAdFailed = (error) {
      state = state.copyWith(
        isBannerAdReady: false,
        error: error,
      );
    };
  }

  Future<void> _initializeIfNeeded() async {
    debugPrint('AdProvider: _initializeIfNeeded called');

    // Check if user is Pro directly from SharedPreferences
    // This avoids dependency on subscription provider during initialization
    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool('isPro') ?? false;

    if (isPro) {
      // Pro user - no ads needed
      debugPrint('AdProvider: User is Pro, skipping ad initialization');
      state = state.copyWith(isInitialized: true, isAdReady: false, isBannerAdReady: false);
      return;
    }

    // Free user - initialize and pre-load ads
    debugPrint('AdProvider: Free user, initializing ads');
    if (!_adService.isInitialized) {
      debugPrint('AdProvider: Initializing AdService');
      await _adService.init();
    }

    // Load banner ad
    await _adService.loadBannerAd();

    // Wait a moment for banner ad to load if not ready
    if (!_adService.isBannerAdLoaded) {
      debugPrint('AdProvider: Waiting for banner ad to load...');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Update state with current ad status
    state = state.copyWith(
      isInitialized: true,
      isBannerAdReady: _adService.isBannerAdLoaded,
    );
    debugPrint('AdProvider: Initialized, isBannerAdReady: ${_adService.isBannerAdLoaded}');
  }

  // ═══════════════════════════════════════════
  // PUBLIC METHODS
  // ═══════════════════════════════════════════

  /// Show interstitial ad if available
  /// Returns true if ad was shown, false otherwise
  Future<bool> showInterstitialAd() async {
    // Check if user is Pro
    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool('isPro') ?? false;
    if (isPro) return false;

    return await _adService.showInterstitialAd();
  }

  /// Track user action and show ad if threshold reached
  /// Call this at natural break points (e.g., closing settings, saving text)
  Future<bool> trackActionAndMaybeShowAd() async {
    debugPrint('AdProvider: trackActionAndMaybeShowAd called');

    // Check if user is Pro
    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool('isPro') ?? false;
    if (isPro) {
      debugPrint('AdProvider: User is Pro, skipping ad');
      return false;
    }

    final newCount = state.actionCount + 1;
    debugPrint('AdProvider: Action count: $newCount / $kActionsBeforeAd, isAdReady: ${state.isAdReady}');

    if (newCount >= kActionsBeforeAd && state.isAdReady) {
      // Reset counter and show ad
      debugPrint('AdProvider: Showing interstitial ad!');
      state = state.copyWith(actionCount: 0);
      return await _adService.showInterstitialAd();
    } else {
      // Just increment counter
      state = state.copyWith(actionCount: newCount);
      debugPrint('AdProvider: Counter incremented to $newCount');
      return false;
    }
  }

  /// Pre-load an interstitial ad
  Future<void> loadInterstitialAd() async {
    await _adService.loadInterstitialAd();
  }

  /// Load a banner ad
  Future<void> loadBannerAd() async {
    await _adService.loadBannerAd();
  }

  /// Get the banner ad widget if ready
  Widget? getBannerAdWidget() {
    return _adService.getBannerAdWidget();
  }

  /// Called when user becomes Pro - dispose ads
  Future<void> onUserBecamePro() async {
    await _adService.dispose();
    state = state.copyWith(
      isAdReady: false,
      isBannerAdReady: false,
      clearError: true,
    );
  }
}

// ═══════════════════════════════════════════
// CONVENIENCE PROVIDERS
// ═══════════════════════════════════════════

/// Check if interstitial ad is ready to show
final isInterstitialAdReadyProvider = Provider<bool>((ref) {
  final adState = ref.watch(adProvider);
  return adState.isAdReady;
});

/// Check if banner ad is ready to show
final isBannerAdReadyProvider = Provider<bool>((ref) {
  final adState = ref.watch(adProvider);
  return adState.isBannerAdReady;
});
