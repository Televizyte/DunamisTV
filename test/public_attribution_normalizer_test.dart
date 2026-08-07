import 'package:dunamis_tv/ui/shared/designers/public_attribution_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PublicAttributionNormalizer accepts public attribution', () {
    const longSource =
        'Dunamis International Gospel Centre Worldwide Media and Publications';

    for (final value in const <String>[
      'Dr Paul Enenche',
      'Psalm 23:1',
      'José Álvarez — 恩典',
      longSource,
      "Faith & Victory (Vol. 2) — Pastor's Notes",
    ]) {
      test(value, () {
        expect(PublicAttributionNormalizer.normalize(value), value);
      });
    }

    test('trims surrounding whitespace without truncating', () {
      expect(
        PublicAttributionNormalizer.normalize('  Seeds of Destiny  '),
        'Seeds of Destiny',
      );
      expect(PublicAttributionNormalizer.normalize(longSource), longSource);
    });
  });

  group('PublicAttributionNormalizer rejects non-public values', () {
    final values = <Object?>[
      null,
      '',
      '   ',
      <String, Object?>{'source': 'Dr Paul Enenche'},
      <String>['Dr Paul Enenche'],
      <String>{'Dr Paul Enenche'},
      _TechnicalObject(),
      23,
      true,
      'null',
      'undefined',
      'N/A',
      'NA',
      'none',
      'unknown',
      'not available',
      'not applicable',
      '-',
      '--',
      '{}',
      '[]',
      '{"source":"Dr Paul Enenche"}',
      '["Psalm 23:1"]',
      '{not valid json',
      '[not valid json',
      'Instance of SourceMetadata',
      'Exception: backend failed',
      'SQLSTATE connection failure',
      'Stack trace: frame 1',
      'Internal server error',
      'Object instance returned by parser',
      'PlatformException(source unavailable)',
      'Fatal error while loading source',
      'RenderFlex overflow by 20 pixels',
    ];

    for (final value in values) {
      test('$value', () {
        expect(PublicAttributionNormalizer.normalize(value), isNull);
      });
    }
  });
}

class _TechnicalObject {
  @override
  String toString() => 'Dr Paul Enenche';
}
