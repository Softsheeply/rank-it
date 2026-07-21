import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'purchase_service.dart';

/// Real AdMob identifiers for this app. iOS-only for now — Android units
/// aren't configured yet, so Android falls back to Google's public test
/// units so the app never crashes if run there.
class AdIds {
  AdIds._();

  static String get appId => 'ca-app-pub-7275597651109621~7899126145';

  static String get bannerUnitId {
    if (Platform.isIOS) return 'ca-app-pub-7275597651109621/4436337940';
    return 'ca-app-pub-3940256099942544/6300978111';
  }

  static String get interstitialUnitId {
    if (Platform.isIOS) return 'ca-app-pub-7275597651109621/6794907977';
    return 'ca-app-pub-3940256099942544/1033173712';
  }
}

/// One-time SDK init, called from main() before runApp. Swallows errors so
/// a platform/network hiccup (or running in a test/CI environment with no
/// ads platform channel) never crashes app startup — it just means no ads
/// load, which is a safe fallback.
Future<void> initAds() async {
  try {
    await MobileAds.instance.initialize();
  } catch (_) {
    // No-op: ads simply won't show if the SDK can't initialize.
  }
}

/// A bottom-pinned banner ad. Shows nothing (zero height) once ads are
/// removed via purchase, or while the ad is still loading/failed.
class BannerAdBar extends StatefulWidget {
  final PurchaseService purchaseService;
  const BannerAdBar({super.key, required this.purchaseService});

  @override
  State<BannerAdBar> createState() => _BannerAdBarState();
}

class _BannerAdBarState extends State<BannerAdBar> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    widget.purchaseService.addListener(_onPurchaseChanged);
    if (!widget.purchaseService.adsRemoved) {
      _loadBanner();
    }
  }

  void _onPurchaseChanged() {
    if (widget.purchaseService.adsRemoved) {
      _bannerAd?.dispose();
      _bannerAd = null;
      if (mounted) setState(() => _isLoaded = false);
    }
  }

  void _loadBanner() {
    try {
      _bannerAd = BannerAd(
        adUnitId: AdIds.bannerUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _isLoaded = true);
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
          },
        ),
      )..load();
    } catch (_) {
      // No ads platform channel available (e.g. widget tests) — stay hidden.
    }
  }

  @override
  void dispose() {
    widget.purchaseService.removeListener(_onPurchaseChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.purchaseService.adsRemoved || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}

/// Manages loading + showing interstitial ads at natural break points
/// (opening a board), capped so it isn't shown every single time.
class InterstitialAdManager {
  InterstitialAdManager._();
  static final InterstitialAdManager instance = InterstitialAdManager._();

  InterstitialAd? _ad;
  int _openCount = 0;
  static const int _showEveryNOpens = 6;

  void preload() {
    try {
      InterstitialAd.load(
        adUnitId: AdIds.interstitialUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => _ad = ad,
          onAdFailedToLoad: (_) => _ad = null,
        ),
      );
    } catch (_) {
      // No ads platform channel available (e.g. widget tests) — no-op.
    }
  }

  /// Call this each time a board is opened. Shows an interstitial roughly
  /// every [_showEveryNOpens] opens, and only if ads haven't been purchased
  /// away.
  void maybeShowOnOpen({required bool adsRemoved}) {
    if (adsRemoved) return;
    _openCount++;
    if (_openCount % _showEveryNOpens != 0) return;
    if (_ad == null) {
      preload();
      return;
    }
    try {
      final ad = _ad!;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _ad = null;
          preload();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _ad = null;
          preload();
        },
      );
      ad.show();
    } catch (_) {
      // No-op fallback if showing fails for any reason.
    }
  }

  /// Test-only hook to reset the shared counter between test cases.
  @visibleForTesting
  void resetForTesting() {
    _openCount = 0;
    _ad = null;
  }
}
