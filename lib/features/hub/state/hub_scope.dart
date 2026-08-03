import 'package:flutter/material.dart';

import 'hub_store.dart';

/// InheritedNotifier wrapper around HubStore.
/// This lets UI do: final store = HubScope.of(context);
class HubScope extends InheritedNotifier<HubStore> {
  final HubStore store;

  const HubScope({
    super.key,
    required this.store,
    required Widget child,
  }) : super(notifier: store, child: child);

  static HubStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HubScope>();
    assert(scope != null, 'HubScope not found. Wrap your app with HubScope.');
    return scope!.store;
  }

  static HubStore? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HubScope>();
    return scope?.store;
  }

  @override
  bool updateShouldNotify(HubScope oldWidget) => store != oldWidget.store;
}
