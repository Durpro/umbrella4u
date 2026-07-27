import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_controller.dart';
import '../../core/app_models.dart';
import '../../core/app_theme.dart';
import '../../data/umbrella_repository.dart';
import '../../widgets/app_components.dart';

enum LegalDocument { privacy, terms }

Future<void> openMoreMenu(BuildContext context) async {
  final navigator = Navigator.of(context);
  final controller = AppScope.of(context);
  final isModerator = controller.profile?.isModerator == true;

  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      void open(Widget page) {
        Navigator.of(sheetContext).pop();
        navigator.push(MaterialPageRoute<void>(builder: (_) => page));
      }

      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.88,
        ),
        decoration: BoxDecoration(
          color: AppTheme.background.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.62)),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 12, 14, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(sheetContext).colorScheme.primary,
                    Theme.of(sheetContext).colorScheme.secondary,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.umbrella_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'More from Umbrella4U',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Safety, support, settings, and our story.',
                              style: TextStyle(
                                color: Color(0xFFE8DEFF),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        tooltip: 'Close',
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                children: [
                  _MoreTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'Appearance, privacy, and your account',
                    onTap: () => open(const SettingsScreen()),
                  ),
                  _MoreTile(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Resource hub',
                    subtitle: 'Canadian 9-8-8 crisis support',
                    onTap: () => open(const ResourcesScreen()),
                  ),
                  _MoreTile(
                    icon: Icons.auto_stories_outlined,
                    title: 'How Haven works',
                    subtitle: 'A quick tour of sharing and support',
                    onTap: () => open(const HowItWorksScreen()),
                  ),
                  _MoreTile(
                    icon: Icons.shield_outlined,
                    title: 'Community guidelines',
                    subtitle: 'The promises that keep this space safe',
                    onTap: () => open(const GuidelinesScreen()),
                  ),
                  _MoreTile(
                    icon: Icons.rate_review_outlined,
                    title: 'Send feedback',
                    subtitle: 'Tell the team what could feel better',
                    onTap: () => open(const FeedbackScreen()),
                  ),
                  if (isModerator)
                    _MoreTile(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Moderator tools',
                      subtitle: 'Available on the Umbrella4U website',
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        showAppMessage(
                          context,
                          'Moderator tools are currently available on the Umbrella4U website.',
                        );
                      },
                    ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 18, 8, 8),
                    child: Text(
                      'ABOUT & LEGAL',
                      style: TextStyle(
                        color: AppTheme.mutedInk,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  _MoreTile(
                    icon: Icons.groups_2_outlined,
                    title: 'Meet the team',
                    subtitle: 'Youth mental wellness, built by youth',
                    onTap: () => open(const TeamScreen()),
                  ),
                  _MoreTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy policy',
                    onTap: () => open(
                      const LegalScreen(document: LegalDocument.privacy),
                    ),
                  ),
                  _MoreTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of use',
                    onTap: () =>
                        open(const LegalScreen(document: LegalDocument.terms)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onOpenProfile});

  final VoidCallback? onOpenProfile;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _savingDiscoverability = false;
  bool _signingOut = false;

  Future<void> _setDiscoverable(bool value) async {
    setState(() => _savingDiscoverability = true);
    try {
      await AppScope.of(context).updatePreference('discoverable', value);
      if (mounted) {
        showAppMessage(
          context,
          value
              ? 'Your profile can now appear in search.'
              : 'Your profile is now hidden from search.',
        );
      }
    } catch (error) {
      if (mounted) showAppMessage(context, friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => _savingDiscoverability = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Log out everywhere?'),
            content: const Text(
              'This signs this account out on every device. You can log back in at any time.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Log out'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _signingOut = true);
    try {
      await AppScope.of(context).signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _signingOut = false);
        showAppMessage(context, friendlyError(error), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final profile = controller.profile;
    final selectedTheme = controller.theme;

    return _DetailScaffold(
      title: 'Settings',
      subtitle: 'Make Haven feel comfortable, private, and yours.',
      children: [
        const _SectionLabel('Appearance'),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your color',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 5),
              Text(
                'Purple stays the signature look. Your choice follows your account when you are logged in.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: appThemeChoices
                        .map(
                          (choice) => SizedBox(
                            width: width,
                            child: _ThemeChoiceTile(
                              choice: choice,
                              selected: choice.key == selectedTheme.key,
                              onTap: () => controller.setTheme(choice),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('Privacy'),
        _SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingsRow(
                icon: Icons.manage_search_rounded,
                title: 'Show me in search',
                subtitle: profile == null
                    ? 'Log in to manage profile discovery.'
                    : 'People can find your profile by username, display name, or interests.',
                trailing: _savingDiscoverability
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CupertinoActivityIndicator(radius: 10),
                      )
                    : Switch.adaptive(
                        value: profile?.discoverable ?? false,
                        onChanged: profile == null ? null : _setDiscoverable,
                      ),
              ),
              const Divider(height: 1, indent: 68),
              _SettingsRow(
                icon: Icons.alternate_email_rounded,
                title: 'Email notifications',
                subtitle:
                    'Coming soon — this switch is not active yet. Inbox updates still appear inside Haven.',
                badge: 'COMING SOON',
                trailing: Switch.adaptive(
                  value: profile?.notifyEmail ?? false,
                  onChanged: null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('Account'),
        _SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (widget.onOpenProfile != null) ...[
                _SettingsRow(
                  icon: Icons.account_circle_outlined,
                  title: 'Edit profile',
                  subtitle: 'Update your weather, bio, avatar, and interests.',
                  onTap: widget.onOpenProfile,
                ),
                const Divider(height: 1, indent: 68),
              ],
              if (controller.isLoggedIn)
                _SettingsRow(
                  icon: Icons.logout_rounded,
                  title: 'Log out of all devices',
                  subtitle: 'End every active session for this account.',
                  destructive: true,
                  onTap: _signingOut ? null : _signOut,
                  trailing: _signingOut
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CupertinoActivityIndicator(radius: 10),
                        )
                      : null,
                )
              else
                const _SettingsRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Browsing as a guest',
                  subtitle:
                      'Open the Profile tab when you are ready to log in or create an anonymous account.',
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _InfoBanner(
          icon: Icons.lock_outline_rounded,
          text:
              'Your email is used for login and account recovery. It is never shown on your public profile.',
        ),
      ],
    );
  }
}

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Resource hub',
      subtitle: 'Trained support is available when peer support is not enough.',
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.24),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '9-8-8: Suicide Crisis Helpline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Call or text 9-8-8 anywhere in Canada for live support in English or French, 24 hours a day, every day.',
                style: TextStyle(
                  color: Color(0xFFECE4FF),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _launchExternal(
                        context,
                        Uri(scheme: 'tel', path: '988'),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('Call 9-8-8'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _launchExternal(
                        context,
                        Uri(scheme: 'sms', path: '988'),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.16),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.sms_outlined),
                      label: const Text('Text 9-8-8'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SurfaceCard(
          padding: EdgeInsets.zero,
          child: _SettingsRow(
            icon: Icons.language_rounded,
            title: 'Visit the official 9-8-8 website',
            subtitle: 'Learn what to expect and find more information.',
            onTap: () => _launchExternal(context, Uri.parse('https://988.ca/')),
          ),
        ),
        const SizedBox(height: 20),
        const _InfoBanner(
          icon: Icons.favorite_border_rounded,
          text:
              'Haven is a peer-support community. It is not professional counselling, medical care, or a crisis service.',
        ),
      ],
    );
  }
}

class GuidelinesScreen extends StatelessWidget {
  const GuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const guidelines = [
      (
        Icons.diversity_1_outlined,
        'Respect every identity',
        'You will meet people unlike you. Their identity and experience deserve care.',
      ),
      (
        Icons.forum_outlined,
        'Criticize ideas, never people',
        'Disagree without insults, humiliation, harassment, or personal attacks.',
      ),
      (
        Icons.block_rounded,
        'No hate or discrimination',
        'Hate speech, threats, sexual exploitation, and discriminatory content are not welcome.',
      ),
      (
        Icons.lock_outline_rounded,
        'Protect everyone’s identity',
        'Never reveal private information, real names, schools, addresses, or contact details.',
      ),
      (
        Icons.umbrella_outlined,
        'Respond how they asked',
        'When someone shares their rain, meet them with listening, advice, similar stories, or resources as requested.',
      ),
    ];

    return _DetailScaffold(
      title: 'Community guidelines',
      subtitle: 'Haven only works because everyone helps keep it safe.',
      children: [
        const _InfoBanner(
          icon: Icons.volunteer_activism_outlined,
          text:
              'We know struggling is hard. Keep your words safe and kind—to yourself and to everyone here.',
        ),
        const SizedBox(height: 16),
        ...guidelines.indexed.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GuidelineCard(
              number: entry.$1 + 1,
              icon: entry.$2.$1,
              title: entry.$2.$2,
              description: entry.$2.$3,
            ),
          ),
        ),
        const SizedBox(height: 4),
        _SurfaceCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.flag_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  'Use the report action on any story that breaks these rules. Reports go to the moderation team.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        Icons.cloud_outlined,
        'Share your weather',
        'Post what you are carrying—a hard day, a small win, or a question. Share only what feels right.',
      ),
      (
        Icons.tune_rounded,
        'Choose how to be met',
        'Ask people to listen, offer advice, share similar experiences, or point you to resources.',
      ),
      (
        Icons.umbrella_rounded,
        'One umbrella each',
        'Instead of endless comment threads, each person can offer one quiet act of support.',
      ),
      (
        Icons.mark_email_unread_outlined,
        'Check your inbox',
        'Umbrellas, optional notes, and thank-yous appear in one calm notification stream.',
      ),
    ];

    return _DetailScaffold(
      title: 'How Haven works',
      subtitle:
          'We cannot stop the rain, but we can hold out an umbrella for each other.',
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.umbrella_rounded, color: Colors.white, size: 40),
              SizedBox(height: 22),
              Text(
                'A quieter kind of social space.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 9),
              Text(
                'Share honestly, stay anonymous when you choose, and support people without pile-ons or arguments.',
                style: TextStyle(
                  color: Color(0xFFE9E0FF),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const _SectionLabel('The support loop'),
        ...steps.indexed.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TourStepCard(
              number: entry.$1 + 1,
              icon: entry.$2.$1,
              title: entry.$2.$2,
              description: entry.$2.$3,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const _SectionLabel('Why it feels safer'),
        const _SafetyFeature(
          icon: Icons.visibility_off_outlined,
          title: 'Anonymous by design',
          description:
              'Your email stays private, and a fully anonymous story is not connected to your public profile.',
        ),
        const SizedBox(height: 10),
        const _SafetyFeature(
          icon: Icons.security_outlined,
          title: 'Layers of moderation',
          description:
              'Database screening, reports, relevance signals, and human review work together.',
        ),
        const SizedBox(height: 10),
        const _SafetyFeature(
          icon: Icons.favorite_outline_rounded,
          title: 'Kindness is the rule',
          description:
              'Everyone agrees to the community guidelines before sharing.',
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const GuidelinesScreen()),
          ),
          icon: const Icon(Icons.shield_outlined),
          label: const Text('Read the community guidelines'),
        ),
      ],
    );
  }
}

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _messageController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      await AppScope.of(context).repository.submitFeedback(message);
      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _submitting = false;
        _submitted = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showAppMessage(context, friendlyError(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Send feedback',
      subtitle: 'Help the team make Haven calmer, safer, and more useful.',
      children: [
        if (_submitted)
          EmptyState(
            icon: Icons.mark_email_read_outlined,
            title: 'Thank you for telling us',
            message:
                'Your feedback was sent to the Umbrella4U team. Every thoughtful note helps.',
            action: () => setState(() => _submitted = false),
            actionLabel: 'Send another note',
          )
        else
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What should we know?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 7),
                Text(
                  'Share an idea, a confusing moment, an accessibility issue, or something that did not work.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _messageController,
                  minLines: 6,
                  maxLines: 10,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Write your feedback here…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        _messageController.text.trim().isEmpty || _submitting
                        ? null
                        : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CupertinoActivityIndicator(
                              color: Colors.white,
                              radius: 9,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_submitting ? 'Sending…' : 'Send feedback'),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        const _InfoBanner(
          icon: Icons.schedule_rounded,
          text:
              'This feedback form is not monitored in real time. If you need immediate crisis support, use the Resource hub.',
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ResourcesScreen()),
          ),
          icon: const Icon(Icons.health_and_safety_outlined),
          label: const Text('Open the Resource hub'),
        ),
      ],
    );
  }
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, this.document = LegalDocument.privacy});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final privacy = document == LegalDocument.privacy;
    final sections = privacy ? _privacySections : _termsSections;
    final pageUri = Uri.parse(
      privacy ? 'https://umbrella4u.ca/privacy' : 'https://umbrella4u.ca/terms',
    );

    return _DetailScaffold(
      title: privacy ? 'Privacy policy' : 'Terms of use',
      subtitle: 'Last updated July 7, 2026',
      selectable: true,
      children: [
        _InfoBanner(
          icon: privacy
              ? Icons.privacy_tip_outlined
              : Icons.description_outlined,
          text: privacy
              ? 'Your email is for login and recovery, never your public identity. Umbrella4U does not sell your data or run ads.'
              : 'Use Umbrella4U only if you are 13 or older. Be kind, protect private information, and remember that Haven is peer support.',
        ),
        const SizedBox(height: 18),
        ...sections.map(
          (section) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _LegalSection(title: section.$1, body: section.$2),
          ),
        ),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () => _launchExternal(context, pageUri),
          icon: const Icon(Icons.open_in_new_rounded),
          label: Text(
            privacy
                ? 'Open the full privacy policy'
                : 'Open the full terms of use',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'The current policy published on umbrella4u.ca is the authoritative version.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  static const _members = [
    ('Ricky Chen', 'Founder · CEO · CTO'),
    ('Kaylee Hu', 'Art Director · Washington Chapter President'),
    ('Kevin Qian', 'Outreach & Advocacy'),
    ('Sophie Zou', 'Marketing & Social Media'),
    ('Kasra', 'Events Coordination & Networking'),
    ('Blake', 'Business & Strategy'),
    ('Norman', 'Backend Developer & Aerial Photographer'),
  ];

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Meet the team',
      subtitle: 'Youth mental wellness, built by youth.',
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrandMark(size: 46),
              SizedBox(height: 24),
              Text(
                'Built with young people, for young people.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  height: 1.18,
                ),
              ),
              SizedBox(height: 9),
              Text(
                'Umbrella4U is a youth-led mental-wellness project. Haven is its flagship anonymous peer-support community.',
                style: TextStyle(
                  color: Color(0xFFE9E0FF),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const _SectionLabel('Our team'),
        ..._members.map(
          (member) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TeamMemberTile(name: member.$1, role: member.$2),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () =>
              _launchExternal(context, Uri.parse('https://umbrella4u.ca/team')),
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('Read the full team bios'),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () =>
              _launchExternal(context, Uri.parse('https://umbrella4u.ca/')),
          icon: const Icon(Icons.language_rounded),
          label: const Text('Visit umbrella4u.ca'),
        ),
      ],
    );
  }
}

