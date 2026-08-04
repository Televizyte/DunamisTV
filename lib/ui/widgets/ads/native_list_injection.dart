import '../../../services/ads_service.dart';

class NativeListEntry<T> {
  final bool isAd;
  final T? item;
  final int itemIndex;

  const NativeListEntry.item({
    required this.item,
    required this.itemIndex,
  }) : isAd = false;

  const NativeListEntry.ad({
    required this.itemIndex,
  })  : isAd = true,
        item = null;
}

class NativeListInjection {
  const NativeListInjection._();

  static List<NativeListEntry<T>> buildEntries<T>(
    List<T> items, {
    required String tabKey,
  }) {
    if (items.isEmpty) return <NativeListEntry<T>>[];

    final ads = AdsService.instance;

    if (!ads.nativeInListAllowedForTab(tabKey)) {
      return _itemOnlyEntries(items);
    }

    final every = ads.nativeEveryForPolicy(tabKey);
    final startAfter = ads.nativeStartAfterForPolicy(tabKey);
    if (every <= 0) return _itemOnlyEntries(items);

    final out = <NativeListEntry<T>>[];
    var lastAdAfterItemIndex = -9999;
    var insertedAds = 0;
    final maxPerList = ads.nativeMaxPerListForPolicy(tabKey);

    for (var i = 0; i < items.length; i++) {
      out.add(NativeListEntry<T>.item(item: items[i], itemIndex: i));

      if (i == items.length - 1) continue;

      final itemNumber = i + 1;
      final reachedStart = itemNumber >= startAfter;
      final matchesInterval = (itemNumber - startAfter) % every == 0;
      final farEnoughFromPrevious = (i - lastAdAfterItemIndex) >= every;

      final underLimit = maxPerList == 0 || insertedAds < maxPerList;

      if (reachedStart &&
          matchesInterval &&
          farEnoughFromPrevious &&
          underLimit) {
        out.add(NativeListEntry<T>.ad(itemIndex: i));
        lastAdAfterItemIndex = i;
        insertedAds++;
      }
    }

    return out;
  }

  static List<NativeListEntry<T>> _itemOnlyEntries<T>(List<T> items) {
    return List<NativeListEntry<T>>.generate(
      items.length,
      (index) => NativeListEntry<T>.item(
        item: items[index],
        itemIndex: index,
      ),
      growable: false,
    );
  }
}
