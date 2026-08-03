import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/ads_service.dart';

class BannerAdWidget extends StatefulWidget {
  final String tabKey;
  final EdgeInsetsGeometry padding;

  const BannerAdWidget({
    super.key,
    required this.tabKey,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  BannerAd? _pendingAd;
  AdSize? _resolvedSize;
  AdSize? _pendingSize;
  bool _loadingAdaptive = false;
  bool _isLoaded = false;
  bool _loadFailed = false;
  int? _lastWidth;
  String? _lastUnitId;
  bool _requestInFlight = false;
  bool _disposed = false;
  int _requestGeneration = 0;
  Timer? _retryTimer;

  void _scheduleRetry([Duration delay = const Duration(seconds: 3)]) {
    if (_disposed || !_allowed) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (!mounted || _disposed || !_allowed) return;
      final width = _lastWidth;
      if (width != null && width > 0) {
        _loadFailed = false;
        _ensureAdaptiveBanner(width);
      } else {
        setState(() {});
      }
    });
  }

  bool get _allowed {
    try {
      return AdsService.instance.bannerAllowedForTab(widget.tabKey);
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureAdaptiveBanner(int width) async {
    if (!_allowed) {
      _disposeAd();
      return;
    }

    if (kIsWeb || _loadingAdaptive || width <= 0) return;

    final unitId = AdsService.instance.bannerUnitId.trim();
    if (unitId.isEmpty) {
      _disposeAd();
      return;
    }

    final sameRequest = _lastWidth == width && _lastUnitId == unitId;
    if (sameRequest && (_pendingAd != null || _requestInFlight)) return;
    if (sameRequest && _ad != null && _resolvedSize != null && _isLoaded) {
      return;
    }

    _loadingAdaptive = true;
    final generation = ++_requestGeneration;

    final acquired = await AdsService.instance.acquireAdLoadSlot(
      format: 'banner',
      placement: 'banner:${widget.tabKey}:$width',
    );
    if (!mounted || generation != _requestGeneration) {
      if (acquired) {
        AdsService.instance.releaseAdLoadSlot(
          format: 'banner',
          success: false,
        );
      }
      _loadingAdaptive = false;
      return;
    }
    if (!acquired) {
      _loadingAdaptive = false;
      _scheduleRetry(const Duration(seconds: 8));
      return;
    }

    try {
      final adSize =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

      if (!mounted || generation != _requestGeneration) {
        AdsService.instance.releaseAdLoadSlot(
          format: 'banner',
          success: false,
        );
        return;
      }
      if (adSize == null) {
        AdsService.instance.releaseAdLoadSlot(
          format: 'banner',
          success: false,
        );
        if (_ad == null) _loadFailed = true;
        return;
      }

      _lastWidth = width;
      _lastUnitId = unitId;
      _pendingSize = adSize;
      _loadFailed = false;

      late final BannerAd newAd;
      newAd = BannerAd(
        size: adSize,
        adUnitId: unitId,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _requestInFlight = false;
            AdsService.instance.releaseAdLoadSlot(
              format: 'banner',
              success: true,
            );
            if (!mounted || _disposed || generation != _requestGeneration) {
              ad.dispose();
              return;
            }
            if (!identical(ad, _pendingAd)) {
              ad.dispose();
              return;
            }

            final oldAd = _ad;
            setState(() {
              _ad = ad as BannerAd;
              _resolvedSize = _pendingSize;
              _pendingAd = null;
              _pendingSize = null;
              _isLoaded = true;
              _loadFailed = false;
            });
            if (oldAd != null && !identical(oldAd, ad)) {
              oldAd.dispose();
            }
          },
          onAdFailedToLoad: (ad, error) {
            _requestInFlight = false;
            AdsService.instance.releaseAdLoadSlot(
              format: 'banner',
              success: false,
              errorCode: error.code,
            );
            if (kDebugMode) {
              debugPrint(
                '[AdsLoadError] format=banner placement=${widget.tabKey} '
                'code=${error.code} domain=${error.domain} '
                'message=${error.message}',
              );
            }
            ad.dispose();

            if (!mounted || _disposed || generation != _requestGeneration) {
              return;
            }
            if (!identical(ad, _pendingAd)) return;

            setState(() {
              _pendingAd = null;
              _pendingSize = null;
              _loadFailed = _ad == null;
            });
            _scheduleRetry();
          },
        ),
      );

      if (!mounted || generation != _requestGeneration) {
        AdsService.instance.releaseAdLoadSlot(
          format: 'banner',
          success: false,
        );
        await newAd.dispose();
        return;
      }

      _pendingAd = newAd;
      _requestInFlight = true;
      await newAd.load();
    } catch (error) {
      if (_requestInFlight) {
        _requestInFlight = false;
        AdsService.instance.releaseAdLoadSlot(
          format: 'banner',
          success: false,
        );
      }
      if (kDebugMode) {
        debugPrint(
          '[AdsLoadError] format=banner placement=${widget.tabKey} '
          'exception=$error',
        );
      }
      final failedPending = _pendingAd;
      if (mounted && !_disposed && generation == _requestGeneration) {
        setState(() {
          _pendingAd = null;
          _pendingSize = null;
          _loadFailed = _ad == null;
        });
      }
      failedPending?.dispose();
      _scheduleRetry();
    } finally {
      _loadingAdaptive = false;
    }
  }

