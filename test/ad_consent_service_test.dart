import 'package:dunamis_tv/services/ad_consent_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  test('requests update and required form before allowing ads', () async {
    final platform = _FakeConsentPlatform(
      canRequest: true,
      privacyStatus: PrivacyOptionsRequirementStatus.required,
    );
    final service = AdConsentService(platform: platform);

    expect(await service.gatherConsent(), isTrue);
    expect(platform.calls, <String>['update', 'form', 'canRequest', 'status']);
    expect(service.canRequestAds, isTrue);
    expect(service.privacyOptionsRequired, isTrue);
  });

  test('failure checks cached decision and fails closed without one', () async {
    final cached = AdConsentService(
      platform: _FakeConsentPlatform(canRequest: true, updateFails: true),
    );
    final denied = AdConsentService(
      platform: _FakeConsentPlatform(canRequest: false, updateFails: true),
    );

    expect(await cached.gatherConsent(), isTrue);
    expect(await denied.gatherConsent(), isFalse);
  });

  test('privacy form is exposed only when Google requires it', () async {
    final requiredPlatform = _FakeConsentPlatform(
      canRequest: true,
      privacyStatus: PrivacyOptionsRequirementStatus.required,
    );
    final required = AdConsentService(platform: requiredPlatform);
    await required.gatherConsent();
    expect(await required.showPrivacyOptions(), isTrue);
    expect(requiredPlatform.calls, contains('privacy'));

    final notRequiredPlatform = _FakeConsentPlatform(canRequest: true);
    final notRequired = AdConsentService(platform: notRequiredPlatform);
    await notRequired.gatherConsent();
    expect(await notRequired.showPrivacyOptions(), isFalse);
    expect(notRequiredPlatform.calls, isNot(contains('privacy')));
  });

  test('concurrent callers share one consent flow', () async {
    final platform = _FakeConsentPlatform(canRequest: true);
    final service = AdConsentService(platform: platform);

    await Future.wait([service.gatherConsent(), service.gatherConsent()]);
    expect(platform.calls.where((call) => call == 'update'), hasLength(1));
  });
}

class _FakeConsentPlatform implements AdConsentPlatform {
  _FakeConsentPlatform({
    required this.canRequest,
    this.privacyStatus = PrivacyOptionsRequirementStatus.notRequired,
    this.updateFails = false,
  });

  final bool canRequest;
  final PrivacyOptionsRequirementStatus privacyStatus;
  final bool updateFails;
  final List<String> calls = <String>[];

  @override
  Future<bool> canRequestAds() async {
    calls.add('canRequest');
    return canRequest;
  }

  @override
  Future<void> loadAndShowConsentFormIfRequired() async {
    calls.add('form');
  }

  @override
  Future<PrivacyOptionsRequirementStatus>
      privacyOptionsRequirementStatus() async {
    calls.add('status');
    return privacyStatus;
  }

  @override
  Future<void> requestConsentInfoUpdate() async {
    calls.add('update');
    if (updateFails) throw StateError('update failed');
  }

  @override
  Future<void> showPrivacyOptionsForm() async {
    calls.add('privacy');
  }
}
