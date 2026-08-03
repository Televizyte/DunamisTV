import 'package:flutter/material.dart';

import 'app_auth_service.dart';

enum AuthRequiredAction {
  comment,
  like,
  save,
  follow,
  report,
  reply,
  react,
  personalizedProgress,
}

extension AuthRequiredActionCopy on AuthRequiredAction {
  String get verb => switch (this) {
        AuthRequiredAction.comment => 'comment',
        AuthRequiredAction.like => 'like this content',
        AuthRequiredAction.save => 'save this content',
        AuthRequiredAction.follow => 'follow',
        AuthRequiredAction.report => 'report this content',
        AuthRequiredAction.reply => 'reply',
        AuthRequiredAction.react => 'react',
        AuthRequiredAction.personalizedProgress => 'save your progress',
      };

  String get title => switch (this) {
        AuthRequiredAction.comment => 'Sign in to comment',
        AuthRequiredAction.like => 'Sign in to like',
        AuthRequiredAction.save => 'Sign in to save',
        AuthRequiredAction.follow => 'Sign in to follow',
        AuthRequiredAction.report => 'Sign in to report',
        AuthRequiredAction.reply => 'Sign in to reply',
        AuthRequiredAction.react => 'Sign in to react',
        AuthRequiredAction.personalizedProgress => 'Sign in to sync progress',
      };
}

class AuthActionGate {
  AuthActionGate._();

  static bool _dialogOpen = false;

  static Future<bool> requireAuthentication(
    BuildContext context, {
    required AuthRequiredAction action,
  }) async {
    await AppAuthState.instance.load();
    if (AppAuthState.instance.isSignedIn) return true;
    if (_dialogOpen || !context.mounted) return false;

    _dialogOpen = true;
    try {
      final choice = await showDialog<_AuthChoice>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => _AuthRequiredDialog(action: action),
      );

      if (choice == null || !context.mounted) return false;

      return _showCredentialDialog(
        context,
        createAccount: choice == _AuthChoice.createAccount,
      );
    } finally {
      _dialogOpen = false;
    }
  }

  static Future<bool> _showCredentialDialog(
    BuildContext context, {
    required bool createAccount,
  }) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          bool busy = false;
          bool showPassword = false;
          String? error;

          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              backgroundColor: const Color(0xFF10152B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
              ),
              title: Text(
                createAccount ? 'Create your account' : 'Welcome back',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (createAccount) ...[
                      TextField(
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      onSubmitted: busy ? null : (_) {},
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          tooltip:
                              showPassword ? 'Hide password' : 'Show password',
                          onPressed: busy
                              ? null
                              : () => setState(
                                    () => showPassword = !showPassword,
                                  ),
                          icon: Icon(
                            showPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                      ),
                    ),
                    if (!createAccount)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: busy
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
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: const TextStyle(color: Color(0xFFFF7C92)),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      busy ? null : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          setState(() {
                            busy = true;
                            error = null;
                          });
                          try {
                            if (createAccount) {
                              await AppAuthService.instance.register(
                                nameController.text,
                                emailController.text,
                                passwordController.text,
                              );
                            } else {
                              await AppAuthService.instance.login(
                                emailController.text,
                                passwordController.text,
                              );
                            }
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (exception) {
                            setState(() {
                              busy = false;
                              error = exception.toString();
                            });
                          }
                        },
                  child: Text(
                    busy
                        ? 'Please wait…'
                        : createAccount
                            ? 'Create Account'
                            : 'Sign In',
                  ),
                ),
              ],
            ),
          );
        },
      );
      return result ?? false;
    } finally {
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
    }
  }
}

enum _AuthChoice { signIn, createAccount }

class _AuthRequiredDialog extends StatelessWidget {
  const _AuthRequiredDialog({required this.action});

  final AuthRequiredAction action;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0E1430),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      contentPadding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF0798D8), Color(0xFFC82791)],
              ),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Text(
            action.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create an account or sign in to ${action.verb}. Your activity can then stay connected to your account across devices.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          const _BenefitRow(label: 'Comment and join conversations'),
          const _BenefitRow(label: 'Like, save, and follow content'),
          const _BenefitRow(label: 'Sync personalized activity'),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Not now'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, _AuthChoice.signIn),
          child: const Text('Sign In'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _AuthChoice.createAccount),
          child: const Text('Create Account'),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF25D4B2), size: 18),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}
