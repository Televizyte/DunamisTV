import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../kingdom_builder/config/kingdom_builder_config.dart';
import '../../../kingdom_builder/state/kingdom_builder_controller.dart';

class KingdomBuilderScreen extends StatefulWidget {
  final KingdomBuilderConfig config;

  const KingdomBuilderScreen({
    super.key,
    this.config = const KingdomBuilderConfig(),
  });

  @override
  State<KingdomBuilderScreen> createState() => _KingdomBuilderScreenState();
}

class _KingdomBuilderScreenState extends State<KingdomBuilderScreen>
    with WidgetsBindingObserver {
  late final KingdomBuilderController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = KingdomBuilderController()..addListener(_refresh);
    _controller.initialise();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final state = _controller.state;

    return Scaffold(
      backgroundColor: const Color(0xFF07131F),
      appBar: AppBar(
        backgroundColor: config.primaryColor,
        foregroundColor: Colors.white,
        title: Text(config.displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/games'),
        ),
        actions: [
          IconButton(
            tooltip: 'Reset local progress',
            onPressed: state == null ? null : _confirmReset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: _controller.loading && state == null
          ? const Center(child: CircularProgressIndicator())
          : state == null
              ? _ErrorState(
                  message: _controller.error ?? 'Unable to load the game.')
              : SafeArea(
                  child: Column(
                    children: [
                      _ResourceHeader(
                        level: state.ministryLevel,
                        funds: state.ministryFunds,
                        faith: state.faith,
                        impact: state.impact,
                        accentColor: config.accentColor,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _WorldFoundationCard(
                                stageName: state.stageName,
                                foundationStarted: state.foundationStarted,
                                primaryColor: config.primaryColor,
                                secondaryColor: config.secondaryColor,
                                accentColor: config.accentColor,
                              ),
                              const SizedBox(height: 14),
                              _MissionCard(
                                foundationStarted: state.foundationStarted,
                                members: state.members,
                                workers: state.workers,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionCard(
                                      title: state.foundationStarted
                                          ? 'Foundation Ready'
                                          : 'Start Foundation',
                                      subtitle: state.foundationStarted
                                          ? 'The first ministry plot is active.'
                                          : 'Use 500 Funds to prepare the first plot.',
                                      icon: Icons.foundation_rounded,
                                      enabled: !state.foundationStarted &&
                                          state.ministryFunds >= 500,
                                      onTap: _controller.startFoundation,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _ActionCard(
                                      title: 'Welcome Visitors',
                                      subtitle:
                                          'Grow the first community around the ministry.',
                                      icon: Icons.groups_rounded,
                                      enabled: state.foundationStarted,
                                      onTap: _controller.welcomeVisitors,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: const _GameNavigationBar(),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Kingdom Builder?'),
        content: const Text(
            'This clears the local foundation progress on this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed == true) await _controller.reset();
  }
}

class _ResourceHeader extends StatelessWidget {
  final int level;
  final int funds;
  final int faith;
  final int impact;
  final Color accentColor;

  const _ResourceHeader({
    required this.level,
    required this.funds,
    required this.faith,
    required this.impact,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      color: const Color(0xFF0D2032),
      child: Row(
        children: [
          _Metric(
              icon: Icons.workspace_premium_rounded,
              label: 'Level',
              value: '$level',
              color: accentColor),
          _Metric(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Funds',
              value: '$funds',
              color: const Color(0xFF65C18C)),
          _Metric(
              icon: Icons.auto_awesome_rounded,
              label: 'Faith',
              value: '$faith',
              color: const Color(0xFFF3D27A)),
          _Metric(
              icon: Icons.public_rounded,
              label: 'Impact',
              value: '$impact',
              color: const Color(0xFF78B7FF)),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _Metric(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .62), fontSize: 10)),
        ],
      ),
    );
  }
}

class _WorldFoundationCard extends StatelessWidget {
  final String stageName;
  final bool foundationStarted;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  const _WorldFoundationCard({
    required this.stageName,
    required this.foundationStarted,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 330,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor, const Color(0xFF385B3D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
                painter:
                    _FoundationWorldPainter(accentColor, foundationStarted)),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .32),
                  borderRadius: BorderRadius.circular(16)),
              child: Text(stageName,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Text(
              foundationStarted
                  ? 'The first ministry plot is prepared. The next build phase will add the fellowship shelter and construction engine.'
                  : 'An undeveloped ministry compound awaiting its first foundation.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .88),
                  fontWeight: FontWeight.w700,
                  height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoundationWorldPainter extends CustomPainter {
  final Color accent;
  final bool active;

  _FoundationWorldPainter(this.accent, this.active);

  @override
  void paint(Canvas canvas, Size size) {
    final ground = Paint()
      ..color = const Color(0xFF5F7E4D).withValues(alpha: .72);
    final path = Path()
      ..moveTo(size.width * .08, size.height * .56)
      ..lineTo(size.width * .52, size.height * .33)
      ..lineTo(size.width * .92, size.height * .54)
      ..lineTo(size.width * .48, size.height * .78)
      ..close();
    canvas.drawPath(path, ground);

    final road = Paint()
      ..color = const Color(0xFFCFBE98).withValues(alpha: .75);
    final roadPath = Path()
      ..moveTo(size.width * .42, size.height)
      ..lineTo(size.width * .52, size.height * .54)
      ..lineTo(size.width * .60, size.height * .58)
      ..lineTo(size.width * .58, size.height)
      ..close();
    canvas.drawPath(roadPath, road);

    final plot = Paint()
      ..color = active
          ? accent.withValues(alpha: .80)
          : Colors.white.withValues(alpha: .20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final plotPath = Path()
      ..moveTo(size.width * .30, size.height * .50)
      ..lineTo(size.width * .50, size.height * .39)
      ..lineTo(size.width * .70, size.height * .50)
      ..lineTo(size.width * .50, size.height * .62)
      ..close();
    canvas.drawPath(plotPath, plot);

    if (active) {
      final foundation = Paint()..color = const Color(0xFFE7E0D3);
      final foundationPath = Path()
        ..moveTo(size.width * .36, size.height * .50)
        ..lineTo(size.width * .50, size.height * .43)
        ..lineTo(size.width * .64, size.height * .50)
        ..lineTo(size.width * .50, size.height * .58)
        ..close();
      canvas.drawPath(foundationPath, foundation);
    }
  }

  @override
  bool shouldRepaint(covariant _FoundationWorldPainter oldDelegate) =>
      oldDelegate.active != active || oldDelegate.accent != accent;
}

class _MissionCard extends StatelessWidget {
  final bool foundationStarted;
  final int members;
  final int workers;

  const _MissionCard(
      {required this.foundationStarted,
      required this.members,
      required this.workers});

  @override
  Widget build(BuildContext context) {
    final progress = foundationStarted ? .66 : .33;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10263A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FOUNDATION MISSION',
              style: TextStyle(
                  color: Color(0xFFC8952E),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8)),
          const SizedBox(height: 7),
          const Text('Establish the first fellowship',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 12),
          Text(
              'Members: $members  •  Workers: $workers  •  Foundation: ${foundationStarted ? 'Ready' : 'Pending'}',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .72),
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final Future<void> Function() onTap;

  const _ActionCard(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.enabled,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? const Color(0xFF17364F) : const Color(0xFF111C26),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: enabled ? () => onTap() : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  color: enabled ? const Color(0xFFC8952E) : Colors.white38),
              const SizedBox(height: 12),
              Text(title,
                  style: TextStyle(
                      color: enabled ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(subtitle,
                  style: TextStyle(
                      color:
                          Colors.white.withValues(alpha: enabled ? .65 : .34),
                      fontSize: 12,
                      height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameNavigationBar extends StatelessWidget {
  const _GameNavigationBar();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF0D2032),
      selectedItemColor: const Color(0xFFC8952E),
      unselectedItemColor: Colors.white54,
      onTap: (_) {},
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_work_rounded), label: 'World'),
        BottomNavigationBarItem(
            icon: Icon(Icons.add_business_rounded), label: 'Build'),
        BottomNavigationBarItem(
            icon: Icon(Icons.groups_rounded), label: 'People'),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_tree_rounded), label: 'Departments'),
        BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_rounded), label: 'More'),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}
