import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

abstract class AdConsentPlatform {
  Future<void> requestConsentInfoUpdate();
  Future<void> loadAndShowConsentFormIfRequired();
  Future<bool> canRequestAds();
  Future<PrivacyOptionsRequirementStatus> privacyOptionsRequirementStatus();
  Future<void> showPrivacyOptionsForm();
}

class GoogleAdConsentPlatform implements AdConsentPlatform {
  @override
  Future<void> requestConsentInfoUpdate() {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      completer.complete,
      completer.completeError,
    );
    return completer.future;
  }

  @override
  Future<void> loadAndShowConsentFormIfRequired() {
    final completer = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(error);
      }
    });
    return completer.future;
  }

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  @override
  Future<PrivacyOptionsRequirementStatus> privacyOptionsRequirementStatus() =>
      ConsentInformation.instance.getPrivacyOptionsRequirementStatus();

  @override
  Future<void> showPrivacyOptionsForm() {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((error) {
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(error);
      }
    });
    return completer.future;
  }
}

class AdConsentService extends ChangeNotifier {
  AdConsentService({AdConsentPlatform? platform})
      : _platform = platform ?? GoogleAdConsentPlatform();

  static final AdConsentService instance = AdConsentService();
  static const Duration _operationTimeout = Duration(seconds: 15);

  final AdConsentPlatform _platform;
  Future<bool>? _gathering;
  bool _canRequestAds = false;
  PrivacyOptionsRequirementStatus _privacyOptionsRequirementStatus =
      PrivacyOptionsRequirementStatus.unknown;

  bool get canRequestAds => _canRequestAds;
  bool get privacyOptionsRequired =>
      _privacyOptionsRequirementStatus ==
      PrivacyOptionsRequirementStatus.required;

  Future<bool> gatherConsent() {
    return _gathering ??= _gatherConsent();
  }

  Future<bool> _gatherConsent() async {
    if (kIsWeb) {
      _update(canRequestAds: true);
      return true;
    }

    try {
      await _platform.requestConsentInfoUpdate().timeout(_operationTimeout);
      await _platform
          .loadAndShowConsentFormIfRequired()
          .timeout(_operationTimeout);
    } catch (_) {
      // A cached consent decision may still permit requests. Query it below.
    }

    await _refreshStatus();
    return _canRequestAds;
  }

  Future<void> _refreshStatus() async {
    var canRequest = false;
    var privacyStatus = PrivacyOptionsRequirementStatus.unknown;

    try {
      canRequest = await _platform.canRequestAds().timeout(_operationTimeout);
    } catch (_) {}
    try {
      privacyStatus = await _platform
          .privacyOptionsRequirementStatus()
          .timeout(_operationTimeout);
    } catch (_) {}

    _update(
      canRequestAds: canRequest,
      privacyOptionsRequirementStatus: privacyStatus,
    );
  }

  Future<bool> showPrivacyOptions() async {
    if (!privacyOptionsRequired || kIsWeb) return false;

    try {
      await _platform.showPrivacyOptionsForm().timeout(_operationTimeout);
    } catch (_) {
      return false;
    } finally {
      await _refreshStatus();
    }
    return true;
  }

  void _update({
    required bool canRequestAds,
    PrivacyOptionsRequirementStatus? privacyOptionsRequirementStatus,
  }) {
    final changed = _canRequestAds != canRequestAds ||
        (privacyOptionsRequirementStatus != null &&
            _privacyOptionsRequirementStatus !=
                privacyOptionsRequirementStatus);
    _canRequestAds = canRequestAds;
    if (privacyOptionsRequirementStatus != null) {
      _privacyOptionsRequirementStatus = privacyOptionsRequirementStatus;
    }
    if (changed) notifyListeners();
  }
}
