import '../app_config.dart';
import 'brand_config.dart';
import 'celebration_brand.dart';
import 'dunamis_brand.dart';

class BrandSelector {
  const BrandSelector._();

  static const String defaultFlavor = 'dunamis';

  static void applyFromEnvironment() {
    const flavor = String.fromEnvironment(
      'APP_FLAVOR',
      defaultValue: defaultFlavor,
    );

    apply(flavor);
  }

  static void apply(String flavor) {
    AppConfig.setBrand(resolve(flavor));
  }

  static BrandConfig resolve(String flavor) {
    final normalized = flavor.trim().toLowerCase().replaceAll('_', '-');

    switch (normalized) {
      case 'celebration':
      case 'celebration-tv':
        return CelebrationBrandConfig.instance;

      case 'dunamis':
      case 'dunamis-tv':
      default:
        return DunamisBrandConfig.instance;
    }
  }
}