const _privacySections = <(String, String)>[
  (
    'Who we are',
    'Umbrella4U is an anonymous peer-support community for young people. It is run by a small youth-led volunteer team with adult guidance. It is not counselling, medical care, or a crisis service.',
  ),
  (
    'What we collect',
    'We collect the email used for account login and recovery; profile details you choose to add; stories, umbrellas, short notes, votes, and reports; and basic technical information needed to run and secure the service. Passwords are handled by the authentication provider and are not stored as readable text.',
  ),
  (
    'What we do not ask for',
    'We do not ask for your real name, home address, phone number, or precise location. We do not use advertising trackers or build advertising profiles.',
  ),
  (
    'How information is used',
    'Information is used to operate Haven, show community content, personalize profiles, provide account features, screen content, investigate reports, and protect the community.',
  ),
  (
    'Public and anonymous content',
    'Live stories can be viewed by logged-out visitors. Named stories connect to a public profile; fully anonymous stories do not display or publicly expose their author. Avoid writing details that could identify you or somebody else.',
  ),
  (
    'Sharing and retention',
    'Umbrella4U does not sell personal data. Trusted hosting and authentication providers process data to run the service. Information is kept only as long as needed to operate and protect the community or meet legal obligations.',
  ),
  (
    'Your choices',
    'You can edit profile details, control whether your profile appears in search, and delete your own stories. You may request access, correction, or deletion of personal information through the contact method on the official website.',
  ),
  (
    'Age and changes',
    'Umbrella4U is for people age 13 and older. Material policy changes will be reflected in the updated date and may also be announced in the app.',
  ),
];

