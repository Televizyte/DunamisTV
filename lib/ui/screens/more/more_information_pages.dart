import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_config.dart';
import '../../../services/more_information_service.dart';
import '../../widgets/gradient_page_background.dart';

Map<String, dynamic> _map(dynamic value) => value is Map
    ? Map<String, dynamic>.from(value.cast<String, dynamic>())
    : <String, dynamic>{};

List<dynamic> _list(dynamic value) => value is List ? value : const [];
String _text(dynamic value) => value?.toString().trim() ?? '';
bool _enabled(Map<String, dynamic> map) => map['enabled'] != false;

class MoreInformationPage extends StatefulWidget {
  final String section;

  const MoreInformationPage({super.key, required this.section});

  @override
  State<MoreInformationPage> createState() => _MoreInformationPageState();
}

class _MoreInformationPageState extends State<MoreInformationPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = MoreInformationService.instance.load();
  }

  void _reload() => setState(() {
        _future = MoreInformationService.instance.load();
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <String, dynamic>{};
        final data = _map(all[widget.section]);
        final title = _text(data['title']).isEmpty
            ? _fallbackTitle(widget.section)
            : _text(data['title']);

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: GradientPageBackground(
            child: snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : snapshot.hasError || data.isEmpty
                    ? _ErrorState(onRetry: _reload)
                    : RefreshIndicator(
                        onRefresh: () async => _reload(),
                        child: _body(context, widget.section, data),
                      ),
          ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    String section,
    Map<String, dynamic> data,
  ) {
    switch (section) {
      case 'technical_support':
        return _TechnicalSupport(data: data);
      case 'ministry':
        return _MinistryPage(data: data);
      case 'about_app':
        return _AboutAppPage(data: data);
      case 'legal_index':
        return _LegalIndexPage(data: data);
      case 'build_with_dxm':
        return _BuildWithDxmPage(data: data);
      default:
        return _ErrorState(onRetry: _reload);
    }
  }

  static String _fallbackTitle(String section) {
    return switch (section) {
      'technical_support' => 'Technical Support',
      'ministry' => 'About the Ministry',
      'about_app' => 'About the App',
      'legal_index' => 'Legal & Policies',
      'build_with_dxm' => 'Build an App Like This',
      _ => 'Information',
    };
  }
}

class _TechnicalSupport extends StatelessWidget {
  final Map<String, dynamic> data;

  const _TechnicalSupport({required this.data});

  @override
  Widget build(BuildContext context) {
    final knowledge = _map(data['knowledge_base']);
    final request = _map(data['request']);
    final articles = _list(knowledge['articles'])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .where(_enabled)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _HeroCard(
          icon: Icons.support_agent_rounded,
          title: _text(data['title']),
          subtitle: _text(data['subtitle']),
        ),
        const SizedBox(height: 18),
        const _SectionTitle('Help & Knowledge Base'),
        for (final article in articles)
          _InfoCard(
            icon: _articleIcon(_text(article['icon_key'])),
            title: _text(article['title']),
            subtitle: _text(article['summary']),
            onTap: () => _showArticle(context, article),
          ),
        const SizedBox(height: 12),
        const _SectionTitle('Need More Help?'),
        _InfoCard(
          icon: Icons.edit_note_rounded,
          title: _text(request['title']).isEmpty
              ? 'Send a Support Request'
              : _text(request['title']),
          subtitle:
              'Describe the challenge and receive an app-specific support reference.',
          onTap: () => _openInternalWeb(
            context,
            'Technical Support',
            _text(request['form_url']),
          ),
        ),
        if (_text(request['email']).isNotEmpty)
          _InfoCard(
            icon: Icons.email_rounded,
            title: 'Email Technical Support',
            subtitle: _text(request['email']),
            onTap: () =>
                launchUrl(Uri.parse('mailto:${_text(request['email'])}')),
          ),
      ],
    );
  }

  static IconData _articleIcon(String key) => switch (key) {
        'quote' => Icons.format_quote_rounded,
        'download' => Icons.download_rounded,
        'notifications' => Icons.notifications_rounded,
        _ => Icons.explore_rounded,
      };

  static void _showArticle(BuildContext context, Map<String, dynamic> article) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .72,
          maxChildSize: .92,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                _text(article['title']),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              SelectableText(
                _text(article['content']),
                style: const TextStyle(fontSize: 15, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MinistryPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const _MinistryPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final links = _list(data['social_links'])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .where(_enabled)
        .toList();
    final phones = _list(data['phones']).map(_text).where((e) => e.isNotEmpty);
    final emails = _list(data['emails']).map(_text).where((e) => e.isNotEmpty);
    final website = _map(data['website']);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _MinistryHero(data: data),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_text(data['overview']).isNotEmpty)
                _TextSection(
                    title: 'About the Ministry', text: _text(data['overview'])),
              if (_text(data['vision']).isNotEmpty)
                _TextSection(title: 'Vision', text: _text(data['vision'])),
              if (_text(data['mission']).isNotEmpty)
                _TextSection(title: 'Mission', text: _text(data['mission'])),
              const _SectionTitle('Contact the Ministry'),
              if (_text(data['address']).isNotEmpty)
                _InfoCard(
                  icon: Icons.location_on_rounded,
                  title: 'Headquarters',
                  subtitle: _text(data['address']),
                ),
              for (final phone in phones)
                _InfoCard(
                  icon: Icons.phone_rounded,
                  title: 'Phone',
                  subtitle: phone,
                  onTap: () => launchUrl(Uri.parse('tel:$phone')),
                ),
              for (final email in emails)
                _InfoCard(
                  icon: Icons.email_rounded,
                  title: 'Email',
                  subtitle: email,
                  onTap: () => launchUrl(Uri.parse('mailto:$email')),
                ),
              if (_enabled(website) && _text(website['url']).isNotEmpty)
                _InfoCard(
                  icon: Icons.public_rounded,
                  title: _text(website['label']).isEmpty
                      ? 'Official Website'
                      : _text(website['label']),
                  subtitle: _text(website['url']),
                  onTap: () => _openDestination(context, website),
                ),
              if (links.isNotEmpty) ...[
                const SizedBox(height: 16),
                const _SectionTitle('Connect with the Ministry'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final link in links) _SocialButton(link: link)
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MinistryHero extends StatelessWidget {
  final Map<String, dynamic> data;

  const _MinistryHero({required this.data});

  @override
  Widget build(BuildContext context) {
    final banner = _text(data['banner_url']);
    return Container(
      constraints: const BoxConstraints(minHeight: 230),
      decoration: BoxDecoration(
        image: banner.isEmpty
            ? null
            : DecorationImage(image: NetworkImage(banner), fit: BoxFit.cover),
        gradient: banner.isEmpty
            ? const LinearGradient(
                colors: [
                  Color(0xFF171B55),
                  Color(0xFF6B1D8D),
                  Color(0xFFB70E7C)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 46, 22, 28),
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(banner.isEmpty ? .08 : .48)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.church_rounded, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              _text(data['name']),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.12,
                  fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Map<String, dynamic> link;

  const _SocialButton({required this.link});

  @override
  Widget build(BuildContext context) {
    final icon = _text(link['icon_key']).toLowerCase();
    final asset = switch (icon) {
      'facebook' => 'assets/icons/social/facebook.svg',
      'instagram' => 'assets/icons/social/instagram.svg',
      'youtube' => 'assets/icons/social/youtube.svg',
      'x' || 'twitter' => 'assets/icons/social/x.svg',
      _ => 'assets/icons/social/link.svg',
    };
    return Semantics(
      button: true,
      label: _text(link['label']),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDestination(context, link),
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.primary.withOpacity(.10),
          ),
          child: SvgPicture.asset(
            asset,
            width: 23,
            height: 23,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.primary,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutAppPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const _AboutAppPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _HeroCard(
          icon: Icons.live_tv_rounded,
          title: _text(data['name']),
          subtitle: _text(data['tagline']),
        ),
        const SizedBox(height: 18),
        if (_text(data['description']).isNotEmpty)
          _TextSection(
              title: 'About the App', text: _text(data['description'])),
        _InfoCard(
            icon: Icons.business_rounded,
            title: 'Technical Operator',
            subtitle: _text(data['operator_name'])),
        _InfoCard(
            icon: Icons.apps_rounded,
            title: 'Package Name',
            subtitle: _text(data['package_name'])),
        _InfoCard(
          icon: Icons.info_outline_rounded,
          title: 'Version',
          subtitle:
              '${_text(data['version_name'])}${_text(data['version_code']).isEmpty ? '' : ' (${_text(data['version_code'])})'}',
        ),
      ],
    );
  }
}

class _LegalIndexPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const _LegalIndexPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final docs = _list(data['documents'])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .where((e) => _enabled(e) && _text(e['value'] ?? e['url']).isNotEmpty)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _HeroCard(
            icon: Icons.gavel_rounded,
            title: 'Legal & Policies',
            subtitle:
                'Review the documents that govern use of the app and explain your rights.'),
        const SizedBox(height: 18),
        for (final doc in docs)
          _InfoCard(
            icon: Icons.description_rounded,
            title: _text(doc['label'] ?? doc['title']),
            subtitle: _text(doc['summary']),
            onTap: () => _openInternalWeb(
                context,
                _text(doc['label'] ?? doc['title']),
                _text(doc['value'] ?? doc['url'])),
          ),
      ],
    );
  }
}

class _BuildWithDxmPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const _BuildWithDxmPage({required this.data});

  @override
  State<_BuildWithDxmPage> createState() => _BuildWithDxmPageState();
}

