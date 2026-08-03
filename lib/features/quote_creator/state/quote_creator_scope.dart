import 'package:flutter/widgets.dart';
import 'quote_creator_store.dart';

class QuoteCreatorScope extends InheritedNotifier<QuoteCreatorStore> {
  const QuoteCreatorScope({
    super.key,
    required QuoteCreatorStore store,
    required Widget child,
  }) : super(notifier: store, child: child);

  static QuoteCreatorStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<QuoteCreatorScope>();
    assert(scope != null, 'QuoteCreatorScope not found');
    return scope!.notifier!;
  }
}