const _termsSections = <(String, String)>[
  (
    'Accepting these terms',
    'By creating an account or using Umbrella4U, you agree to the Terms of Use, Privacy Policy, and Community Guidelines.',
  ),
  (
    'Who can use Umbrella4U',
    'You must be at least 13 years old. Keep account details secure, do not impersonate others, and do not evade enforcement by creating replacement accounts.',
  ),
  (
    'What Haven is',
    'Haven is an anonymous space for peer support and connection. It is not counselling, medical advice, an emergency service, or a replacement for professional help.',
  ),
  (
    'Community conduct',
    'Respect every identity. Do not post hate speech, harassment, threats, personal attacks, illegal content, sexual content involving minors, or private identifying information.',
  ),
  (
    'Your content',
    'Your content remains yours. By sharing it, you give Umbrella4U permission to display and process it as needed to provide and protect the service. You must have the right to share what you post.',
  ),
  (
    'Moderation',
    'Umbrella4U may screen, hide, or remove content and may restrict accounts that break the rules or put the community at risk. Reports may be reviewed by human moderators.',
  ),
  (
    'Availability and peer advice',
    'The service is provided as available and may occasionally be interrupted. Support comes from peers and must not be treated as professional advice.',
  ),
  (
    'Ending use and governing law',
    'You can stop using the service at any time. Umbrella4U may end access when needed to enforce these terms or protect the community. The published terms are governed by the laws of British Columbia, Canada.',
  ),
];

