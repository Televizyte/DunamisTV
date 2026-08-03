import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

abstract class AdsService {
  Future<void> warmUp();
  void dispose();
  Object? createBanner({required String slot});
  Future<void> showInterstitialIfReady({required String placement});
}

class AdsServiceImpl implements AdsService {
  InterstitialAd? _interstitial;

  @override
  Future<void> warmUp() async {
    // You can call this on app start or on safe screens only
    await MobileAds.instance.initialize();

    // Preload interstitial (you can later gate by route/placement)
    InterstitialAd.load(
      adUnitId: _testInterstitialId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  @override
  void dispose() {
    _interstitial?.dispose();
    _interstitial = null;
  }

  @override
  Object? createBanner({required String slot}) {
    // Return a widget later when you give me your real ad unit IDs.
    // For now, keep it null and we’ll wire it to your banner component.
    return null;
  }

  @override
  Future<void> showInterstitialIfReady({required String placement}) async {
    final ad = _interstitial;
    if (ad == null) return;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitial = null;
      },
    );

    ad.show();
    _interstitial = null;
  }

  String _testInterstitialId() {
    // Google test ID (safe for debug). Replace later for release.
    return 'ca-app-pub-3940256099942544/1033173712';
  }
}
