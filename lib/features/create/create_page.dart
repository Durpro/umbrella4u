import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_controller.dart';
import '../../core/app_models.dart';
import '../../core/app_theme.dart';
import '../../data/umbrella_repository.dart';
import '../../widgets/app_components.dart';
import '../auth/auth_screens.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key, required this.onPosted});

  final VoidCallback onPosted;

  @override
  State<CreatePage> createState() => CreatePageState();
}

class CreatePageState extends State<CreatePage>
    with AutomaticKeepAliveClientMixin {
  final _text = TextEditingController();
  final _pollControllers = [TextEditingController(), TextEditingController()];
  String _intent = 'similar';
  String _category = 'school';
  int _weather = 2;
  bool _anonymous = false;
  bool _sensitive = false;
  bool _pollEnabled = false;
  bool _guidelines = false;
  bool _busy = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _text.dispose();
    for (final controller in _pollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void resetDraft() {
    _text.clear();
    for (final controller in _pollControllers) {
      controller.clear();
    }
    setState(() {
      _intent = 'similar';
      _category = 'school';
      _weather = 2;
      _anonymous = false;
      _sensitive = false;
      _pollEnabled = false;
      _guidelines = false;
    });
  }

  Future<void> _submit() async {
    if (!await requireMember(context)) return;
    if (!mounted) return;
    final body = _text.text.trim();
    if (body.isEmpty) {
      showAppMessage(context, 'Write something before sharing.', error: true);
      return;
    }
    if (body.length > 1500) {
      showAppMessage(
        context,
        'Keep your story under 1,500 characters.',
        error: true,
      );
      return;
    }
    if (_crisisPattern.hasMatch(body)) {
      await _showCrisisSupport();
      return;
    }
    if (_emailPattern.hasMatch(body)) {
      showAppMessage(
        context,
        'Please remove the email address. Keeping personal details out protects everyone.',
        error: true,
      );
      return;
    }
    if (!_guidelines) {
      showAppMessage(
        context,
        'Please confirm the kindness agreement before sharing.',
        error: true,
      );
      return;
    }

    final pollOptions = _pollEnabled
        ? _pollControllers
              .map((controller) => controller.text.trim())
              .where((option) => option.isNotEmpty)
              .toList(growable: false)
        : <String>[];
    if (_pollEnabled && pollOptions.length < 2) {
      showAppMessage(
        context,
        'A poll needs at least two choices.',
        error: true,
      );
      return;
    }
    if (_anonymous && pollOptions.isNotEmpty) {
      showAppMessage(
        context,
        'Anonymous polls are temporarily unavailable while their privacy rules are strengthened.',
        error: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.umbrella_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Ready to share?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Before this enters the community, make sure it contains no real names, schools, locations, phone numbers, emails, or social handles.',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EFFB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _anonymous
                    ? 'This will be fully anonymous and privately linked to your account for safety.'
                    : 'This will appear under your anonymous Haven profile.',
                style: const TextStyle(
                  color: AppTheme.secondaryInk,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Share story'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    setState(() => _busy = true);
    try {
      final repository = AppScope.of(context).repository;
      await repository.createStory(
        text: body,
        intent: _intent,
        category: _category,
        anonymous: _anonymous,
        weather: _weather,
        contentWarning: _sensitive,
        pollOptions: pollOptions,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final colors = Theme.of(dialogContext).colorScheme;
          return AlertDialog(
            icon: EntranceReveal(
              duration: const Duration(milliseconds: 520),
              slideFrom: const Offset(0, 0.055),
              scaleFrom: 0.76,
              child: _PostCelebrationMark(
                color: colors.primary,
                accentColor: colors.secondary,
              ),
            ),
            title: const Text('Your story is sheltered'),
            content: const Text(
              'Thank you for trusting this space. The community can now meet you where you asked to be met.',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('View the feed'),
              ),
            ],
          );
        },
      );
      if (!mounted) return;
      resetDraft();
      widget.onPosted();
    } catch (error) {
      if (mounted) showAppMessage(context, friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showCrisisSupport() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4CBE0),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const Text(
              'You deserve live support right now',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'What you wrote sounds really heavy. Haven is peer support, so this story has not been posted. In Canada, 9-8-8 provides live suicide crisis support by phone and text, in English and French, 24 hours a day.',
              style: TextStyle(
                color: AppTheme.secondaryInk,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:988')),
                    icon: const Icon(Icons.call_rounded),
                    label: const Text('Call 9-8-8'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('sms:988')),
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('Text 9-8-8'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => launchUrl(Uri.parse('https://988.ca/')),
                child: const Text('Visit 988.ca'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Return to my draft'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = AppScope.of(context);
    final canPost = controller.isLoggedIn || controller.isDemo;
    return PageFrame(
      title: 'Share your weather',
      subtitle: 'A story, a small win, or whatever you’re carrying.',
      trailing: RoundIconButton(
        icon: Icons.refresh_rounded,
        tooltip: 'Clear draft',
        onPressed: _text.text.isEmpty ? () {} : resetDraft,
      ),
      child: canPost
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WeeklyPrompt(
                  onUse: () {
                    if (_text.text.isEmpty) {
                      _text.text =
                          'When did you last stop yourself from saying or wearing something, and wish you hadn’t?\n\n';
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _text,
                  minLines: 6,
                  maxLines: 12,
                  maxLength: 1500,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Your story',
                    hintText:
                        'You don’t have to share your worst moment—just whatever you’re carrying right now.',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                const _PrivacyReminder(),
                const SizedBox(height: 24),
                Text(
                  'How should people respond?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _intent,
                  items: responseIntents.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) =>
                      setState(() => _intent = value ?? _intent),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.forum_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'What’s this about?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: communityCategories
                      .map(
                        (category) => ChoiceChip(
                          avatar: Icon(
                            category.icon,
                            size: 17,
                            color: _category == category.key
                                ? Colors.white
                                : category.color,
                          ),
                          label: Text(category.name),
                          selected: _category == category.key,
                          selectedColor: category.color,
                          labelStyle: TextStyle(
                            color: _category == category.key
                                ? Colors.white
                                : AppTheme.secondaryInk,
                          ),
                          onSelected: (_) =>
                              setState(() => _category = category.key),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 24),
                Text(
                  'How’s your weather today?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  'Umbrellas from others help clear it toward sunny.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 88,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: weatherChoices
                        .map(
                          (weather) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _weather = weather.value),
                              borderRadius: BorderRadius.circular(17),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 92,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _weather == weather.value
                                      ? Theme.of(context).colorScheme.primary
                                      : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(17),
                                  border: Border.all(
                                    color: _weather == weather.value
                                        ? Theme.of(context).colorScheme.primary
                                        : AppTheme.border,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      weather.emoji,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      weather.label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _weather == weather.value
                                            ? Colors.white
                                            : AppTheme.secondaryInk,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 20),
                _OptionTile(
                  icon: Icons.visibility_off_outlined,
                  title: 'Post fully anonymously',
                  subtitle:
                      'Hide your Haven profile. Ownership stays private for safety.',
                  value: _anonymous,
                  onChanged: (value) {
                    setState(() {
                      _anonymous = value;
                      if (value && _pollEnabled) _pollEnabled = false;
                    });
                    if (value) {
                      showAppMessage(
                        context,
                        'Polls are turned off for anonymous stories until their privacy policy is fixed.',
                      );
                    }
                  },
                ),
                const SizedBox(height: 9),
                _OptionTile(
                  icon: Icons.visibility_off_rounded,
                  title: 'Add a sensitive-content cover',
                  subtitle: 'Readers choose when they feel ready to reveal it.',
                  value: _sensitive,
                  onChanged: (value) => setState(() => _sensitive = value),
                ),
                const SizedBox(height: 9),
                _OptionTile(
                  icon: Icons.poll_outlined,
                  title: 'Add a poll',
                  subtitle: 'Offer two to four choices. One vote per member.',
                  value: _pollEnabled,
                  onChanged: _anonymous
                      ? null
                      : (value) => setState(() => _pollEnabled = value),
                ),
                if (_pollEnabled) ...[
                  const SizedBox(height: 12),
                  _PollEditor(controllers: _pollControllers),
                ],
                const SizedBox(height: 18),
                CheckboxListTile(
                  value: _guidelines,
                  onChanged: (value) =>
                      setState(() => _guidelines = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I kept everyone anonymous and this story follows the kindness agreement.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: _busy
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CupertinoActivityIndicator(
                              color: Colors.white,
                              radius: 9,
                            ),
                          )
                        : const Icon(Icons.umbrella_rounded),
                    label: Text(
                      _busy ? 'Sheltering your story…' : 'Share story',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Up to five stories per day · enforced privately by Haven',
                    style: TextStyle(color: AppTheme.mutedInk, fontSize: 10.5),
                  ),
                ),
              ],
            )
          : EmptyState(
              icon: Icons.edit_note_rounded,
              title: 'Your story needs a safe account',
              message:
                  'Accounts are anonymous and your email is only used for login and recovery.',
              action: () => requireMember(context),
              actionLabel: 'Log in or sign up',
            ),
    );
  }
}

class _PostCelebrationMark extends StatelessWidget {
  const _PostCelebrationMark({required this.color, required this.accentColor});

  final Color color;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Story shared successfully',
      child: SizedBox(
        width: 88,
        height: 78,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: 1,
              top: 1,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 19,
                color: accentColor,
              ),
            ),
            Positioned(
              left: 6,
              bottom: 10,
              child: Icon(Icons.star_rounded, size: 13, color: accentColor),
            ),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, accentColor],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.24),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.umbrella_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyPrompt extends StatelessWidget {
  const _WeeklyPrompt({required this.onUse});

  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF241835),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '☂️  THIS WEEK’S PROMPT',
            style: TextStyle(
              color: Color(0xFFCBB9F7),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 11),
          const Text(
            'When did you last stop yourself from saying or wearing something, and wish you hadn’t?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 11),
          TextButton.icon(
            onPressed: onUse,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD9CBFA),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: const Text('Answer this'),
          ),
        ],
      ),
    );
  }
}

class _PrivacyReminder extends StatelessWidget {
  const _PrivacyReminder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.softSurface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: Color(0xFF75558F), size: 18),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Keep it anonymous: no full names, schools, addresses, phone numbers, emails, or social handles.',
              style: TextStyle(
                color: Color(0xFF5F4B69),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.mutedInk,
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PollEditor extends StatefulWidget {
  const _PollEditor({required this.controllers});

  final List<TextEditingController> controllers;

  @override
  State<_PollEditor> createState() => _PollEditorState();
}

class _PollEditorState extends State<_PollEditor> {
  void _add() {
    if (widget.controllers.length >= 4) return;
    setState(() => widget.controllers.add(TextEditingController()));
  }

  void _remove(int index) {
    if (widget.controllers.length <= 2) return;
    final controller = widget.controllers.removeAt(index);
    controller.dispose();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          ...widget.controllers.indexed.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: entry.$2,
                      maxLength: 80,
                      decoration: InputDecoration(
                        labelText: 'Choice ${entry.$1 + 1}',
                        counterText: '',
                      ),
                    ),
                  ),
                  if (widget.controllers.length > 2)
                    IconButton(
                      onPressed: () => _remove(entry.$1),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Remove choice',
                    ),
                ],
              ),
            ),
          ),
          if (widget.controllers.length < 4)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add choice'),
              ),
            ),
        ],
      ),
    );
  }
}

final _emailPattern = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');

final _crisisPattern = RegExp(
  r'(kill(ing)? myself|\bkms\b|end (it all|my life)|want(ed)? to die|'
  r'wish i (was|were) dead|nothing to live for|don.?t want to (live|exist)|'
  r'better off dead|can.?t go on|self[-\s]?harm|hurt(ing)? myself|'
  r'suicid(e|al)|hopeless)',
  caseSensitive: false,
);
