import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/subscription_provider.dart';
import '../utils/constants.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String _selectedPlan = ProductIds.yearly;
  bool _wasNotPro = true; // Track if user was not Pro when screen opened
  bool _navigatedToSuccess = false; // Guards against a double push

  @override
  void initState() {
    super.initState();
    // Force portrait orientation for subscription screen
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // Check initial Pro status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wasNotPro = !ref.read(subscriptionProvider).isPro;
    });
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final subNotifier = ref.read(subscriptionProvider.notifier);

    // Listen for Pro status change and navigate to success screen
    ref.listen<SubscriptionState>(subscriptionProvider, (previous, next) {
      // A purchase and its restored twin can both land, so only navigate once.
      if (!_navigatedToSuccess &&
          _wasNotPro &&
          next.isPro &&
          !next.isPurchasing) {
        _navigatedToSuccess = true;
        Get.offNamed('/purchase-success');
      }
    });

    // The paywall is locked behind a blur from the moment Continue is tapped
    // until the entitlement lands. While Apple's payment sheet is up the blur
    // sits behind it, so in practice the user only sees it in the gap between
    // paying and the success screen — the gap that used to look like nothing
    // had happened. An Ask To Buy purchase parks `isPurchasing` at true for as
    // long as it takes a parent to approve, and that arrives as a message in
    // `error`, so the blur steps aside rather than hanging there for days.
    final isConfirming = subState.isPurchasing && subState.error == null;

    return PopScope(
      // No backing out mid-transaction: the entitlement is still in flight.
      canPop: !isConfirming,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: Column(
                children: [
                  // App Bar
                  _buildAppBar(subNotifier),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Header
                          _buildHeader(),

                          const SizedBox(height: 20),

                          // Plan Cards
                          _buildPlanCards(subNotifier),

                          const SizedBox(height: 20),

                          // Features List
                          _buildFeaturesList(),

                          const SizedBox(height: 24),

                          // Error message
                          if (subState.error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        subState.error!,
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (subState.error != null)
                            const SizedBox(height: 16),

                          // CTA Button
                          _buildCTAButton(subState, subNotifier),

                          // Legal text
                          _buildLegalText(),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isConfirming) const _PurchaseConfirmingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(SubscriptionNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close, color: Color(0xFF1F2937), size: 24),
          ),
          const Expanded(
            child: Text(
              'BigText Pro',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          TextButton(
            onPressed: () => notifier.restore(),
            child: const Text(
              'Restore',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123768), Color(0xFF1e4a8a)],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Unlock Pro',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Remove ads · all modes · all fonts · all colors',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCards(SubscriptionNotifier notifier) {
    // Prices come from StoreKit, already formatted in the user's own currency.
    // Never hardcode them — App Review runs from many countries, and a price
    // that does not match Apple's payment sheet is a metadata rejection.
    //
    // The yearly saving obeys the same rule. Apple's price tiers are not
    // straight currency conversions, so the discount differs by storefront and
    // no one figure is right everywhere. Deriving it from the two prices that
    // are actually on screen keeps the badge true in every currency, and keeps
    // it true the next time the prices change.
    final yearlySavings = _yearlySavingsLabel(notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _PlanCard(
              name: 'MONTHLY',
              price: notifier.getPrice(ProductIds.monthly),
              isSelected: _selectedPlan == ProductIds.monthly,
              onTap: () => setState(() => _selectedPlan = ProductIds.monthly),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PlanCard(
              name: 'YEARLY',
              price: notifier.getPrice(ProductIds.yearly),
              badge: 'BEST VALUE',
              savings: yearlySavings,
              isSelected: _selectedPlan == ProductIds.yearly,
              onTap: () => setState(() => _selectedPlan = ProductIds.yearly),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PlanCard(
              name: 'LIFETIME',
              price: notifier.getPrice(ProductIds.lifetime),
              isSelected: _selectedPlan == ProductIds.lifetime,
              onTap: () => setState(() => _selectedPlan = ProductIds.lifetime),
            ),
          ),
        ],
      ),
    );
  }

  /// What the yearly saving is when StoreKit has not told us the prices.
  ///
  /// Matches the App Store Connect price tiers: 12 x $0.99 = $11.88 against
  /// $9.99 a year. Apple's tiers are near-proportional across storefronts, so
  /// this is close to right everywhere — but it is a stand-in, and the live
  /// figure below is used whenever the real prices are available.
  static const String _fallbackYearlySavings = 'Save 16%';

  /// "Save N%" for the yearly plan.
  ///
  /// Worked out from the two prices actually on screen whenever StoreKit has
  /// answered, so the badge is right in every currency and cannot go stale the
  /// next time the prices change. Falls back to [_fallbackYearlySavings] when
  /// no prices have loaded — the simulator, or StoreKit being unreachable.
  ///
  /// Null only when the real prices say the yearly plan is not actually a
  /// saving; inventing one then would be a claim the prices disprove.
  String? _yearlySavingsLabel(SubscriptionNotifier notifier) {
    final monthly = notifier.getProduct(ProductIds.monthly);
    final yearly = notifier.getProduct(ProductIds.yearly);
    if (monthly == null || yearly == null) return _fallbackYearlySavings;

    final twelveMonths = monthly.rawPrice * 12;
    if (twelveMonths <= 0) return _fallbackYearlySavings;

    final percent = (1 - yearly.rawPrice / twelveMonths) * 100;
    // Below 1% there is nothing to boast about, and a negative figure would
    // mean the yearly plan costs more than paying by the month.
    if (percent < 1) return null;

    return 'Save ${percent.round()}%';
  }

  Widget _buildFeaturesList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'Everything Included',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            // Features
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _FeatureRowIcon(
                    icon: Icons.business_center_outlined,
                    text: 'Business mode',
                  ),
                  _FeatureRowIcon(
                    icon: Icons.slideshow_outlined,
                    text: 'Presentation mode',
                  ),
                  _FeatureRowIcon(
                    icon: Icons.text_fields_outlined,
                    text: 'All 12 font families',
                  ),
                  _FeatureRowIcon(
                    icon: Icons.palette_outlined,
                    text: 'All colors + custom',
                  ),
                  _FeatureRowIcon(
                    icon: Icons.block_outlined,
                    text: 'No advertisements',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTAButton(
    SubscriptionState state,
    SubscriptionNotifier notifier,
  ) {
    // getPrice returns '--' when the product has not loaded, which happens if
    // the store is unreachable or the IDs do not match App Store Connect.
    // Fall back to a plain label rather than showing a price that isn't real.
    final price = notifier.getPrice(_selectedPlan);
    final hasPrice = price != '--' && price.isNotEmpty;

    String buttonText;
    if (!hasPrice) {
      buttonText = 'Continue';
    } else if (_selectedPlan == ProductIds.monthly) {
      buttonText = 'Continue with Monthly — $price';
    } else if (_selectedPlan == ProductIds.yearly) {
      buttonText = 'Continue with Yearly — $price';
    } else if (_selectedPlan == ProductIds.lifetime) {
      buttonText = 'Continue with Lifetime — $price';
    } else {
      buttonText = 'Continue';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: state.isPurchasing
              ? null
              : () async {
                  // Just initiate purchase - navigation happens via listener when purchase completes
                  await notifier.buy(_selectedPlan);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF123768),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: state.isPurchasing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  /// Renewal disclosure plus the Terms and Privacy links.
  ///
  /// App Store Guideline 3.1.2 requires both links to be reachable from the
  /// screen where the subscription is bought, alongside the price and term.
  Widget _buildLegalText() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Column(
        children: [
          const Text(
            'Subscriptions renew automatically unless cancelled at least 24 '
            'hours before the end of the current period. Manage or cancel '
            'anytime in your App Store account settings. Lifetime is a '
            'one-time purchase and does not renew.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.45,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegalLink(label: 'Terms of Use', url: LegalUrls.termsOfUse),
              Text(
                '  •  ',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
              _LegalLink(label: 'Privacy Policy', url: LegalUrls.privacyPolicy),
            ],
          ),
        ],
      ),
    );
  }
}

/// Blurs and locks the paywall while the App Store settles a transaction.
///
/// The entitlement does not arrive with the payment: Apple's sheet closes and
/// the transaction event follows seconds later on the purchase stream. Until
/// then the paywall looked untouched apart from a greyed button, so people read
/// the pause as "my payment failed" and started tapping again. Blurring
/// everything and leaving only a spinner says the work is still going.
class _PurchaseConfirmingOverlay extends StatelessWidget {
  const _PurchaseConfirmingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      // Swallows every tap and drag underneath, so no plan can be re-selected
      // and Restore cannot fire while the entitlement is mid-flight.
      child: AbsorbPointer(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            // The blur alone leaves the page legible enough to look tappable;
            // the wash on top is what reads as "not right now".
            color: Colors.white.withValues(alpha: 0.55),
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF123768)),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Confirming your purchase',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The App Store is finishing up. This takes a few seconds — '
                    'please keep the app open.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tappable underlined link that opens a legal page in the system browser.
class _LegalLink extends StatelessWidget {
  final String label;
  final String url;

  const _LegalLink({required this.label, required this.url});

  Future<void> _open() async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('LegalLink: could not open $url - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Keeps the tap target comfortable without changing the visual layout.
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF123768),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String? badge;
  final String? savings;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.name,
    required this.price,
    this.badge,
    this.savings,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFe8eef5) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF123768)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          // The column shrink-wraps its widest child, so without this the whole
          // block sits against the card's left edge rather than centred.
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? const Color(0xFF123768)
                        : const Color(0xFF1F2937),
                  ),
                ),
                if (savings != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    savings!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ],
            ),
            if (badge != null)
              Positioned(
                top: -24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF123768),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRowIcon extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRowIcon({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF123768)),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
