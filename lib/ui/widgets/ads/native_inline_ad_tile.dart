import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../services/ads_service.dart';

/// Adaptive/advanced native ad tile.
///
/// Rules:
/// - Backend controls whether native ads are allowed through AdsService.
/// - Web preview shows a clear placeholder so layout can be tested in Chrome.
/// - Android/iOS only show a real NativeAd after it is loaded.
/// - If AdMob/native factory is not available or the ad fails, this widget
///   collapses completely. It never shows fake ad cards on mobile.
class NativeInlineAdTile extends StatefulWidget {
  final String tabKey;
  final String label;
  final double minHeight;
  final EdgeInsetsGeometry margin;
  final String factoryId;

  const NativeInlineAdTile({
    super.key,
    this.tabKey = 'inspire',
    this.label = 'Sponsored',
    this.minHeight = 120,
    this.margin = const EdgeInsets.only(bottom: 14),
    this.factoryId = 'listTile',
  });

  @override
  State<NativeInlineAdTile> createState() => _NativeInlineAdTileState();
}

class _NativeInlineAdTileState extends State<NativeInlineAdTile>
    with AutomaticKeepAliveClientMixin<NativeInlineAdTile> {
  @override
  bool get wantKeepAlive => true;

  NativeAd? _nativeAd;
  bool _loaded = false;
  bool _failed = false;
  bool _loading = false;
  int _requestGeneration = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    AdsService.instance.policyRevision.addListener(_handlePolicyRevision);
    _loadNativeAdIfAllowed();
  }

  void _handlePolicyRevision() {
    if (!mounted) return;
    final ads = AdsService.instance;
    final allowed = ads.nativeAllowedForTab(widget.tabKey) &&
        ads.hasUnitForFormat('native');
    if (!allowed) {
      _disposeAd();
      _loaded = false;
      _failed = false;
      _loading = false;
    } else if (!_loaded && !_loading) {
      _failed = false;
      _loadNativeAdIfAllowed();
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant NativeInlineAdTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabKey != widget.tabKey ||
        oldWidget.factoryId != widget.factoryId) {
      _disposeAd();
      _loaded = false;
      _failed = false;
      _loading = false;
      _loadNativeAdIfAllowed();
    }
  }

  Future<void> _loadNativeAdIfAllowed() async {
    if (kIsWeb || _loading || _loaded || _failed) return;

    final ads = AdsService.instance;
    if (!ads.nativeRuntimeAvailable ||
        !ads.nativeAllowedForTab(widget.tabKey) ||
        !ads.hasUnitForFormat('native')) {
      _failed = true;
      return;
    }

    _loading = true;
    final generation = ++_requestGeneration;
    NativeAd? pendingAd;

    final acquired = await ads.acquireAdLoadSlot(
      format: 'native',
      placement:
          'native:${widget.tabKey}:${widget.factoryId}:${identityHashCode(this)}',
    );
    if (!mounted || generation != _requestGeneration) {
      if (acquired) {
        ads.releaseAdLoadSlot(format: 'native', success: false);
      }
      _loading = false;
      return;
    }
    if (!acquired) {
      _loading = false;
      _scheduleRetry(const Duration(seconds: 2));
      return;
    }

    try {
      pendingAd = NativeAd(
        adUnitId: ads.nativeUnitId,
        request: const AdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.small,
        ),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            ads.releaseAdLoadSlot(format: 'native', success: true);
            if (!mounted || generation != _requestGeneration) {
              ad.dispose();
              return;
            }

            final loadedAd = ad as NativeAd;
            setState(() {
              _nativeAd?.dispose();
              _nativeAd = loadedAd;
              _loaded = true;
              _failed = false;
              _loading = false;
            });
          },
          onAdFailedToLoad: (ad, error) {
            ads.releaseAdLoadSlot(
              format: 'native',
              success: false,
              errorCode: error.code,
            );
            ad.dispose();
            if (!mounted || generation != _requestGeneration) return;
            setState(() {
              _nativeAd = null;
              _loaded = false;
              _failed = false;
              _loading = false;
            });
            _scheduleRetry(
              error.code == 3
                  ? const Duration(seconds: 30)
                  : const Duration(seconds: 12),
            );
          },
        ),
      );

      await pendingAd.load();
    } on PlatformException {
      ads.releaseAdLoadSlot(format: 'native', success: false);
      pendingAd?.dispose();
      ads.markNativeUnavailableForSession();
      if (!mounted) return;
      setState(() {
        _nativeAd = null;
        _loaded = false;
        _failed = true;
        _loading = false;
      });
    } catch (_) {
      ads.releaseAdLoadSlot(format: 'native', success: false);
      pendingAd?.dispose();
      if (!mounted) return;
      setState(() {
        _nativeAd = null;
        _loaded = false;
        _failed = true;
        _loading = false;
      });
    }
  }

  void _scheduleRetry(Duration delay) {
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (!mounted || _loaded || _loading) return;
      _failed = false;
      _loadNativeAdIfAllowed();
    });
  }

  void _disposeAd() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _requestGeneration++;
    _nativeAd?.dispose();
    _nativeAd = null;
  }

  @override
  void dispose() {
    AdsService.instance.policyRevision.removeListener(_handlePolicyRevision);
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ads = AdsService.instance;

    if (!kIsWeb &&
        (!ads.nativeRuntimeAvailable ||
            !ads.nativeAllowedForTab(widget.tabKey) ||
            _failed)) {
      return const SizedBox.shrink();
    }

    if (kIsWeb) {
      if (!ads.nativeAllowedForTab(widget.tabKey)) {
        return const SizedBox.shrink();
      }
      return _WebNativePreview(
        label: widget.label,
        minHeight: widget.minHeight,
        margin: widget.margin,
      );
    }

    if (!_loaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    final resolvedHeight = widget.minHeight < 100 ? 100.0 : widget.minHeight;

    return SizedBox(
      width: double.infinity,
      height: resolvedHeight,
      child: Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox.expand(
            child: AdWidget(ad: _nativeAd!),
          ),
        ),
      ),
    );
  }
}

class _WebNativePreview extends StatelessWidget {
  final String label;
  final double minHeight;
  final EdgeInsetsGeometry margin;

  const _WebNativePreview({
    required this.label,
    required this.minHeight,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1228), Color(0xFF141B3A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5B1FA8), Color(0xFFB70E7C)],
              ),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Text(
                        'Web Preview Only',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Native ad placement is backend-controlled. Mobile collapses this space unless a real native ad loads.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12.5,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
