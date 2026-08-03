import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../bridge/tool_bridge_launcher.dart';
import '../bridge/tool_bridge_payload.dart';
import '../bridge/tool_bridge_registry.dart';
import '../capabilities/app_engine_capability_registry.dart';
import '../models/dynamic_action_payload.dart';
import '../models/native_engine_action.dart';
import '../registry/action_type_registry.dart';
import '../registry/native_engine_registry.dart';
import 'native_engine_launcher.dart';

class DynamicActionExecutor {
  const DynamicActionExecutor._();

  static Future<bool> execute(
    BuildContext context,
    DynamicActionPayload payload,
  ) async {
    final normalizedEngine = NativeEngineRegistry.normalizeEngine(payload.engine);
    final appType = _appTypeFromPayload(payload);

    final payloadExtra = {
      ...payload.extra,
      'app_type': appType,
      if (normalizedEngine.isNotEmpty) 'engine': normalizedEngine,
    };

    if (normalizedEngine.isNotEmpty &&
        ToolBridgeRegistry.isBridgeEngine(normalizedEngine)) {
      final launched = ToolBridgeLauncher.launch(
        context,
        ToolBridgePayload.fromMap(payloadExtra),
      );

      if (launched) {
        return true;
      }
    }

    if (normalizedEngine.isNotEmpty) {
      final capabilityAllowed = _isEngineAllowedForAppType(
        appType: appType,
        engine: normalizedEngine,
      );

      if (capabilityAllowed || NativeEngineRegistry.isKnown(normalizedEngine)) {
        final launched = NativeEngineLauncher.launch(
          context,
          NativeEngineAction(
            engine: normalizedEngine,
            route: payload.route,
            title: payload.title,
            url: payload.url,
            contentId: payload.contentId,
            bucket: payload.bucket,
            extra: payloadExtra,
          ),
        );

        if (launched) {
          return true;
        }
      }
    }

    if (payload.hasRoute) {
      context.push(
        payload.route,
        extra: payloadExtra,
      );

      return true;
    }

    if (payload.hasUrl) {
      context.push(
        '/web',
        extra: {
          'title': payload.title,
          'url': payload.url,
          ...payloadExtra,
        },
      );

      return true;
    }

    if (payload.contentId.trim().isNotEmpty) {
      context.push(
        '/articles/detail',
        extra: {
          ...payloadExtra,
          'id': payload.contentId.trim(),
          'content_id': payload.contentId.trim(),
        },
      );

      return true;
    }

    return false;
  }

  static Future<bool> executeMap(
    BuildContext context,
    Map<String, dynamic> map,
  ) async {
    return execute(
      context,
      DynamicActionPayload.fromMap(map),
    );
  }

  static DynamicActionPayload fromCard(
    dynamic card,
  ) {
    final map = <String, dynamic>{};

    try {
      final raw = card.raw;
      if (raw is Map<String, dynamic>) {
        map.addAll(raw);
      }
    } catch (_) {}

    try {
      map['route'] = card.route;
    } catch (_) {}

    try {
      map['url'] = card.url;
    } catch (_) {}

    try {
      map['title'] = card.title;
    } catch (_) {}

    try {
      map['engine'] = card.engine;
    } catch (_) {}

    try {
      map['content_id'] = card.key;
    } catch (_) {}

    return DynamicActionPayload.fromMap(map);
  }

  static bool shouldUseNativeEngine(
    DynamicActionPayload payload,
  ) {
    if (payload.hasEngine) {
      return true;
    }

    final type = payload.type.trim().toLowerCase();

    return ActionTypeRegistry.isNativeEngine(type) ||
        ActionTypeRegistry.isVideo(type) ||
        ActionTypeRegistry.isArticle(type) ||
        ActionTypeRegistry.isShorts(type);
  }

  static String _appTypeFromPayload(
    DynamicActionPayload payload,
  ) {
    final rawValues = [
      payload.extra['app_type'],
      payload.extra['appType'],
      payload.extra['template_type'],
      payload.extra['template'],
      payload.extra['capability'],
      payload.extra['category'],
    ];

    for (final value in rawValues) {
      final text = (value ?? '').toString().trim().toLowerCase();

      if (text.isNotEmpty) {
        return text.replaceAll('-', '_');
      }
    }

    return 'tv';
  }

  static bool _isEngineAllowedForAppType({
    required String appType,
    required String engine,
  }) {
    if (engine.trim().isEmpty) {
      return false;
    }

    return AppEngineCapabilityRegistry.supportsEngine(
      appType: appType,
      engine: engine,
    );
  }
}