  @override
  void didUpdateWidget(covariant BannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tabKey != widget.tabKey) {
      // Preserve the last successfully loaded banner while the next route's
      // policy/creative is resolved. It is replaced only after a new load
      // succeeds, preventing blank banner slots during navigation.
      _requestGeneration++;
      _pendingAd?.dispose();
      _pendingAd = null;
      _pendingSize = null;
      _requestInFlight = false;
      _loadingAdaptive = false;
      _loadFailed = false;
      _lastWidth = null;
      _lastUnitId = null;
      _scheduleRetry(const Duration(milliseconds: 300));
    }
  }

  void _disposeAd() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _requestGeneration++;
    final ad = _ad;
    final pendingAd = _pendingAd;
    _ad = null;
    _pendingAd = null;
    _resolvedSize = null;
    _pendingSize = null;
    _isLoaded = false;
    _loadFailed = false;
    _lastWidth = null;
    _lastUnitId = null;
    _requestInFlight = false;

    ad?.dispose();
    pendingAd?.dispose();
  }

  @override
  void dispose() {
    _disposed = true;
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_allowed) {
      _disposeAd();
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _horizontalPadding(widget.padding);
        final width = (constraints.maxWidth - horizontalPadding).floor();

        if (!kIsWeb) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _ensureAdaptiveBanner(width);
          });
        }

        if (kIsWeb) {
          return Padding(
            padding: widget.padding,
            child: _AdPlaceholder(tabKey: widget.tabKey),
          );
        }

        final ad = _ad;
        final size = _resolvedSize;

        if (_loadFailed && ad == null) {
          return const SizedBox.shrink();
        }

        if (ad == null || size == null || !_isLoaded) {
          // Mobile should never show a synthetic/fallback ad placeholder.
          // Reserve no space until a real banner has loaded.
          return const SizedBox.shrink();
        }

        final resolvedPadding =
            widget.padding.resolve(Directionality.of(context));
        final totalHeight = size.height.toDouble() +
            resolvedPadding.top +
            resolvedPadding.bottom;

        return SizedBox(
          width: double.infinity,
          height: totalHeight,
          child: Padding(
            padding: widget.padding,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: size.width.toDouble(),
                height: size.height.toDouble(),
                child: AdWidget(ad: ad),
              ),
            ),
          ),
        );
      },
    );
  }

  double _horizontalPadding(EdgeInsetsGeometry padding) {
    final resolved = padding.resolve(Directionality.of(context));
    return resolved.left + resolved.right;
  }
}

class _AdPlaceholder extends StatelessWidget {
  final String tabKey;

  const _AdPlaceholder({required this.tabKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.campaign,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ad placeholder • ${_label(tabKey)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w700,
                fontSize: 12.8,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withValues(alpha: 0.10),
            ),
            child: const Text(
              'Sponsored',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label(String value) => value.trim().isEmpty ? 'home' : value;
}
