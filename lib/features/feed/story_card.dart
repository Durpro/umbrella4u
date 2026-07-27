import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../core/app_models.dart';
import '../../core/app_theme.dart';
import '../../data/umbrella_repository.dart';
import '../../widgets/app_components.dart';
import '../auth/auth_screens.dart';

class StoryCard extends StatefulWidget {
  const StoryCard({
    super.key,
    required this.story,
    this.onChanged,
    this.onOpenProfile,
  });

  final StoryItem story;
  final VoidCallback? onChanged;
  final ValueChanged<String>? onOpenProfile;

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard> {
  late StoryItem _story;
  bool _busyHug = false;
  bool _busyUmbrella = false;
  bool _reported = false;
  bool _marked = false;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _story = widget.story;
  }

  @override
  void didUpdateWidget(covariant StoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.story != widget.story) _story = widget.story;
  }

  UmbrellaRepository get _repository => AppScope.of(context).repository;

  Future<void> _toggleHug() async {
    if (_busyHug || !await requireMember(context)) return;
    if (!mounted) return;
    setState(() => _busyHug = true);
    try {
      final next = await _repository.toggleHug(_story);
      if (!mounted) return;
      setState(() {
        _story = _story.copyWith(
          hasHug: next,
          hugCount: (_story.hugCount + (next ? 1 : -1))
              .clamp(0, 999999)
              .toInt(),
        );
      });
    } catch (error) {
      if (mounted) showAppMessage(context, friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => _busyHug = false);
    }
  }

  Future<void> _openUmbrella() async {
    if (_story.hasUmbrella || _story.isMine || _busyUmbrella) return;
    if (!await requireMember(context)) return;
    if (!mounted) return;

    final noteController = TextEditingController();
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4CBE0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.umbrella_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Open an umbrella',
                          style: TextStyle(
                            color: AppTheme.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'A quiet signal that says “I’m here with you.”',
                          style: TextStyle(
                            color: AppTheme.secondaryInk,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: noteController,
                minLines: 3,
                maxLines: 6,
                maxLength: 300,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: _story.intent == 'listen'
                      ? 'A kind word (optional)'
                      : 'Leave a supportive note (optional)',
                  hintText: _intentHint(_story.intent),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Keep it anonymous. Leave out names, schools, locations, email addresses, phone numbers, and socials.',
                style: TextStyle(
                  color: AppTheme.mutedInk,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Not now'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          Navigator.of(sheetContext).pop(noteController.text),
                      icon: const Icon(Icons.umbrella_rounded, size: 19),
                      label: const Text('Open it'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    noteController.dispose();
    if (!mounted || note == null) return;

    setState(() => _busyUmbrella = true);
    try {
      final hugged = await _repository.openUmbrella(_story, note: note);
      if (!mounted) return;
      setState(() {
        _story = _story.copyWith(
          hasUmbrella: true,
          umbrellaCount: _story.umbrellaCount + 1,
          hasHug: hugged,
          hugCount: hugged && !_story.hasHug
              ? _story.hugCount + 1
              : _story.hugCount,
        );
      });
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final colors = Theme.of(dialogContext).colorScheme;
          return AlertDialog(
            icon: EntranceReveal(
              duration: const Duration(milliseconds: 500),
              slideFrom: const Offset(0, 0.055),
              scaleFrom: 0.76,
              child: _CelebrationMark(
                icon: Icons.umbrella_rounded,
                color: colors.primary,
                accentColor: colors.secondary,
                semanticsLabel: 'Umbrella opened',
              ),
            ),
            title: const Text('Your umbrella is open'),
            content: const Text(
              'We can’t stop the rain, but we can hold out an umbrella for each other.',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Done'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (mounted) showAppMessage(context, friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => _busyUmbrella = false);
    }
  }

  Future<void> _vote(PollOption option) async {
    if (_story.myVoteOptionId != null || !await requireMember(context)) return;
    if (!mounted) return;
    try {
      await _repository.castVote(_story, option.id);
      if (!mounted) return;
      setState(() {
        _story = _story.copyWith(
          myVoteOptionId: option.id,
          pollOptions: _story.pollOptions
              .map(
                (item) => item.id == option.id
                    ? PollOption(
                        id: item.id,
                        storyId: item.storyId,
                        index: item.index,
                        label: item.label,
                        voteCount: item.voteCount + 1,
                      )
                    : item,
              )
              .toList(growable: false),
        );
      });
    } catch (error) {
      if (mounted) showAppMessage(context, friendlyError(error), error: true);
    }
  }

  Future<void> _handleMenu(String action) async {
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete your story?'),
          content: const Text(
            'This removes the story and its support permanently. This can’t be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC33E55),
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      try {
        await _repository.deleteStory(_story.id);
        widget.onChanged?.call();
      } catch (error) {
        if (mounted) showAppMessage(context, friendlyError(error), error: true);
      }
      return;
    }
    if (!await requireMember(context)) return;
    if (!mounted) return;
    try {
      if (action == 'report') {
        await _repository.reportStory(_story.id);
        if (!mounted) return;
        setState(() => _reported = true);
        if (mounted) {
          showAppMessage(context, 'Thanks. A moderator can review it.');
        }
      } else if (action == 'relevance') {
        await _repository.markNotRelevant(_story.id);
        if (!mounted) return;
        setState(() => _marked = true);
        if (mounted) {
          showAppMessage(context, 'Thanks. Your signal stays private.');
        }
      }
    } catch (error) {
      if (mounted) showAppMessage(context, friendlyError(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = categoryFor(_story.category);
    final weather = weatherFor(_story.weather);
    final warning = _story.contentWarning.trim();
    final threshold = [50, 35, 22, 12, 8][_story.weather.clamp(0, 4).toInt()];
    final progress = (_story.umbrellaCount / threshold).clamp(0.0, 1.0);
    final who = _story.anonymous ? 'Anonymous' : _story.authorName;
    final storyBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _story.text,
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 15.5,
            height: 1.55,
            letterSpacing: -0.05,
          ),
        ),
        if (_story.pollOptions.isNotEmpty) ...[
          const SizedBox(height: 18),
          _PollView(story: _story, onVote: _vote),
        ],
      ],
    );

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F2C164F),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap:
                      !_story.anonymous &&
                          _story.authorId != null &&
                          widget.onOpenProfile != null
                      ? () => widget.onOpenProfile!(_story.authorName)
                      : null,
                  child: Container(
                    width: 43,
                    height: 43,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _story.anonymous
                          ? const Color(0xFFF0EBF8)
                          : category.color.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _story.anonymous
                          ? '🕶️'
                          : who.characters.first.toUpperCase(),
                      style: TextStyle(
                        color: category.color,
                        fontSize: _story.anonymous ? 20 : 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              who,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (_story.anonymous) ...[
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.lock_rounded,
                              size: 12,
                              color: AppTheme.mutedInk,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${relativeTime(_story.createdAt)} · ${category.name}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Story options',
                  onSelected: _handleMenu,
                  itemBuilder: (_) => [
                    if (!_story.isMine)
                      PopupMenuItem(
                        value: 'report',
                        enabled: !_reported,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.flag_outlined),
                          title: Text(_reported ? 'Reported' : 'Report story'),
                        ),
                      ),
                    if (!_story.isMine)
                      PopupMenuItem(
                        value: 'relevance',
                        enabled: !_marked,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.low_priority_rounded),
                          title: Text(_marked ? 'Marked' : 'Not relevant here'),
                        ),
                      ),
                    if (_story.isMine)
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFC33E55),
                          ),
                          title: Text('Delete story'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _MetaPill(
                  icon: category.icon,
                  label: category.name,
                  color: category.color,
                ),
                _MetaPill(
                  icon: Icons.forum_outlined,
                  label: responseIntents[_story.intent] ?? 'Support',
                  color: Theme.of(context).colorScheme.primary,
                ),
                _MetaPill(
                  emoji: weather.emoji,
                  label: weather.label,
                  color: const Color(0xFF65758B),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (warning.isEmpty)
              storyBody
            else if (_revealed) ...[
              const _ContentWarningLabel(),
              const SizedBox(height: 10),
              storyBody,
            ] else
              _ContentWarningCover(
                onReveal: () => setState(() => _revealed = true),
              ),
            const SizedBox(height: 19),
            Row(
              children: [
                Text(
                  '${weather.emoji} Weather clearing',
                  style: const TextStyle(
                    color: AppTheme.secondaryInk,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_story.umbrellaCount}/$threshold',
                  style: const TextStyle(
                    color: AppTheme.mutedInk,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: const Color(0xFFEDE8F3),
                color: category.color,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        _story.hasUmbrella || _story.isMine || _busyUmbrella
                        ? null
                        : _openUmbrella,
                    icon: _busyUmbrella
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CupertinoActivityIndicator(
                              color: Colors.white,
                              radius: 9,
                            ),
                          )
                        : Icon(
                            _story.hasUmbrella
                                ? Icons.check_rounded
                                : Icons.umbrella_rounded,
                            size: 18,
                          ),
                    label: Text(
                      _story.isMine
                          ? 'Your story'
                          : _story.hasUmbrella
                          ? 'Umbrella open'
                          : 'Open umbrella',
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Semantics(
                  button: true,
                  selected: _story.hasHug,
                  label: _story.hasHug ? 'Remove hug' : 'Send hug',
                  child: OutlinedButton.icon(
                    onPressed: _busyHug ? null : _toggleHug,
                    icon: Icon(
                      _story.hasHug
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _story.hasHug ? const Color(0xFFD95277) : null,
                      size: 18,
                    ),
                    label: Text('${_story.hugCount}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'One umbrella each · no threads · always kind',
                style: TextStyle(color: AppTheme.mutedInk, fontSize: 10.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps a sensitive story hidden until the reader asks for it, which is what
/// the composer promises when someone adds a cover to their post.
class _ContentWarningCover extends StatelessWidget {
  const _ContentWarningCover({required this.onReveal});

  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sensitive content, hidden until you choose to read it',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7EA).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0D9AF)),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFF6E7CC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.visibility_off_outlined,
                size: 21,
                color: Color(0xFF9B6B24),
              ),
            ),
            const SizedBox(height: 11),
            const Text(
              'Sensitive content',
              style: TextStyle(
                color: Color(0xFF754C13),
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'This story is covered until you feel ready to read it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8A6B32),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 13),
            OutlinedButton.icon(
              onPressed: onReveal,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Reveal story'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8A642D),
                side: const BorderSide(color: Color(0xFFE0C795)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentWarningLabel extends StatelessWidget {
  const _ContentWarningLabel();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sensitive content',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7EA).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0D9AF)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Color(0xFF9B6B24),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Sensitive content',
                style: const TextStyle(
                  color: Color(0xFF754C13),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CelebrationMark extends StatelessWidget {
  const _CelebrationMark({
    required this.icon,
    required this.color,
    required this.accentColor,
    required this.semanticsLabel,
  });

  final IconData icon;
  final Color color;
  final Color accentColor;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticsLabel,
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
              child: Icon(icon, size: 35, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    this.icon,
    this.emoji,
    required this.label,
    required this.color,
  });

  final IconData? icon;
  final String? emoji;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null)
            Text(emoji!, style: const TextStyle(fontSize: 11))
          else
            Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PollView extends StatelessWidget {
  const _PollView({required this.story, required this.onVote});

  final StoryItem story;
  final ValueChanged<PollOption> onVote;

  @override
  Widget build(BuildContext context) {
    final total = story.pollOptions.fold(
      0,
      (value, option) => value + option.voteCount,
    );
    final voted = story.myVoteOptionId != null;
    return Column(
      children: story.pollOptions
          .map((option) {
            final selected = story.myVoteOptionId == option.id;
            final fraction = total == 0 ? 0.0 : option.voteCount / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: voted ? null : () => onVote(option),
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F4FB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : AppTheme.border,
                        ),
                      ),
                    ),
                    if (voted)
                      Positioned.fill(
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: fraction,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.label,
                                style: TextStyle(
                                  color: AppTheme.ink,
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (voted)
                              Text(
                                '${(fraction * 100).round()}%',
                                style: const TextStyle(
                                  color: AppTheme.secondaryInk,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

String _intentHint(String intent) {
  return switch (intent) {
    'advice' => 'A gentle idea that helped you…',
    'resources' => 'A safe resource they could explore…',
    'similar' => 'A small “me too” story…',
    _ => 'A short word of care…',
  };
}