Future<void> _launchExternal(BuildContext context, Uri uri) async {
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      showAppMessage(
        context,
        'This action is not available on this device.',
        error: true,
      );
    }
  } catch (_) {
    if (context.mounted) {
      showAppMessage(
        context,
        'This action is not available on this device.',
        error: true,
      );
    }
  }
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    this.selectable = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 42),
      children: [
        EntranceReveal(
          slideFrom: const Offset(0, 0.018),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 22),
              ...children,
            ],
          ),
        ),
      ],
    );

    return SwipeBackScope(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(title),
          centerTitle: false,
          backgroundColor: AppTheme.background,
          foregroundColor: AppTheme.ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          top: false,
          child: selectable ? SelectionArea(child: content) : content,
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: padding,
      borderRadius: BorderRadius.circular(22),
      opacity: 0.84,
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ThemeChoiceTile extends StatelessWidget {
  const _ThemeChoiceTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final AppThemeChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? choice.accent.withValues(alpha: 0.1)
          : const Color(0xFFFAF8FD),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected ? choice.accent : AppTheme.border,
              width: selected ? 1.7 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [choice.accent, choice.deep],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: choice.accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choice.name,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      choice.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.mutedInk,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.badge,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? badge;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive
        ? const Color(0xFFC9475B)
        : Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: accent, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: destructive
                                ? const Color(0xFFC9475B)
                                : AppTheme.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing!,
            ] else if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.mutedInk),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: AppTheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.mutedInk,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuidelineCard extends StatelessWidget {
  const _GuidelineCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final int number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 23,
                ),
              ),
              Positioned(
                right: -4,
                top: -5,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TourStepCard extends StatelessWidget {
  const _TourStepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final int number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 23),
              ),
              const SizedBox(height: 7),
              Text(
                'STEP $number',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyFeature extends StatelessWidget {
  const _SafetyFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 25),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _TeamMemberTile extends StatelessWidget {
  const _TeamMemberTile({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final initial = name.characters.first.toUpperCase();
    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(role, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
