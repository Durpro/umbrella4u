import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_controller.dart';
import '../../core/app_models.dart';
import '../../core/app_theme.dart';
import '../../data/umbrella_repository.dart';
import '../../widgets/app_components.dart';
import '../auth/auth_screens.dart';
import '../feed/story_card.dart';
import '../settings/settings_screens.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  UserProfile? _profile;
  ProfileStats? _stats;
  List<StoryItem> _stories = const [];
  Object? _error;
  bool _loading = true;
  bool _checkedDependencies = false;
  String? _loadedUserId;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = AppScope.of(context).repository.currentUser?.id;
    if (!_checkedDependencies || _loadedUserId != userId) {
      _checkedDependencies = true;
      _loadedUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    final controller = AppScope.of(context);
    if (controller.isDemo) {
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final source = await controller.repository.fetchStories();
        final stories = source
            .take(2)
            .map(_asDemoProfileStory)
            .toList(growable: false);
        if (!mounted) return;
        setState(() {
          _profile = _demoProfile;
          _stats = ProfileStats(
            stories: stories.length,
            received: stories.fold(
              0,
              (total, story) => total + story.umbrellaCount,
            ),
            sent: _demoProfile.umbrellasSent,
            streak: _demoProfile.streakCount,
          );
          _stories = stories;
          _loading = false;
        });
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _error = error;
          _loading = false;
        });
      }
      return;
    }
    if (!controller.isLoggedIn) {
      setState(() {
        _profile = null;
        _stats = null;
        _stories = const [];
        _error = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (controller.profile == null) await controller.refreshProfile();
      final profile = controller.profile;
      if (profile == null) {
        // Surface why the load failed when the controller knows, so a dropped
        // connection does not read as a missing profile.
        throw controller.profileError ??
            const AppException('Your profile could not be found.');
      }
      final results = await Future.wait<dynamic>([
        controller.repository.fetchProfileStats(),
        controller.repository.fetchStories(),
      ]);
      final allStories = results[1] as List<StoryItem>;
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _stats = results[0] as ProfileStats;
        _stories = allStories
            .where((story) => story.isMine)
            .toList(growable: false);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _openEditor() async {
    final profile = _profile;
    if (profile == null) return;
    if (AppScope.of(context).isDemo) {
      showAppMessage(
        context,
        'Profile editing becomes active when the app is connected to Supabase.',
      );
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditProfileScreen(profile: profile),
      ),
    );
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = AppScope.of(context);

    if (!controller.isLoggedIn && !controller.isDemo) {
      return PageFrame(
        title: 'Your profile',
        subtitle: 'A gentle corner that feels like you.',
        child: EmptyState(
          icon: Icons.person_outline_rounded,
          title: 'Your profile is waiting',
          message:
              'Log in to see your stories, streak, badges, and the umbrellas you have shared.',
          action: () => requireMember(context),
          actionLabel: 'Log in or sign up',
        ),
      );
    }

    if (_loading && _profile == null) {
      return const PageFrame(
        title: 'Your profile',
        subtitle: 'Gathering your corner of Haven…',
        child: LoadingCards(count: 2),
      );
    }

    if (_error != null && _profile == null) {
      return PageFrame(
        title: 'Your profile',
        subtitle: 'A gentle corner that feels like you.',
        child: ErrorState(message: friendlyError(_error!), onRetry: _load),
      );
    }

    final profile = _profile ?? controller.profile;
    if (profile == null) {
      return PageFrame(
        title: 'Your profile',
        subtitle: 'A gentle corner that feels like you.',
        child: ErrorState(
          message: 'Your profile is not available yet.',
          onRetry: _load,
        ),
      );
    }

    final stats =
        _stats ??
        ProfileStats(
          stories: _stories.length,
          received: 0,
          sent: profile.umbrellasSent,
          streak: profile.streakCount,
        );

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: const PageStorageKey<String>('my-profile'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: _load),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 122),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                EntranceReveal(
                  duration: const Duration(milliseconds: 360),
                  slideFrom: const Offset(0, 0.018),
                  scaleFrom: 0.996,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your profile',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your place to show up as yourself.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      RoundIconButton(
                        icon: Icons.settings_outlined,
                        tooltip: 'Settings',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                EntranceReveal(
                  delay: const Duration(milliseconds: 70),
                  child: _ProfileHero(
                    profile: profile,
                    stats: stats,
                    primaryActionLabel: 'Edit profile',
                    primaryActionIcon: Icons.edit_outlined,
                    onPrimaryAction: _openEditor,
                    secondaryActionLabel: 'Settings',
                    onSecondaryAction: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _InlineNotice(
                    message: friendlyError(_error!),
                    onRetry: _load,
                  ),
                ],
                const SizedBox(height: 27),
                Row(
                  children: [
                    Text(
                      'Your stories',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    if (_loading && _stories.isNotEmpty)
                      CupertinoActivityIndicator(
                        radius: 9,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Named and anonymous stories both stay yours.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                if (_stories.isEmpty && !_loading)
                  const EmptyState(
                    icon: Icons.auto_stories_outlined,
                    title: 'No stories yet',
                    message:
                        'When you share your weather, your stories will collect here.',
                  )
                else
                  ..._stories.map(
                    (story) => StoryCard(
                      key: ValueKey<String>('profile-${story.id}'),
                      story: story,
                      onChanged: _load,
                      onOpenProfile: (username) => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              PublicProfileScreen(username: username),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.profile});

  final UserProfile? profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _avatars = [
    '☂️',
    '🌙',
    '🌱',
    '⭐',
    '🌈',
    '🫂',
    '🎧',
    '📚',
    '🎨',
    '🌻',
    '🦋',
    '☁️',
  ];

  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _pronouns = TextEditingController();
  final _status = TextEditingController();
  final _about = TextEditingController();
  final _tagInput = TextEditingController();
  final List<String> _tags = [];
  bool _initialized = false;
  bool _busy = false;
  bool _saved = false;
  String _avatar = '☂️';

  // What the form was seeded with, so an exit can tell an edited profile from
  // an untouched one.
  UserProfile? _source;
  String _initialAvatar = '☂️';
  List<String> _initialTags = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final profile = widget.profile ?? AppScope.of(context).profile;
    if (profile == null) return;
    _displayName.text = profile.displayName;
    _username.text = profile.username;
    _pronouns.text = profile.pronouns;
    _status.text = profile.statusWeather;
    _about.text = profile.aboutMe;
    _tags.addAll(profile.tags.take(8));
    _avatar = profile.avatarUrl.startsWith('emoji:')
        ? profile.avatarUrl.substring(6)
        : profile.avatarText;

    _source = profile;
    _initialAvatar = _avatar;
    _initialTags = List<String>.unmodifiable(_tags);
  }

  bool get _hasUnsavedChanges {
    final profile = _source;
    if (profile == null || _saved) return false;
    return _displayName.text.trim() != profile.displayName.trim() ||
        _username.text.trim().toLowerCase() !=
            profile.username.trim().toLowerCase() ||
        _pronouns.text.trim() != profile.pronouns.trim() ||
        _status.text.trim() != profile.statusWeather.trim() ||
        _about.text.trim() != profile.aboutMe.trim() ||
        _avatar != _initialAvatar ||
        _tagInput.text.trim().isNotEmpty ||
        !listEquals(_tags, _initialTags);
  }

  Future<void> _handlePop(bool didPop) async {
    if (didPop || _busy) return;
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.edit_off_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Leave without saving?'),
        content: const Text(
          'Your profile changes have not been saved yet. They will be lost if '
          'you leave now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC33E55),
            ),
            child: const Text('Discard changes'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _pronouns.dispose();
    _status.dispose();
    _about.dispose();
    _tagInput.dispose();
    super.dispose();
  }

  void _addTag() {
    var tag = _tagInput.text
        .trim()
        .replaceFirst(RegExp(r'^#+'), '')
        .toLowerCase();
    tag = tag.replaceAll(RegExp(r'\s+'), ' ');
    if (tag.length > 20) tag = tag.substring(0, 20).trim();
    if (tag.isNotEmpty && !_tags.contains(tag) && _tags.length < 8) {
      setState(() => _tags.add(tag));
    }
    _tagInput.clear();
  }

  Future<void> _save() async {
    _addTag();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AppScope.of(context).saveProfile({
        'display_name': _displayName.text.trim(),
        'username': _username.text.trim().toLowerCase(),
        'pronouns': _pronouns.text.trim(),
        'status_weather': _status.text.trim(),
        'about_me': _about.text.trim(),
        'avatar_url': 'emoji:$_avatar',
        'tags': List<String>.unmodifiable(_tags),
      });
      if (!mounted) return;
      // The form now matches what is stored, so leaving must not prompt.
      _saved = true;
      showAppMessage(context, 'Your profile is saved.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) showAppMessage(context, friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile ?? AppScope.of(context).profile;
    // Every way out of the editor — the app bar arrow, the system back
    // gesture, and SwipeBackScope — routes through maybePop, so guarding it
    // here covers all of them. `canPop` stays false rather than tracking the
    // form, which would mean rebuilding this list on every keystroke.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handlePop(didPop),
      child: SwipeBackScope(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Edit profile'),
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
          body: profile == null
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 40),
                  children: [
                    EmptyState(
                      icon: Icons.person_off_outlined,
                      title: 'Log in to edit your profile',
                      message:
                          'Your profile details are available after you log in.',
                      action: () => requireMember(context),
                      actionLabel: 'Log in',
                    ),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 48),
                    children: [
                      _EditorIntro(profile: profile, avatar: _avatar),
                      const SizedBox(height: 24),
                      Text(
                        'Choose an avatar',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 11),
                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: _avatars
                            .map(
                              (emoji) => _AvatarChoice(
                                emoji: emoji,
                                selected: emoji == _avatar,
                                onTap: () => setState(() => _avatar = emoji),
                              ),
                            )
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _displayName,
                        maxLength: 30,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                          hintText: 'How you want to appear',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) => value!.trim().isEmpty
                            ? 'Add a display name.'
                            : null,
                      ),
                      const SizedBox(height: 11),
                      TextFormField(
                        controller: _username,
                        maxLength: 24,
                        textCapitalization: TextCapitalization.none,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9_]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'quiet_fern',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                        validator: (value) => _validUsername(value ?? '')
                            ? null
                            : 'Use 3–24 letters, numbers, or underscores.',
                      ),
                      const SizedBox(height: 11),
                      TextFormField(
                        controller: _pronouns,
                        maxLength: 30,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Pronouns',
                          hintText: 'Optional',
                          prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 11),
                      TextFormField(
                        controller: _status,
                        maxLength: 60,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Today’s weather',
                          hintText: '🌤️ better than yesterday',
                          prefixIcon: Icon(Icons.wb_cloudy_outlined),
                        ),
                      ),
                      const SizedBox(height: 11),
                      TextFormField(
                        controller: _about,
                        minLines: 4,
                        maxLines: 7,
                        maxLength: 300,
                        decoration: const InputDecoration(
                          labelText: 'About you',
                          hintText:
                              'Share a little without using your real name, school, address, or contact details.',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _PrivacyReminder(),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Interests',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            '${_tags.length}/8',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_tags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tags
                              .map(
                                (tag) => InputChip(
                                  label: Text('#$tag'),
                                  onDeleted: _busy
                                      ? null
                                      : () => setState(() => _tags.remove(tag)),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      if (_tags.isNotEmpty) const SizedBox(height: 11),
                      TextField(
                        controller: _tagInput,
                        enabled: _tags.length < 8 && !_busy,
                        maxLength: 20,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addTag(),
                        decoration: InputDecoration(
                          labelText: _tags.length >= 8
                              ? 'Eight interests added'
                              : 'Add an interest',
                          hintText: 'music, art, studying…',
                          prefixIcon: const Icon(Icons.tag_rounded),
                          suffixIcon: IconButton(
                            onPressed: _tags.length < 8 && !_busy
                                ? _addTag
                                : null,
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            tooltip: 'Add tag',
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _save,
                          icon: _busy
                              ? const SizedBox(
                                  width: 19,
                                  height: 19,
                                  child: CupertinoActivityIndicator(
                                    radius: 9,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(_busy ? 'Saving…' : 'Save profile'),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key, required this.username});

  final String username;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  UserProfile? _profile;
  List<StoryItem> _stories = const [];
  Object? _error;
  bool _loading = true;
  bool _following = false;
  bool _followBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant PublicProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username) _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = AppScope.of(context).repository;
    try {
      final profile = await repository.fetchProfileByUsername(widget.username);
      if (profile == null) {
        if (!mounted) return;
        setState(() {
          _profile = null;
          _stories = const [];
          _following = false;
          _loading = false;
        });
        return;
      }
      final results = await Future.wait<dynamic>([
        repository.fetchStoriesForUser(profile.id),
        repository.isFollowing(profile.id),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _stories = results[0] as List<StoryItem>;
        _following = results[1] as bool;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_followBusy) return;
    final isMember = await requireMember(context);
    if (!mounted || !isMember) return;
    final profile = _profile;
    if (profile == null) return;
    setState(() => _followBusy = true);
    try {
      final following = await AppScope.of(
        context,
      ).repository.toggleFollow(profile.id, _following);
      if (mounted) setState(() => _following = following);
    } catch (error) {
      if (mounted) showAppMessage(context, friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final currentProfile = AppScope.of(context).profile;
    final isOwn = profile != null && currentProfile?.id == profile.id;

    return SwipeBackScope(
      child: Scaffold(
        appBar: AppBar(
          // Prefer the resolved handle: the value navigated with may have been
          // a display name carried on a story.
          title: Text('@${profile?.username ?? widget.username}'),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: CustomScrollView(
          key: PageStorageKey<String>('public-profile-${widget.username}'),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: _load),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 42),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_loading && profile == null)
                    const LoadingCards(count: 2)
                  else if (_error != null && profile == null)
                    ErrorState(message: friendlyError(_error!), onRetry: _load)
                  else if (profile == null)
                    EmptyState(
                      icon: Icons.person_search_outlined,
                      title: 'No profile found',
                      message:
                          'There is no discoverable member named @${widget.username}.',
                      action: () => Navigator.of(context).pop(),
                      actionLabel: 'Go back',
                    )
                  else ...[
                    EntranceReveal(
                      child: _ProfileHero(
                        profile: profile,
                        stats: ProfileStats(
                          stories: _stories.length,
                          received: _stories.fold(
                            0,
                            (total, story) => total + story.umbrellaCount,
                          ),
                          sent: profile.umbrellasSent,
                          streak: profile.streakCount,
                        ),
                        primaryActionLabel: isOwn
                            ? 'Edit your profile'
                            : _following
                            ? 'Following'
                            : 'Follow',
                        primaryActionIcon: isOwn
                            ? Icons.edit_outlined
                            : _following
                            ? Icons.check_rounded
                            : Icons.person_add_alt_1_rounded,
                        onPrimaryAction: isOwn
                            ? () async {
                                final changed = await Navigator.of(context)
                                    .push<bool>(
                                      MaterialPageRoute<bool>(
                                        builder: (_) =>
                                            EditProfileScreen(profile: profile),
                                      ),
                                    );
                                if (changed == true) await _load();
                              }
                            : _toggleFollow,
                        primaryBusy: _followBusy,
                        primaryOutlined: _following && !isOwn,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      _InlineNotice(
                        message: friendlyError(_error!),
                        onRetry: _load,
                      ),
                    ],
                    const SizedBox(height: 27),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Stories by @${profile.username}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (_loading && _stories.isNotEmpty)
                          CupertinoActivityIndicator(
                            radius: 9,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    if (_stories.isEmpty && !_loading)
                      const EmptyState(
                        icon: Icons.cloud_outlined,
                        title: 'No public stories yet',
                        message:
                            'Anonymous stories always remain separate from a public profile.',
                      )
                    else
                      ..._stories.map(
                        (story) => StoryCard(
                          key: ValueKey<String>('public-profile-${story.id}'),
                          story: story,
                          onChanged: _load,
                          onOpenProfile: (username) {
                            if (username == widget.username) return;
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    PublicProfileScreen(username: username),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.stats,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.primaryBusy = false,
    this.primaryOutlined = false,
  });

  final UserProfile profile;
  final ProfileStats stats;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool primaryBusy;
  final bool primaryOutlined;

  @override
  Widget build(BuildContext context) {
    final accent = profile.accent;
    final badges = _earnedBadges(stats);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x112C164F),
            blurRadius: 26,
            offset: Offset(0, 11),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 118,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent,
                  Color.lerp(accent, const Color(0xFF38205F), 0.58)!,
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  top: -30,
                  child: Icon(
                    _bannerIcon(profile.bannerTheme),
                    size: 158,
                    color: Colors.white.withValues(alpha: 0.11),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'A LITTLE SHELTER OF YOUR OWN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(19, 0, 19, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -29),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: ProfileAvatar(profile: profile, size: 72),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: primaryOutlined
                              ? OutlinedButton.icon(
                                  onPressed: primaryBusy
                                      ? null
                                      : onPrimaryAction,
                                  icon: _ActionIcon(
                                    busy: primaryBusy,
                                    icon: primaryActionIcon,
                                    dark: false,
                                  ),
                                  label: Text(
                                    primaryActionLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : FilledButton.icon(
                                  onPressed: primaryBusy
                                      ? null
                                      : onPrimaryAction,
                                  icon: _ActionIcon(
                                    busy: primaryBusy,
                                    icon: primaryActionIcon,
                                    dark: true,
                                  ),
                                  label: Text(
                                    primaryActionLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.visibleName,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '@${profile.username}'
                        '${profile.pronouns.trim().isEmpty ? '' : ' · ${profile.pronouns.trim()}'}',
                        style: const TextStyle(
                          color: AppTheme.secondaryInk,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (profile.statusWeather.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            profile.statusWeather.trim(),
                            style: TextStyle(
                              color: Color.lerp(accent, AppTheme.ink, 0.28),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -4),
                  child: _ProfileStatsRow(stats: stats),
                ),
                if (profile.aboutMe.trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    profile.aboutMe.trim(),
                    style: const TextStyle(
                      color: AppTheme.secondaryInk,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                ],
                if (profile.tags.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: profile.tags
                        .take(8)
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F1FA),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                color: AppTheme.secondaryInk,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
                if (badges.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: badges
                        .map((badge) => _BadgeChip(badge: badge))
                        .toList(growable: false),
                  ),
                ],
                if (secondaryActionLabel != null &&
                    onSecondaryAction != null) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onSecondaryAction,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: Text(secondaryActionLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.busy,
    required this.icon,
    required this.dark,
  });

  final bool busy;
  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (!busy) return Icon(icon, size: 18);
    return SizedBox(
      width: 17,
      height: 17,
      child: CupertinoActivityIndicator(
        radius: 8,
        color: dark ? Colors.white : Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _ProfileStatsRow extends StatelessWidget {
  const _ProfileStatsRow({required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _Stat(value: stats.stories, label: 'stories'),
          const _StatDivider(),
          _Stat(value: stats.received, label: 'received'),
          const _StatDivider(),
          _Stat(value: stats.sent, label: 'sent'),
          const _StatDivider(),
          _Stat(value: stats.streak, label: 'day streak'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.mutedInk, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: AppTheme.border);
  }
}

class _BadgeData {
  const _BadgeData(this.emoji, this.label);

  final String emoji;
  final String label;
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final _BadgeData badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E9),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFF0DFC0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            badge.label,
            style: const TextStyle(
              color: Color(0xFF73552A),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorIntro extends StatelessWidget {
  const _EditorIntro({required this.profile, required this.avatar});

  final UserProfile profile;
  final String avatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: profile.accent,
              shape: BoxShape.circle,
            ),
            child: Text(avatar, style: const TextStyle(fontSize: 25)),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Make this space yours',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Keep personal details private. A nickname and a little personality are enough.',
                  style: TextStyle(
                    color: AppTheme.secondaryInk,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Choose $emoji as avatar',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 51,
          height: 51,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.14)
                : Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : AppTheme.border,
              width: selected ? 1.7 : 1,
            ),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }
}

class _PrivacyReminder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF0DFC0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF8A642D)),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Leave out your real name, school, address, phone number, email, and social handles.',
              style: TextStyle(
                color: Color(0xFF76562A),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF1CFD5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: Color(0xFFB44359),
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF7B3947), fontSize: 11.5),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

List<_BadgeData> _earnedBadges(ProfileStats stats) {
  final badges = <_BadgeData>[];
  if (stats.sent >= 100) {
    badges.add(const _BadgeData('👑', 'Guardian'));
  } else if (stats.sent >= 50) {
    badges.add(const _BadgeData('💞', 'Shelter'));
  } else if (stats.sent >= 10) {
    badges.add(const _BadgeData('🫂', 'Friend'));
  }

  if (stats.streak >= 100) {
    badges.add(const _BadgeData('🏆', '100-day shelter'));
  } else if (stats.streak >= 30) {
    badges.add(const _BadgeData('🌟', '30 days showing up'));
  } else if (stats.streak >= 14) {
    badges.add(const _BadgeData('🌊', 'Two weeks steady'));
  } else if (stats.streak >= 7) {
    badges.add(const _BadgeData('☂️', 'A week showing up'));
  } else if (stats.streak >= 3) {
    badges.add(const _BadgeData('🌱', 'Three-day streak'));
  }

  if (stats.stories >= 50) {
    badges.add(const _BadgeData('📖', '50 stories shared'));
  } else if (stats.stories >= 10) {
    badges.add(const _BadgeData('📝', '10 stories shared'));
  } else if (stats.stories >= 1) {
    badges.add(const _BadgeData('✍️', 'First story shared'));
  }
  return badges;
}

IconData _bannerIcon(String bannerTheme) {
  return switch (bannerTheme) {
    'meadow' => Icons.local_florist_rounded,
    'sunset' => Icons.wb_twilight_rounded,
    'stars' => Icons.auto_awesome_rounded,
    'ocean' => Icons.waves_rounded,
    _ => Icons.umbrella_rounded,
  };
}

bool _validUsername(String value) {
  return RegExp(r'^[A-Za-z0-9_]{3,24}$').hasMatch(value.trim());
}

const _demoProfile = UserProfile(
  id: 'demo-profile',
  username: 'quiet_fern',
  displayName: 'Quiet Fern',
  pronouns: 'they/them',
  statusWeather: '🌤️ taking today one step at a time',
  aboutMe:
      'Playlists on repeat, rainy-day sketches, and learning to be a little kinder to myself.',
  accentColor: '#75558F',
  avatarUrl: 'emoji:🌿',
  bannerTheme: 'rain',
  tags: ['music', 'art', 'books', 'trying my best'],
  discoverable: true,
  notifyEmail: true,
  onboarded: true,
  postCount: 8,
  streakCount: 7,
  umbrellasSent: 24,
  isModerator: false,
);

StoryItem _asDemoProfileStory(StoryItem story) {
  return StoryItem(
    id: 'profile-${story.id}',
    authorId: _demoProfile.id,
    authorName: _demoProfile.username,
    anonymous: false,
    text: story.text,
    intent: story.intent,
    category: story.category,
    contentWarning: story.contentWarning,
    umbrellaCount: story.umbrellaCount,
    hugCount: story.hugCount,
    viewCount: story.viewCount,
    weather: story.weather,
    createdAt: story.createdAt,
    pollOptions: story.pollOptions,
    myVoteOptionId: story.myVoteOptionId,
    isMine: true,
    hasUmbrella: false,
    hasHug: story.hasHug,
  );
}
