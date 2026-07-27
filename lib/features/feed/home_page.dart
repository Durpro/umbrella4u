import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../core/app_models.dart';
import '../../core/app_theme.dart';
import '../../data/umbrella_repository.dart';
import '../../widgets/app_components.dart';
import '../auth/auth_screens.dart';
import '../profile/profile_screens.dart';
import 'story_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.onOpenNotifications,
    required this.onCreate,
    required this.onOpenMenu,
  });

  final VoidCallback onOpenNotifications;
  final VoidCallback onCreate;
  final VoidCallback onOpenMenu;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  List<StoryItem> _stories = const [];
  CommunityPulseData? _pulse;
  Object? _error;
  bool _loading = true;
  String? _category;
  final _categoryScrollController = ScrollController();
  bool _categoriesAtStart = true;
  bool _categoriesAtEnd = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _categoryScrollController.addListener(_updateCategoryScrollEdges);
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateCategoryScrollEdges(),
    );
  }

  @override
  void dispose() {
    _categoryScrollController
      ..removeListener(_updateCategoryScrollEdges)
      ..dispose();
    super.dispose();
  }

  void _updateCategoryScrollEdges() {
    if (!_categoryScrollController.hasClients) return;
    final position = _categoryScrollController.position;
    final atStart = position.pixels <= 0.5;
    final atEnd = position.pixels >= position.maxScrollExtent - 0.5;
    if (atStart == _categoriesAtStart && atEnd == _categoriesAtEnd) return;
    if (mounted) {
      setState(() {
        _categoriesAtStart = atStart;
        _categoriesAtEnd = atEnd;
      });
    }
  }

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = AppScope.of(context).repository;
    try {
      final results = await Future.wait<dynamic>([
        repository.fetchStories(category: _category),
        repository.fetchCommunityPulse(),
      ]);
      if (!mounted) return;
      AppScope.of(context).reportRequestSuccess();
      setState(() {
        _stories = results[0] as List<StoryItem>;
        _pulse = results[1] as CommunityPulseData;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      AppScope.of(context).reportRequestFailure(error);
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _selectCategory(String? category) async {
    if (_category == category) return;
    setState(() => _category = category);
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = AppScope.of(context);
    final guestWall =
        !controller.isLoggedIn && !controller.isDemo && _stories.length > 3;
    final shownStories = guestWall ? _stories.take(3).toList() : _stories;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: const PageStorageKey<String>('haven-feed'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: refresh),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 122),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                EntranceReveal(
                  key: const ValueKey<String>('home-header'),
                  child: Row(
                    children: [
                      const BrandMark(size: 44),
                      const Spacer(),
                      RoundIconButton(
                        icon: Icons.notifications_none_rounded,
                        tooltip: 'Notifications',
                        badge: controller.isLoggedIn,
                        onPressed: widget.onOpenNotifications,
                      ),
                      const SizedBox(width: 8),
                      RoundIconButton(
                        icon: Icons.menu_rounded,
                        tooltip: 'More',
                        onPressed: widget.onOpenMenu,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                EntranceReveal(
                  key: const ValueKey<String>('home-welcome'),
                  delay: const Duration(milliseconds: 55),
                  child: _WelcomeCard(onCreate: widget.onCreate),
                ),
                const SizedBox(height: 15),
                if (controller.isDemo)
                  EntranceReveal(
                    key: const ValueKey<String>('home-demo'),
                    delay: const Duration(milliseconds: 90),
                    child: const _DemoBanner(),
                  ),
                EntranceReveal(
                  key: const ValueKey<String>('home-pulse'),
                  delay: const Duration(milliseconds: 105),
                  child: _PulseCard(pulse: _pulse),
                ),
                const SizedBox(height: 15),
                EntranceReveal(
                  key: const ValueKey<String>('home-safety'),
                  delay: const Duration(milliseconds: 145),
                  child: const _SafetyCard(),
                ),
                const SizedBox(height: 24),
                EntranceReveal(
                  key: const ValueKey<String>('home-weather-heading'),
                  delay: const Duration(milliseconds: 175),
                  child: const SectionHeader(title: 'Browse the weather'),
                ),
                const SizedBox(height: 11),
                EntranceReveal(
                  key: const ValueKey<String>('home-weather-filters'),
                  delay: const Duration(milliseconds: 195),
                  child: SizedBox(
                    height: 44,
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          _categoriesAtStart
                              ? Colors.black
                              : Colors.transparent,
                          Colors.black,
                          Colors.black,
                          _categoriesAtEnd ? Colors.black : Colors.transparent,
                        ],
                        stops: const [0, 0.06, 0.91, 1],
                      ).createShader(bounds),
                      child: ListView(
                        controller: _categoryScrollController,
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              avatar: const Icon(
                                Icons.grid_view_rounded,
                                size: 17,
                              ),
                              label: const Text('All stories'),
                              selected: _category == null,
                              onSelected: (_) => _selectCategory(null),
                            ),
                          ),
                          ...communityCategories.map(
                            (category) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
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
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (_) =>
                                    _selectCategory(category.key),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                EntranceReveal(
                  key: const ValueKey<String>('home-stories-heading'),
                  delay: const Duration(milliseconds: 215),
                  child: Row(
                    children: [
                      Text(
                        _category == null
                            ? 'Community stories'
                            : categoryFor(_category!).name,
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
                ),
                if (_error != null && _stories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _FeedRefreshNotice(
                    message: friendlyError(_error!),
                    onRetry: refresh,
                  ),
                ],
                const SizedBox(height: 12),
                if (_loading && _stories.isEmpty)
                  const LoadingCards()
                else if (_error != null && _stories.isEmpty)
                  ErrorState(message: friendlyError(_error!), onRetry: refresh)
                else if (_stories.isEmpty)
                  EmptyState(
                    icon: Icons.cloud_outlined,
                    title: 'No stories here yet',
                    message:
                        'Be the first to share this weather with the community.',
                    action: controller.isLoggedIn || controller.isDemo
                        ? widget.onCreate
                        : null,
                    actionLabel: 'Share a story',
                  )
                else ...[
                  ...shownStories.asMap().entries.map((entry) {
                    final storyIndex = entry.key;
                    final story = entry.value;
                    final staggerIndex = storyIndex > 4 ? 4 : storyIndex;
                    return EntranceReveal(
                      key: ValueKey<String>('feed-story-${story.id}'),
                      delay: Duration(milliseconds: 60 + (staggerIndex * 30)),
                      duration: const Duration(milliseconds: 360),
                      slideFrom: const Offset(0, 0.018),
                      scaleFrom: 0.996,
                      child: StoryCard(
                        key: ValueKey(story.id),
                        story: story,
                        onChanged: refresh,
                        onOpenProfile: (username) => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PublicProfileScreen(username: username),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (guestWall)
                    EntranceReveal(
                      key: const ValueKey<String>('home-guest-wall'),
                      delay: const Duration(milliseconds: 180),
                      child: _GuestWall(onCreate: widget.onCreate),
                    ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedRefreshNotice extends StatelessWidget {
  const _FeedRefreshNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 9, 7, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1CFD5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: Color(0xFFB44359),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF7B3947), fontSize: 11),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.of(context).profile;
    return Container(
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
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -30,
            child: Icon(
              Icons.umbrella_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.11),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  profile == null
                      ? 'A KINDER CORNER OF THE INTERNET'
                      : 'WELCOME BACK, ${profile.visibleName.toUpperCase()}',
                  style: const TextStyle(
                    color: Color(0xFFF1EAFE),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'What’s your\nweather today?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Share only what you’re carrying right now.',
                style: TextStyle(color: Color(0xFFE4D9FA), fontSize: 13),
              ),
              const SizedBox(height: 19),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Share your weather'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  minimumSize: const Size(0, 44),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseCard extends StatelessWidget {
  const _PulseCard({required this.pulse});

  final CommunityPulseData? pulse;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: BorderRadius.circular(19),
      opacity: 0.8,
      showShadow: false,
      child: Row(
        children: [
          Icon(
            Icons.water_drop_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _PulseStat(value: pulse?.stories, label: 'stories'),
          ),
          Container(width: 1, height: 26, color: AppTheme.border),
          Expanded(
            child: _PulseStat(value: pulse?.umbrellas, label: 'umbrellas'),
          ),
          Container(width: 1, height: 26, color: AppTheme.border),
          Expanded(
            child: _PulseStat(value: pulse?.sunny, label: 'skies cleared'),
          ),
        ],
      ),
    );
  }
}

class _PulseStat extends StatelessWidget {
  const _PulseStat({required this.value, required this.label});

  final int? value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value?.toString() ?? '—',
          style: const TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.mutedInk, fontSize: 9.5),
        ),
      ],
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0DFC0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🫂', style: TextStyle(fontSize: 20)),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You’re safe to be honest here.',
                  style: TextStyle(
                    color: Color(0xFF5E431E),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'However you’re feeling, you’re welcome—just be kind to yourself and everyone else.',
                  style: TextStyle(
                    color: Color(0xFF7D6138),
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

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9C8FF)),
      ),
      child: const Row(
        children: [
          Icon(Icons.science_outlined, color: Color(0xFF75558F), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Preview data is showing because Supabase was not provided when the app started.',
              style: TextStyle(
                color: Color(0xFF55348F),
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestWall extends StatelessWidget {
  const _GuestWall({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: const Color(0xFF241835),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.umbrella_rounded,
            color: Color(0xFFCAB6FF),
            size: 34,
          ),
          const SizedBox(height: 13),
          const Text(
            'Come in from the rain',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Create an anonymous account to keep reading, share a story, and support someone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFC7BDCF),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 17),
          FilledButton(
            onPressed: () => requireMember(context),
            child: const Text('Log in or sign up'),
          ),
        ],
      ),
    );
  }
}
