import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/native_engine_action.dart';
import '../registry/native_engine_registry.dart';

class NativeEngineLauncher {
  const NativeEngineLauncher._();

  static bool launch(
    BuildContext context,
    NativeEngineAction action,
  ) {
    final route = NativeEngineRegistry.routeForAction(action).trim();

    if (route.isEmpty) {
      return false;
    }

    final extra = _extraFor(action);

    if (extra.isEmpty) {
      context.go(route);
      return true;
    }

    context.go(route, extra: extra);
    return true;
  }

  static bool launchMap(
    BuildContext context,
    Map<String, dynamic> map,
  ) {
    return launch(
      context,
      NativeEngineAction.fromMap(map),
    );
  }

  static Map<String, dynamic> _extraFor(NativeEngineAction action) {
    final engine = NativeEngineRegistry.normalizeEngine(action.engine);
    final extra = <String, dynamic>{...action.extra};

    if (action.title.trim().isNotEmpty) {
      extra['title'] = action.title.trim();
    }

    if (action.url.trim().isNotEmpty) {
      extra['url'] = action.url.trim();
    }

    if (action.contentId.trim().isNotEmpty) {
      extra['id'] = action.contentId.trim();
      extra['content_id'] = action.contentId.trim();
    }

    if (action.bucket.trim().isNotEmpty) {
      extra['bucket'] = action.bucket.trim();
    }

    extra['engine'] = engine;

    return extra;
  }
}
