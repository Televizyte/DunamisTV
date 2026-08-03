import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/app_auth_service.dart';
import '../../../theme/theme_controller.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    AppAuthState.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation:
          Listenable.merge([ThemeController.instance, AppAuthState.instance]),
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;
        final panelBg =
            isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430);
        final panelAlt =
            isLight ? const Color(0xFFF2E8D8) : const Color(0xFF151C3A);
        final border =
            isLight ? const Color(0xFFE6D8C3) : Colors.white.withOpacity(0.08);
        final titleColor =
            isLight ? const Color(0xFF1E1B16) : Colors.white.withOpacity(0.94);
        final bodyColor =
            isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.72);
        final auth = AppAuthState.instance;

        return Scaffold(
          appBar:
              const DxmTopBar(title: 'Account', showBack: true, showMenu: true),
          body: GradientPageBackground(
            child: auth.isLoaded
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                    children: auth.isSignedIn
                        ? _signedInCards(
                            panelBg, panelAlt, border, titleColor, bodyColor)
                        : _guestCards(
                            panelBg, panelAlt, border, titleColor, bodyColor),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  List<Widget> _guestCards(Color panelBg, Color panelAlt, Color border,
          Color titleColor, Color bodyColor) =>
      [
        _HeaderCard(
          title: 'Account Access',
          subtitle:
              'Sign in to use likes, comments, follows, saved activity, and personalized updates.',
          icon: Icons.person_rounded,
          panelBg: panelBg,
          border: border,
          titleColor: titleColor,
          bodyColor: bodyColor,
        ),
        const SizedBox(height: 14),
        _AccountActionCard(
          title: 'Sign In',
          subtitle: 'Continue with your app account',
          icon: Icons.login_rounded,
          panelBg: panelBg,
          border: border,
          titleColor: titleColor,
          bodyColor: bodyColor,
          onTap: _showLogin,
        ),
        const SizedBox(height: 12),
        _AccountActionCard(
          title: 'Create Account',
          subtitle: 'Create a profile for community features',
          icon: Icons.app_registration_rounded,
          panelBg: panelAlt,
          border: border,
          titleColor: titleColor,
          bodyColor: bodyColor,
          onTap: _showRegister,
        ),
        const SizedBox(height: 12),
        _AccountActionCard(
          title: 'Continue as Guest',
          subtitle: 'Watch, read, and use available tools without signing in',
          icon: Icons.visibility_rounded,
          panelBg: panelBg,
          border: border,
          titleColor: titleColor,
          bodyColor: bodyColor,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ];

  List<Widget> _signedInCards(Color panelBg, Color panelAlt, Color border,
      Color titleColor, Color bodyColor) {
    final user = AppAuthState.instance.user!;
    return [
      _HeaderCard(
        title: user.name.isEmpty ? 'My Account' : user.name,
        subtitle: user.email,
        icon: Icons.verified_user_rounded,
        panelBg: panelBg,
        border: border,
        titleColor: titleColor,
        bodyColor: bodyColor,
      ),
      const SizedBox(height: 14),
      _AccountActionCard(
        title: 'Saved Content',
        subtitle: 'Open your saved items and bookmarks',
        icon: Icons.bookmark_rounded,
        panelBg: panelBg,
        border: border,
        titleColor: titleColor,
        bodyColor: bodyColor,
        onTap: () => Navigator.of(context).pushNamed('/saved'),
      ),
      const SizedBox(height: 12),
      _AccountActionCard(
        title: 'Privacy & Account Deletion',
        subtitle: 'Review deletion options or permanently delete this account',
        icon: Icons.privacy_tip_rounded,
        panelBg: panelAlt,
        border: border,
        titleColor: titleColor,
        bodyColor: bodyColor,
        onTap: _showDeletionOptions,
      ),
      const SizedBox(height: 12),
      _AccountActionCard(
        title: 'Sign Out',
        subtitle: 'End this signed-in session on this device',
        icon: Icons.logout_rounded,
        panelBg: panelBg,
        border: border,
        titleColor: titleColor,
        bodyColor: bodyColor,
        onTap: _busy ? null : _logout,
      ),
    ];
  }

  Future<void> _showLogin() async {
    final email = TextEditingController();
    final password = TextEditingController();
    await _showAuthDialog(
      title: 'Sign In',
      fields: [
        _DialogField(
            controller: email,
            label: 'Email',
            keyboardType: TextInputType.emailAddress),
        _DialogField(
            controller: password, label: 'Password', obscureText: true),
      ],
      submitLabel: 'Sign In',
      onSubmit: () => AppAuthService.instance.login(email.text, password.text),
    );
  }

  Future<void> _showRegister() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    await _showAuthDialog(
      title: 'Create Account',
      fields: [
        _DialogField(controller: name, label: 'Name'),
        _DialogField(
            controller: email,
            label: 'Email',
            keyboardType: TextInputType.emailAddress),
        _DialogField(
            controller: password,
            label: 'Password (minimum 8 characters)',
            obscureText: true),
      ],
      submitLabel: 'Create Account',
      onSubmit: () => AppAuthService.instance
          .register(name.text, email.text, password.text),
    );
  }

  Future<void> _showAuthDialog({
    required String title,
    required List<_DialogField> fields,
    required String submitLabel,
    required Future<AppUser> Function() onSubmit,
  }) async {
    String? error;
    final passwordVisibility = <TextEditingController, bool>{};
    await showDialog<void>(
      context: context,
      barrierDismissible: !_busy,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in fields) ...[
                  TextField(
                    controller: field.controller,
                    obscureText: field.obscureText
                        ? !(passwordVisibility[field.controller] ?? false)
                        : false,
                    keyboardType: field.keyboardType,
                    decoration: InputDecoration(
                      labelText: field.label,
                      suffixIcon: field.obscureText
                          ? IconButton(
                              tooltip: (passwordVisibility[field.controller] ??
                                      false)
                                  ? 'Hide password'
                                  : 'Show password',
                              onPressed: _busy
                                  ? null
                                  : () => setDialogState(() {
                                        passwordVisibility[field.controller] =
                                            !(passwordVisibility[
                                                    field.controller] ??
                                                false);
                                      }),
                              icon: Icon(
                                (passwordVisibility[field.controller] ?? false)
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (title == 'Sign In')
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password recovery is being connected. Use your existing password for this test.',
                                  ),
                                ),
                              );
                            },
                      child: const Text('Forgot password?'),
                    ),
                  ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: _busy ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      setDialogState(() => error = null);
                      try {
                        await onSubmit();
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      } catch (e) {
                        setDialogState(() => error = e.toString());
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Text(_busy ? 'Please wait…' : submitLabel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    setState(() => _busy = true);
    try {
      await AppAuthService.instance.logout();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showDeletionOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delete Account',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              const Text(
                  'Deletion permanently removes your app account data, including likes, comments, saves, follows, progress, and registered devices. This action cannot be undone.'),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final uri =
                        Uri.parse(AppAuthService.instance.publicDeletionUrl());
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: const Text('Open Web Deletion Request'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _confirmPermanentDeletion();
                  },
                  child: const Text('Delete Account in App'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmPermanentDeletion() async {
    final password = TextEditingController();
    bool confirmed = false;
    String? error;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Permanent Account Deletion'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Enter your password and confirm that you understand this action is permanent.'),
                const SizedBox(height: 14),
                TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password')),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: confirmed,
                  onChanged: (value) =>
                      setDialogState(() => confirmed = value ?? false),
                  title: const Text(
                      'I understand that my account data will be permanently deleted.'),
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: _busy ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: !confirmed || _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        await AppAuthService.instance
                            .deleteAccount(password.text);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Account deleted successfully.')));
                        }
                      } catch (e) {
                        setDialogState(() => error = e.toString());
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Text(_busy ? 'Deleting…' : 'Delete Permanently'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogField {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType keyboardType;
  const _DialogField(
      {required this.controller,
      required this.label,
      this.obscureText = false,
      this.keyboardType = TextInputType.text});
}

class _HeaderCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color panelBg, border, titleColor, bodyColor;
  const _HeaderCard(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.panelBg,
      required this.border,
      required this.titleColor,
      required this.bodyColor});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: panelBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border)),
        child: Row(children: [
          Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [Color(0xFF1A1F5A), Color(0xFFB70E7C)])),
              child: Icon(icon, color: Colors.white, size: 30)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(subtitle,
                    style: TextStyle(
                        color: bodyColor,
                        fontSize: 12.7,
                        height: 1.35,
                        fontWeight: FontWeight.w600)),
              ])),
        ]),
      );
}

class _AccountActionCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color panelBg, border, titleColor, bodyColor;
  final VoidCallback? onTap;
  const _AccountActionCard(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.panelBg,
      required this.border,
      required this.titleColor,
      required this.bodyColor,
      required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: panelBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border)),
          child: Row(children: [
            Icon(icon, color: titleColor, size: 24),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: TextStyle(
                          color: titleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: TextStyle(
                          color: bodyColor,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600)),
                ])),
            Icon(Icons.chevron_right_rounded, color: bodyColor),
          ]),
        ),
      );
}
