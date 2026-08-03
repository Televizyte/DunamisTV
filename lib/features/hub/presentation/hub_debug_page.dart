import 'package:flutter/material.dart';
import '../hub_controller.dart';

class HubDebugPage extends StatefulWidget {
  const HubDebugPage({super.key, required this.controller});
  final HubController controller;

  @override
  State<HubDebugPage> createState() => _HubDebugPageState();
}

class _HubDebugPageState extends State<HubDebugPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    widget.controller.init();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final cfg = c.config;

    return Scaffold(
      appBar: AppBar(
        title: Text(cfg?.appName ?? 'Hub Config (Loading...)'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: c.loading ? null : () => c.refresh(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Clear Cache',
            onPressed: c.loading ? null : () => c.clearCache(),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _row('Platform Slug', c.platformSlug),
            _row('Loading', c.loading.toString()),
            _row('Saved At', c.lastSavedAt?.toIso8601String() ?? '-'),
            if (c.error != null) ...[
              const SizedBox(height: 12),
              Text(
                'Error: ${c.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
            const Divider(height: 28),

            Text('Watch', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _row('HLS URL', cfg?.watchHlsUrl ?? '-'),
            _row('YouTube URL', cfg?.watchYoutubeUrl ?? '-'),

            const Divider(height: 28),
            Text('Watch Settings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _row('show_share', (cfg?.showShare).toString()),
            _row('show_reactions', (cfg?.showReactions).toString()),
            _row('allow_comments', (cfg?.allowComments).toString()),
            _row('show_live_badge', (cfg?.showLiveBadge).toString()),
            _row('force_signin_for_actions', (cfg?.forceSigninForActions).toString()),

            const Divider(height: 28),
            Text('Ads', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _row('enabled_global', (cfg?.adsEnabledGlobal).toString()),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 160, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
