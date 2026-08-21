import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/services/purchase_service.dart';
import '../utils/constants.dart';
import 'settings_provider.dart';

// ═══════════════════════════════════════════
// SUBSCRIPTION STATE
// ═══════════════════════════════════════════
class SubscriptionState {
  final bool isPro;
  final SubscriptionType subscriptionType;
  final bool isLoading;
  final bool isPurchasing;
  final String? error;
  final List<ProductDetails> products;

  const SubscriptionState({
    this.isPro = false,
    this.subscriptionType = SubscriptionType.free,
    this.isLoading = true,
    this.isPurchasing = false,
    this.error,
    this.products = const [],
  });

  /// Errors are sticky: they survive unrelated updates and are dropped only
  /// when [clearError] is passed. The previous version assigned `error: error`
  /// unconditionally, so any state change — a spinner starting, products
  /// arriving — silently erased the message the user needed to read.
  SubscriptionState copyWith({
    bool? isPro,
    SubscriptionType? subscriptionType,
    bool? isLoading,
    bool? isPurchasing,
    String? error,
    bool clearError = false,
    List<ProductDetails>? products,
  }) {
    return SubscriptionState(
      isPro: isPro ?? this.isPro,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      isLoading: isLoading ?? this.isLoading,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      error: clearError ? null : (error ?? this.error),
      products: products ?? this.products,
    );
  }
}

// ═══════════════════════════════════════════
// SUBSCRIPTION PROVIDER
// ═══════════════════════════════════════════
final subscriptionProvider =
    NotifierProvider<SubscriptionNotifier, SubscriptionState>(
        SubscriptionNotifier.new);

class SubscriptionNotifier extends Notifier<SubscriptionState> {
  late final PurchaseService _purchaseService;
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  SubscriptionState build() {
    _purchaseService = PurchaseService();
    _setupCallbacks();
    // Delay to avoid accessing state before it's ready
    Future.microtask(() => _loadInitialState());
    return const SubscriptionState();
  }

  void _setupCallbacks() {
    _purchaseService.onPurchaseUpdated = (isPro, type) {
      state = state.copyWith(
        isPro: isPro,
        subscriptionType: type,
        isPurchasing: false,
        clearError: true,
      );
    };

    _purchaseService.onPurchaseError = (error) {
      state = state.copyWith(
        isPurchasing: false,
        error: error,
      );
    };

    _purchaseService.onPurchasingStateChanged = (isPurchasing) {
      state = state.copyWith(isPurchasing: isPurchasing);
    };

    // init() runs in main(), so StoreKit may have already replayed an
    // unfinished transaction before this notifier existed. Collect it now.
    _purchaseService.flushPendingDelivery();
  }

  Future<void> _loadInitialState() async {
    // Load saved subscription status
    final isPro = _prefs.getBool('isPro') ?? false;
    final typeStr = _prefs.getString('subscriptionType');
    final subscriptionType = typeStr != null
        ? SubscriptionType.values.firstWhere(
            (t) => t.name == typeStr,
            orElse: () => SubscriptionType.free,
          )
        : SubscriptionType.free;

    state = state.copyWith(
      isPro: isPro,
      subscriptionType: subscriptionType,
      isLoading: false,
      isPurchasing: _purchaseService.isPurchasing,
      products: _purchaseService.products,
    );
  }

  // ═══════════════════════════════════════════
  // PUBLIC METHODS
  // ═══════════════════════════════════════════

  /// Buy a product by ID.
  ///
  /// Deliberately does not set `isPurchasing` here — PurchaseService owns that
  /// flag and pushes it back through onPurchasingStateChanged. Keeping a second
  /// copy is what let the button re-enable while the service stayed locked,
  /// so every following tap was rejected as "already in progress".
  Future<bool> buy(String productId) async {
    state = state.copyWith(clearError: true);
    return await _purchaseService.buy(productId);
  }

  /// Restore previous purchases
  Future<void> restore() async {
    state = state.copyWith(clearError: true);
    await _purchaseService.restore();
  }

  /// Refresh products from store
  Future<void> refreshProducts() async {
    state = state.copyWith(isLoading: true);
    await _purchaseService.loadProducts();
    state = state.copyWith(
      isLoading: false,
      products: _purchaseService.products,
    );
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ═══════════════════════════════════════════
  // HELPER GETTERS
  // ═══════════════════════════════════════════

  /// Get formatted price for a product
  String getPrice(String productId) {
    return _purchaseService.getPrice(productId);
  }

  /// Get product details
  ProductDetails? getProduct(String productId) {
    return _purchaseService.getProduct(productId);
  }

  /// Check if a specific feature is available
  bool canUseFeature(ProFeature feature) {
    if (state.isPro) return true;

    switch (feature) {
      case ProFeature.businessMode:
        return FreeTierLimits.canUseBusinessMode;
      case ProFeature.presentationMode:
        return FreeTierLimits.canUsePresentationMode;
      case ProFeature.customLogo:
        return FreeTierLimits.canUseLogo;
      case ProFeature.allFonts:
        return false;
      case ProFeature.allColors:
        return false;
      case ProFeature.noWatermark:
        return !FreeTierLimits.showAds;  // No watermark concept, using showAds
    }
  }

  /// Get max recent messages based on subscription
  int get maxRecentMessages {
    return state.isPro
        ? ProTierLimits.maxRecentMessages
        : FreeTierLimits.maxRecentMessages;
  }

  /// Get available fonts count based on subscription
  int get maxFonts {
    return state.isPro ? ProTierLimits.maxFonts : FreeTierLimits.maxFonts;
  }

  /// Get available colors count based on subscription
  int get maxColors {
    return state.isPro ? ProTierLimits.maxColors : FreeTierLimits.maxColors;
  }

  /// Should show ads
  bool get showAds {
    return state.isPro
        ? ProTierLimits.showAds
        : FreeTierLimits.showAds;
  }
}

// ═══════════════════════════════════════════
// PRO FEATURES ENUM
// ═══════════════════════════════════════════
enum ProFeature {
  businessMode,
  presentationMode,
  customLogo,
  allFonts,
  allColors,
  noWatermark,
}

// ═══════════════════════════════════════════
// CONVENIENCE PROVIDERS
// ═══════════════════════════════════════════

/// Quick check if user is Pro
final isProProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).isPro;
});

/// Check if currently purchasing
final isPurchasingProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).isPurchasing;
});

/// Get subscription type
final subscriptionTypeProvider = Provider<SubscriptionType>((ref) {
  return ref.watch(subscriptionProvider).subscriptionType;
});
