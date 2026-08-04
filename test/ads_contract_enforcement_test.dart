import 'package:dunamis_tv/features/hub/models/dynamic_section.dart';
import 'package:dunamis_tv/features/hub/renderer/dynamic_section_renderer.dart';
import 'package:dunamis_tv/features/hub/state/hub_store.dart';
import 'package:dunamis_tv/services/ads_service.dart';
import 'package:dunamis_tv/ui/widgets/ads/native_list_injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ads = AdsService.instance;

  setUp(ads.clearBootstrap);
  tearDown(ads.clearBootstrap);

  test('fresh policy replaces active eligibility immediately', () {
    ads.applyBootstrap(_bootstrap(homeBanner: true));
    expect(ads.bannerAllowedForTab('home'), isTrue);

    ads.applyBootstrap(_bootstrap(homeBanner: false));
    expect(ads.bannerAllowedForTab('home'), isFalse);
  });

  test('HubStore refresh applies policy before publishing refreshed state', () {
    ads.applyBootstrap(_bootstrap(homeBanner: false));
    final store = HubStore();
    addTearDown(store.dispose);

    store.applyRefreshedAdPolicy(_bootstrap(homeBanner: true));

    expect(ads.bannerAllowedForTab('home'), isTrue);
  });

  test('missing or malformed ads clears an old enabled policy', () {
    ads.applyBootstrap(_bootstrap(homeBanner: true));
    final revision = ads.policyRevision.value;

    ads.applyBootstrap(<String, dynamic>{});

    expect(ads.bannerAllowedForTab('home'), isFalse);
    expect(ads.nativeAllowedForTab('home'), isFalse);
    expect(ads.interstitialAllowedForTab('home'), isFalse);
    expect(ads.policyRevision.value, greaterThan(revision));
  });

  test('structurally invalid nested ads clears old authorization', () {
    ads.applyBootstrap(_bootstrap(homeBanner: true));

    ads.applyBootstrap(<String, dynamic>{
      'ads': <String, dynamic>{
        'enabled': true,
        'formats': <String, dynamic>{'banner': 'invalid'},
        'units': <String, dynamic>{},
        'tabs': <String, dynamic>{},
        'native_in_list': <String, dynamic>{},
        'interstitial': <String, dynamic>{},
      },
    });

    expect(ads.bannerAllowedForTab('home'), isFalse);
    expect(ads.nativeAllowedForTab('home'), isFalse);
    expect(ads.interstitialAllowedForTab('home'), isFalse);
  });

  test('master false disables every format', () {
    ads.applyBootstrap(_bootstrap(masterEnabled: false, homeBanner: true));

    expect(ads.bannerAllowedForTab('home'), isFalse);
    expect(ads.nativeAllowedForTab('home'), isFalse);
    expect(ads.interstitialAllowedForTab('home'), isFalse);
  });

  test('null production units remain unavailable', () {
    ads.applyBootstrap(_bootstrap(units: const <String, dynamic>{
      'banner': null,
      'native': ' ',
      'interstitial': null,
    }));

    expect(ads.hasUnitForFormat('banner', debug: false), isFalse);
    expect(ads.hasUnitForFormat('native', debug: false), isFalse);
    expect(ads.hasUnitForFormat('interstitial', debug: false), isFalse);
  });

  test('exact route denial blocks parent shell banner', () {
    ads.applyBootstrap(_bootstrap(
      extraPolicies: <String, dynamic>{
        'explore.books.reader': _policy(
          banner: false,
          placement: 'disabled',
        ),
      },
    ));

    expect(ads.bannerAllowedForPlacement('explore', 'shell_bottom'), isTrue);
    expect(
      ads.bannerAllowedForPlacement(
        'explore.books.reader',
        'shell_bottom',
      ),
      isFalse,
    );
  });

  test('page-bottom policy cannot render through shell placement', () {
    ads.applyBootstrap(_bootstrap(
      extraPolicies: <String, dynamic>{
        'explore.notes': _policy(banner: true, placement: 'page_bottom'),
      },
    ));

    expect(
      ads.bannerAllowedForPlacement('explore.notes', 'shell_bottom'),
      isFalse,
    );
    expect(
      ads.bannerAllowedForPlacement('explore.notes', 'page_bottom'),
      isTrue,
    );
  });

  test('native zero cap is unlimited and positive cap is enforced', () {
    ads.applyBootstrap(_bootstrap(
      nativeMaxPerList: 0,
      nativeEvery: 1,
      nativeStartAfter: 0,
    ));
    final unlimited = NativeListInjection.buildEntries<int>(
      List<int>.generate(6, (index) => index),
      tabKey: 'home',
    );
    expect(unlimited.where((entry) => entry.isAd), hasLength(5));

    ads.applyBootstrap(_bootstrap(
      nativeMaxPerList: 2,
      nativeEvery: 1,
      nativeStartAfter: 0,
    ));
    final capped = NativeListInjection.buildEntries<int>(
      List<int>.generate(6, (index) => index),
      tabKey: 'home',
    );
    expect(capped.where((entry) => entry.isAd), hasLength(2));
    expect(
      ads.shouldInsertNativeAfterItem(tabKey: 'home', itemIndex: 4),
      isFalse,
    );
    expect(
      ads.shouldInsertNativeAfterItem(tabKey: 'home', itemIndex: 0),
      isTrue,
    );
  });

  test('parent native disable overrides global insertion enable', () {
    ads.applyBootstrap(_bootstrap(extraPolicies: <String, dynamic>{
      'home.reader': <String, dynamic>{
        'enabled': true,
        'banner': false,
        'native': true,
        'interstitial': false,
      },
      'home': _policy(
        banner: true,
        placement: 'shell_bottom',
        nativeConfig: const <String, dynamic>{
          'enabled': false,
          'every': 1,
          'start_after': 0,
          'max_per_list': 0,
        },
      ),
    }));

    expect(ads.nativeInListAllowedForTab('home.reader'), isFalse);
  });

  test('parent interstitial cooldown overrides global cooldown', () {
    ads.applyBootstrap(_bootstrap(extraPolicies: <String, dynamic>{
      'home.reader': <String, dynamic>{
        'enabled': true,
        'banner': false,
        'native': false,
        'interstitial': true,
      },
      'home': _policy(
        banner: true,
        placement: 'shell_bottom',
        interstitialConfig: const <String, dynamic>{
          'enabled': true,
          'cooldown_seconds': 15,
          'every_n_safe_actions': 2,
          'minimum_launch_delay_seconds': 0,
          'maximum_per_session': 0,
          'minimum_page_dwell_seconds': 0,
        },
      ),
    }));

    expect(
      ads.interstitialCooldownForTab('home.reader'),
      const Duration(seconds: 15),
    );
  });

  test('zero session maximum is unlimited', () {
    ads.applyBootstrap(_bootstrap(maximumPerSession: 0));
    expect(
      ads.isInterstitialSessionCapReached('home', shownCount: 1000),
      isFalse,
    );
  });

  test('positive dwell blocks early and allows after elapsed duration', () {
    final enteredAt = DateTime(2026, 1, 1, 12);
    ads.applyBootstrap(_bootstrap(minimumPageDwellSeconds: 10));
    ads.markInterstitialPolicyEntered('home', enteredAt: enteredAt);

    expect(
      ads.isInterstitialDwellSatisfied(
        'home',
        now: enteredAt.add(const Duration(seconds: 9)),
      ),
      isFalse,
    );
    expect(
      ads.isInterstitialDwellSatisfied(
        'home',
        now: enteredAt.add(const Duration(seconds: 10)),
      ),
      isTrue,
    );
  });

  test('zero dwell has no restriction', () {
    ads.applyBootstrap(_bootstrap(minimumPageDwellSeconds: 0));
    expect(ads.isInterstitialDwellSatisfied('home'), isTrue);
  });

  testWidgets('malformed dynamic ad block fails closed', (tester) async {
    ads.applyBootstrap(_bootstrap());
    const section = HubDynamicSection(
      key: 'ad-without-contract-metadata',
      title: 'Sponsored',
      subtitle: '',
      layout: HubDynamicSectionLayout.adBlock,
      columns: 1,
      rows: 1,
      enabled: true,
      items: <Map<String, dynamic>>[],
      settings: <String, dynamic>{},
    );

    await tester.pumpWidget(
      const MaterialApp(home: DynamicHubSectionRenderer(section: section)),
    );

    expect(find.byType(SizedBox), findsWidgets);
    expect(find.text('Sponsored'), findsNothing);
  });
}

