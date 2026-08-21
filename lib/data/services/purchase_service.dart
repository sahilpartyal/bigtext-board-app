import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';

// WARNING: must be false in any released build. While true, buy() unlocks Pro
// without contacting the store, so every user gets Pro for free.
// Test mode is now off: buy() goes through the real store. This requires the
// Paid Apps Agreement to be active in App Store Connect and the products to be
// approved — otherwise the store returns no products and buy() fails.
const bool kTestPurchaseMode = false;

/// How long to wait for a transaction event after the payment sheet hands
/// control back to us.
///
/// StoreKit normally answers in well under a second. A dropped connection can
/// leave us with no event at all, and without this timeout the service stays
/// "busy" forever — every later tap is then rejected with "already in
/// progress" and the only escape is force-quitting the app.
const Duration _kPurchaseResolveTimeout = Duration(seconds: 60);

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> products = [];

  // Purchase state
  bool _isAvailable = false;
  bool _isPurchasing = false;
  String? _purchaseError;
  Timer? _resolveTimer;

  /// Product IDs already written to storage this run. Both buyNonConsumable's
  /// return value and the transaction stream can report the same purchase, so
  /// delivery has to be safe to run twice.
  final Set<String> _delivered = {};

  /// A delivery that completed while nobody was listening. StoreKit replays
  /// unfinished transactions as soon as the stream is attached in init(), which
  /// happens in main() — long before the paywall wires its callbacks. The
  /// entitlement is already saved to storage at that point, but the success
  /// screen would never be shown, so we hold the notification and replay it
  /// from [flushPendingDelivery].
  ({bool isPro, SubscriptionType type})? _pendingDelivery;

  // Getters
  bool get isAvailable => _isAvailable;
  bool get isPurchasing => _isPurchasing;
  String? get purchaseError => _purchaseError;

  // Callbacks
  Function(bool isPro, SubscriptionType type)? onPurchaseUpdated;
  Function(String error)? onPurchaseError;
  Function(bool isPurchasing)? onPurchasingStateChanged;

  // ═══════════════════════════════════════════
  // INITIALIZE
  // ═══════════════════════════════════════════
  Future<void> init() async {
    // Check if IAP is available on this device
    _isAvailable = await _iap.isAvailable();

    if (!_isAvailable) {
      debugPrint('PurchaseService: IAP not available on this device');
      return;
    }

    // Listen to purchase stream
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: _onPurchaseStreamDone,
      onError: _onPurchaseStreamError,
    );

    // Load products from store
    await loadProducts();

    debugPrint('PurchaseService: Initialized successfully');
  }

  /// Replays a delivery that landed before the callbacks were attached.
  ///
  /// Safe to call every time callbacks are (re)wired; does nothing if there is
  /// nothing waiting.
  void flushPendingDelivery() {
    final pending = _pendingDelivery;
    if (pending == null) return;
    _pendingDelivery = null;
    debugPrint('PurchaseService: Replaying buffered delivery - ${pending.type.name}');
    onPurchaseUpdated?.call(pending.isPro, pending.type);
  }

  // ═══════════════════════════════════════════
  // LOAD PRODUCTS FROM STORE
  // ═══════════════════════════════════════════
  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    final response = await _iap.queryProductDetails(ProductIds.all);

    if (response.error != null) {
      debugPrint('PurchaseService: Error loading products - ${response.error}');
      return;
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('PurchaseService: Products not found - ${response.notFoundIDs}');
    }

    products = response.productDetails;
    debugPrint('PurchaseService: Loaded ${products.length} products');

    // Sort products by price (monthly, yearly, lifetime)
    products.sort((a, b) {
      final order = [ProductIds.monthly, ProductIds.yearly, ProductIds.lifetime];
      return order.indexOf(a.id).compareTo(order.indexOf(b.id));
    });
  }

  // ═══════════════════════════════════════════
  // BUY PRODUCT
  // ═══════════════════════════════════════════
  Future<bool> buy(String productId) async {
    // TEST MODE: Simulate successful purchase
    if (kTestPurchaseMode) {
      debugPrint('PurchaseService: [TEST MODE] Simulating purchase for $productId');
      _setPurchasing(true);

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      final subscriptionType = SubscriptionType.fromProductId(productId);
      await _saveEntitlement(productId, subscriptionType);

      debugPrint('PurchaseService: [TEST MODE] Pro unlocked - $productId');

      _setPurchasing(false);
      _notifyDelivered(subscriptionType);

      return true;
    }

    // PRODUCTION MODE: Real purchase flow
    if (!_isAvailable) {
      _fail('In-app purchases are not available on this device.');
      return false;
    }

    if (_isPurchasing) {
      // Not surfaced as an error: the button is already showing a spinner, and
      // a second tap is the user being impatient, not something going wrong.
      debugPrint('PurchaseService: Ignoring tap, purchase already in progress');
      return false;
    }

    // Find the product
    debugPrint('PurchaseService: Attempting to buy $productId');
    debugPrint('PurchaseService: Available products: ${products.map((p) => p.id).toList()}');

    final product = getProduct(productId);
    if (product == null) {
      debugPrint('PurchaseService: Product not found: $productId. '
          'Available: ${products.map((p) => p.id).toList()}');
      _fail('That plan is not available right now. Please try again later.');
      return false;
    }

    _purchaseError = null;
    _setPurchasing(true);

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      // All our products are non-consumable (subscriptions + lifetime).
      final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);

      if (!started) {
        // The store declined to even open the payment sheet.
        debugPrint('PurchaseService: buyNonConsumable returned false');
        _setPurchasing(false);
        _fail('The purchase could not be started. Please try again.');
        return false;
      }

      // The sheet was accepted. The entitlement itself arrives on the
      // transaction stream — but arm a timeout so a missing event cannot strand
      // us in the purchasing state.
      _armResolveTimer();
      return true;
    } catch (e, stack) {
      // Never let a raw PlatformException reach the UI: its toString() carries
      // the full native stacktrace.
      debugPrint('PurchaseService: buy() threw - $e');
      debugPrint('$stack');

      _cancelResolveTimer();
      _setPurchasing(false);

      if (_isCancellation(e)) {
        // Backing out of Apple's sheet is a normal choice, not a failure.
        debugPrint('PurchaseService: Purchase cancelled by user');
        return false;
      }

      _fail(_humanError(e));
      return false;
    }
  }

  // ═══════════════════════════════════════════
  // RESTORE PURCHASES
  // ═══════════════════════════════════════════
  bool _restoredAnyPurchase = false;

  Future<void> restore() async {
    if (!_isAvailable) {
      _fail('In-app purchases are not available on this device.');
      return;
    }

    if (_isPurchasing) {
      debugPrint('PurchaseService: Ignoring restore, purchase already in progress');
      return;
    }

    _restoredAnyPurchase = false;
    _purchaseError = null;
    _setPurchasing(true);

    try {
      await _iap.restorePurchases();

      // Restored transactions arrive on the stream, not from the call above.
      await Future.delayed(const Duration(seconds: 3));

      if (!_restoredAnyPurchase) {
        _setPurchasing(false);
        _fail('No previous purchases found for this Apple ID.');
      } else {
        _setPurchasing(false);
      }
    } catch (e, stack) {
      debugPrint('PurchaseService: restore() threw - $e');
      debugPrint('$stack');
      _setPurchasing(false);
      if (!_isCancellation(e)) {
        _fail(_humanError(e));
      }
    }
  }

  // ═══════════════════════════════════════════
  // HANDLE PURCHASE UPDATES (Private)
  // ═══════════════════════════════════════════
  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    // Handled one at a time: these each mutate _isPurchasing, and running them
    // concurrently lets a stale status win the race and re-lock the service.
    for (final purchase in purchases) {
      await _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        debugPrint('PurchaseService: Purchase pending - ${purchase.productID}');
        _setPurchasing(true);
        // Ask To Buy and bank approvals can sit here for days, so say so
        // instead of spinning silently.
        _purchaseError = null;
        onPurchaseError?.call(
            'Your purchase is waiting for approval. Pro unlocks as soon as it '
            'is approved.');
        break;

      case PurchaseStatus.purchased:
        debugPrint('PurchaseService: Purchase completed - ${purchase.productID}');
        _cancelResolveTimer();
        if (await _verifyPurchase(purchase)) {
          await _deliverProduct(purchase);
        } else {
          _fail('We could not verify that purchase. Please contact support.');
        }
        _setPurchasing(false);
        break;

      case PurchaseStatus.restored:
        debugPrint('PurchaseService: Purchase restored - ${purchase.productID}');
        _restoredAnyPurchase = true;
        _cancelResolveTimer();
        if (await _verifyPurchase(purchase)) {
          await _deliverProduct(purchase);
        }
        _setPurchasing(false);
        break;

      case PurchaseStatus.error:
        debugPrint('PurchaseService: Purchase error - ${purchase.error}');
        _cancelResolveTimer();
        _setPurchasing(false);
        _fail(_humanError(purchase.error));
        break;

      case PurchaseStatus.canceled:
        debugPrint('PurchaseService: Purchase canceled');
        _cancelResolveTimer();
        _setPurchasing(false);
        // Deliberately silent — the user chose to back out.
        break;
    }

    // Complete pending purchases (required by stores!)
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  // ═══════════════════════════════════════════
  // VERIFY PURCHASE (Private)
  // ═══════════════════════════════════════════
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // TODO(receipts): validate purchase.verificationData against Apple/Google
    // from a backend before granting Pro. Until then the entitlement is a
    // local flag and a determined user can forge it.
    return purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored;
  }

  // ═══════════════════════════════════════════
  // DELIVER PRODUCT (Private)
  // ═══════════════════════════════════════════
  Future<void> _deliverProduct(PurchaseDetails purchase) async {
    final subscriptionType = SubscriptionType.fromProductId(purchase.productID);

    if (_delivered.contains(purchase.productID)) {
      debugPrint('PurchaseService: Already delivered ${purchase.productID}, '
          're-notifying only');
      _notifyDelivered(subscriptionType);
      return;
    }

    await _saveEntitlement(purchase.productID, subscriptionType);

    debugPrint('PurchaseService: Pro unlocked - ${purchase.productID}');

    _notifyDelivered(subscriptionType);
  }

  Future<void> _saveEntitlement(
      String productId, SubscriptionType subscriptionType) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isPro', true);
    await prefs.setString('subscriptionType', subscriptionType.name);
    await prefs.setString('subscriptionProductId', productId);
    await prefs.setString('purchaseDate', DateTime.now().toIso8601String());

    _delivered.add(productId);
  }

  /// Announces a delivery, buffering it if nobody has wired up yet.
  void _notifyDelivered(SubscriptionType type) {
    _purchaseError = null;
    final callback = onPurchaseUpdated;
    if (callback == null) {
      debugPrint('PurchaseService: No listener yet, buffering delivery');
      _pendingDelivery = (isPro: true, type: type);
      return;
    }
    callback(true, type);
  }

  // ═══════════════════════════════════════════
  // PURCHASING STATE (Private)
  // ═══════════════════════════════════════════

  /// The single source of truth for "a purchase is in flight". Nothing else may
  /// keep its own copy — two copies drifting apart is what deadlocked the
  /// button before.
  void _setPurchasing(bool value) {
    if (_isPurchasing == value) return;
    _isPurchasing = value;
    if (!value) _cancelResolveTimer();
    onPurchasingStateChanged?.call(value);
  }

  void _fail(String message) {
    _purchaseError = message;
    onPurchaseError?.call(message);
  }

  void _armResolveTimer() {
    _cancelResolveTimer();
    _resolveTimer = Timer(_kPurchaseResolveTimeout, () {
      if (!_isPurchasing) return;
      debugPrint('PurchaseService: No transaction event within '
          '${_kPurchaseResolveTimeout.inSeconds}s, releasing purchase lock');
      _isPurchasing = false;
      onPurchasingStateChanged?.call(false);
      _fail('We did not hear back from the App Store. If you were charged, '
          'tap Restore to unlock Pro.');
    });
  }

  void _cancelResolveTimer() {
    _resolveTimer?.cancel();
    _resolveTimer = null;
  }

  // ═══════════════════════════════════════════
  // ERROR TRANSLATION (Private)
  // ═══════════════════════════════════════════

  /// True when the user simply dismissed the payment sheet.
  ///
  /// StoreKit 2 reports this by throwing, so without this check backing out
  /// looks identical to a real failure.
  bool _isCancellation(Object? error) {
    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      return code.contains('cancel');
    }
    if (error is IAPError) {
      return error.code.toLowerCase().contains('cancel');
    }
    return false;
  }

  /// Maps a store failure to a sentence a person can act on.
  ///
  /// Never returns the raw object: PlatformException.toString() includes the
  /// native stacktrace, which is what used to fill the paywall.
  String _humanError(Object? error) {
    String? code;
    if (error is PlatformException) {
      code = error.code;
    } else if (error is IAPError) {
      code = error.code;
    }

    switch (code) {
      case 'storekit_no_response':
      case 'storekit2_no_response':
        return 'The App Store did not respond. Please check your connection '
            'and try again.';
      case 'storekit_duplicate_product_object':
        return 'That purchase is already being processed.';
      case 'purchase_error':
      case 'storekit_generic_error':
        return 'The purchase could not be completed. Please try again.';
      case 'network_error':
        return 'No connection to the App Store. Please check your network.';
      case 'storekit_not_entitled':
        return 'This Apple ID is not allowed to make purchases.';
    }

    if (error is IAPError) {
      // Only pass a store message straight through when it is short enough to
      // read; anything longer is a dump, not a sentence.
      final message = error.message;
      if (message.isNotEmpty && message.length < 200) {
        return message;
      }
    }

    return 'Something went wrong with the purchase. Please try again.';
  }

  // ═══════════════════════════════════════════
  // STREAM HANDLERS (Private)
  // ═══════════════════════════════════════════
  void _onPurchaseStreamDone() {
    debugPrint('PurchaseService: Purchase stream closed');
    _subscription?.cancel();
    _subscription = null;
  }

  void _onPurchaseStreamError(dynamic error) {
    debugPrint('PurchaseService: Purchase stream error - $error');
    _cancelResolveTimer();
    _setPurchasing(false);
    if (!_isCancellation(error)) {
      _fail(_humanError(error));
    }
  }

  // ═══════════════════════════════════════════
  // CHECK PRO STATUS
  // ═══════════════════════════════════════════
  Future<bool> checkProStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isPro') ?? false;
  }

  Future<SubscriptionType> getSubscriptionType() async {
    final prefs = await SharedPreferences.getInstance();
    final typeStr = prefs.getString('subscriptionType');
    if (typeStr == null) return SubscriptionType.free;

    return SubscriptionType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => SubscriptionType.free,
    );
  }

  // ═══════════════════════════════════════════
  // GET PRODUCT HELPERS
  // ═══════════════════════════════════════════
  ProductDetails? getProduct(String productId) {
    try {
      return products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  String getPrice(String productId) {
    return getProduct(productId)?.price ?? '--';
  }

  String getTitle(String productId) {
    return getProduct(productId)?.title ?? productId;
  }

  // ═══════════════════════════════════════════
  // DISPOSE
  // ═══════════════════════════════════════════
  void dispose() {
    _cancelResolveTimer();
    _subscription?.cancel();
    _subscription = null;
  }
}
