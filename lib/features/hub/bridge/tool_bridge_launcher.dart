import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'tool_bridge_payload.dart';
import 'tool_bridge_registry.dart';

class ToolBridgeLauncher {
  const ToolBridgeLauncher._();

  static bool canLaunch(String engine) {
    return ToolBridgeRegistry.isBridgeEngine(engine) &&
        ToolBridgeRegistry.routeForEngine(engine).trim().isNotEmpty;
  }

  static bool launch(
    BuildContext context,
    ToolBridgePayload payload,
  ) {
    final engine = ToolBridgeRegistry.normalize(payload.engine);
    final route = ToolBridgeRegistry.routeForEngine(engine);

    if (route.trim().isEmpty) {
      return false;
    }

    final extra = ToolBridgeRegistry.buildPayloadForEngine(
      engine,
      payload,
    );

    context.push(route, extra: extra);
    return true;
  }

  static bool launchMap(
    BuildContext context,
    Map<String, dynamic> map,
  ) {
    return launch(
      context,
      ToolBridgePayload.fromMap(map),
    );
  }
}