Map<String, dynamic> _bootstrap({
  bool masterEnabled = true,
  bool homeBanner = true,
  Map<String, dynamic>? units,
  Map<String, dynamic>? extraPolicies,
  int nativeEvery = 2,
  int nativeStartAfter = 1,
  int nativeMaxPerList = 0,
  int maximumPerSession = 0,
  int minimumPageDwellSeconds = 0,
}) {
  final nativeConfig = <String, dynamic>{
    'enabled': true,
    'every': nativeEvery,
    'start_after': nativeStartAfter,
    'max_per_list': nativeMaxPerList,
  };
  final interstitialConfig = <String, dynamic>{
    'enabled': true,
    'cooldown_seconds': 60,
    'every_n_safe_actions': 2,
    'minimum_launch_delay_seconds': 0,
    'maximum_per_session': maximumPerSession,
    'minimum_page_dwell_seconds': minimumPageDwellSeconds,
  };

  return <String, dynamic>{
    'ads': <String, dynamic>{
      'enabled': masterEnabled,
      'formats': <String, dynamic>{
        'banner': true,
        'native': true,
        'interstitial': true,
      },
      'units': units ??
          const <String, dynamic>{
            'banner': 'configured-banner',
            'native': 'configured-native',
            'interstitial': 'configured-interstitial',
          },
      'tabs': <String, dynamic>{
        'home': _policy(
          banner: homeBanner,
          placement: 'shell_bottom',
          nativeConfig: nativeConfig,
          interstitialConfig: interstitialConfig,
        ),
        'explore': _policy(
          banner: true,
          placement: 'shell_bottom',
          nativeConfig: nativeConfig,
          interstitialConfig: interstitialConfig,
        ),
        ...?extraPolicies,
      },
      'native_in_list': nativeConfig,
      'interstitial': interstitialConfig,
    },
  };
}

Map<String, dynamic> _policy({
  required bool banner,
  required String placement,
  Map<String, dynamic>? nativeConfig,
  Map<String, dynamic>? interstitialConfig,
}) {
  return <String, dynamic>{
    'enabled': true,
    'banner': banner,
    'native': true,
    'interstitial': true,
    'banner_config': <String, dynamic>{
      'placement': placement,
      'hide_on_failure': true,
      'reserve_space_before_load': false,
    },
    'native_config': nativeConfig ??
        const <String, dynamic>{
          'enabled': true,
          'every': 2,
          'start_after': 1,
          'max_per_list': 0,
        },
    'interstitial_config': interstitialConfig ??
        const <String, dynamic>{
          'enabled': true,
          'cooldown_seconds': 60,
          'every_n_safe_actions': 2,
          'minimum_launch_delay_seconds': 0,
          'maximum_per_session': 0,
          'minimum_page_dwell_seconds': 0,
        },
  };
}
