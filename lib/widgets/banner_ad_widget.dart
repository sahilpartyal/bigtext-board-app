import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../providers/subscription_provider.dart';
import '../utils/constants.dart';

/// A reusable widget that displays a banner ad at the bottom of the screen.
/// Each instance creates and manages its own BannerAd to avoid conflicts.
/// Automatically hides for Pro users.
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    // Check if user is Pro before loading
    final isPro = ref.read(isProProvider);
    if (isPro) return;

    _bannerAd = BannerAd(
      adUnitId: AdUnitIds.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAdWidget: Failed to load - ${error.message}');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);

    // Don't show banner for Pro users
    if (isPro) {
      return const SizedBox.shrink();
    }

    // Don't show if ad is not loaded
    if (!_isAdLoaded || _bannerAd == null) {
      // Return a placeholder with the same height to prevent layout jumps
      return const SizedBox(height: 50);
    }

    return SafeArea(
      top: false,
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: _bannerAd!.size.height.toDouble(),
        color: Colors.transparent,
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