class _BuildWithDxmPageState extends State<_BuildWithDxmPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _organization = TextEditingController();
  final _email = TextEditingController();
  final _country = TextEditingController();
  final _type = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    for (final c in [_name, _organization, _email, _country, _type, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final response = await http
          .post(
            Uri.parse(
                '${AppConfig.apiBaseUrl}/api/v1/apps/${AppConfig.appSlug}/business-enquiries'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'X-APP-TOKEN': AppConfig.appToken
            },
            body: jsonEncode({
              'name': _name.text.trim(),
              'organization': _organization.text.trim(),
              'email': _email.text.trim(),
              'country': _country.text.trim(),
              'project_type': _type.text.trim(),
              'message': _message.text.trim(),
              'preferred_response': 'email',
            }),
          )
          .timeout(const Duration(seconds: 25));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Request failed');
      }
      final decoded = jsonDecode(response.body);
      final reference = decoded is Map ? _text(decoded['reference']) : '';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Enquiry sent successfully${reference.isEmpty ? '.' : '. Reference: $reference'}')));
      _formKey.currentState!.reset();
      for (final c in [
        _name,
        _organization,
        _email,
        _country,
        _type,
        _message
      ]) {
        c.clear();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'The enquiry could not be sent. Please check your connection and try again.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services =
        _list(widget.data['services']).map(_text).where((e) => e.isNotEmpty);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
      children: [
        _HeroCard(
            icon: Icons.rocket_launch_rounded,
            title: _text(widget.data['hero_title']),
            subtitle: _text(widget.data['intro'])),
        const SizedBox(height: 18),
        const _SectionTitle('What We Build'),
        for (final service in services)
          _InfoCard(icon: Icons.check_circle_rounded, title: service),
        const SizedBox(height: 18),
        const _SectionTitle('Start a Conversation'),
        const Text(
            'Tell us what you want to build. Communication for this form is handled by email.',
            style: TextStyle(height: 1.5)),
        const SizedBox(height: 14),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_name, 'Full name', required: true),
              _field(_organization, 'Organization or business'),
              _field(_email, 'Email address', required: true, email: true),
              _field(_country, 'Country'),
              _field(_type, 'Project type'),
              _field(_message, 'Describe your project',
                  required: true, lines: 6),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _sending ? null : _submit,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                  label: Text(_sending ? 'Sending...' : 'Send Enquiry'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label,
      {bool required = false, bool email = false, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (required && text.isEmpty) return '$label is required.';
          if (email && text.isNotEmpty && !text.contains('@'))
            return 'Enter a valid email address.';
          if (label == 'Describe your project' &&
              text.isNotEmpty &&
              text.length < 10) return 'Please provide a little more detail.';
          return null;
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HeroCard(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
            colors: [Color(0xFF171B55), Color(0xFF6B1D8D), Color(0xFFB70E7C)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 38),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.white.withOpacity(.82),
                    height: 1.45,
                    fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      );
}

class _TextSection extends StatelessWidget {
  final String title;
  final String text;
  const _TextSection({required this.title, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SectionTitle(title),
          SelectableText(text,
              style: const TextStyle(fontSize: 15, height: 1.6)),
        ]),
      );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _InfoCard(
      {required this.icon,
      required this.title,
      this.subtitle = '',
      this.onTap});
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: subtitle.isEmpty
              ? null
              : Text(subtitle,
                  maxLines: onTap == null ? 8 : 3,
                  overflow: TextOverflow.ellipsis),
          trailing:
              onTap == null ? null : const Icon(Icons.chevron_right_rounded),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 46),
            const SizedBox(height: 12),
            const Text('This information could not be loaded.',
                textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ]),
        ),
      );
}

Future<void> _openInternalWeb(
    BuildContext context, String title, String url) async {
  if (url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This page is not available yet.')));
    return;
  }
  context.push('/web', extra: {'title': title, 'url': url});
}

Future<void> _openDestination(
    BuildContext context, Map<String, dynamic> item) async {
  final url = _text(item['url'] ?? item['value']);
  final mode = _text(item['open_mode'] ?? item['type']).toLowerCase();
  if (url.isEmpty) return;
  if (mode == 'external_confirmed') {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open external website?'),
        content: const Text(
            'You are about to leave Dunamis TV and open this website in your browser.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue')),
        ],
      ),
    );
    if (proceed != true) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    return;
  }
  if (mode == 'external' || mode == 'native_app') {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    return;
  }
  await _openInternalWeb(context, _text(item['label']), url);
}
