import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../core/app_models.dart';
import '../../core/app_theme.dart';
import '../../data/umbrella_repository.dart';
import '../../widgets/app_components.dart';
import '../feed/story_card.dart';
import '../profile/profile_screens.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const _debounceDuration = Duration(milliseconds: 260);
  static const _suggestions = <String>[
    'anxiety',
    'music',
    'school',
    'belonging',
    'small win',
    'need advice',
  ];
  static const _categoryQueries = <String, String>{
    'identity': 'identity',
    'school': 'school',
    'mind': 'mental health',
    'culture': 'culture',
    'wins': 'small win',
    'vent': 'venting',
  };

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  SearchResults? _results;
  Object? _error;
  String _activeQuery = '';
  bool _loading = false;
  int _requestSerial = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    final request = ++_requestSerial;

    setState(() {
      _activeQuery = query;
      _error = null;
      _results = null;
      _loading = false;
    });

    if (query.isEmpty) return;
    _debounce = Timer(
      _debounceDuration,
      () => _performSearch(query, request, announceLoading: true),
    );
  }

  void _submit(String value) {
    _debounce?.cancel();
    final query = value.trim();
    final request = ++_requestSerial;
    setState(() {
      _activeQuery = query;
      _error = null;
      _results = null;
      _loading = query.isNotEmpty;
    });
    if (query.isNotEmpty) _performSearch(query, request);
  }

  void _chooseQuery(String query) {
    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _searchFocus.unfocus();
    _submit(query);
  }

  void _clearQuery() {
    _debounce?.cancel();
    ++_requestSerial;
    _searchController.clear();
    setState(() {
      _activeQuery = '';
      _results = null;
      _error = null;
      _loading = false;
    });
    _searchFocus.requestFocus();
  }

  Future<void> _performSearch(
    String query,
    int request, {
    bool announceLoading = false,
  }) async {
    if (!mounted || request != _requestSerial) return;
    if (announceLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final repository = AppScope.of(context).repository;
    try {
      final results = await repository.search(query);
      if (!mounted ||
          request != _requestSerial ||
          query != _activeQuery ||
          query != _searchController.text.trim()) {
        return;
      }
      setState(() {
        _results = results;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted ||
          request != _requestSerial ||
          query != _activeQuery ||
          query != _searchController.text.trim()) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _retry() {
    if (_activeQuery.isEmpty) return;
    final request = ++_requestSerial;
    _performSearch(_activeQuery, request, announceLoading: true);
  }

  void _refreshAfterChange() {
    if (_activeQuery.isEmpty) return;
    final request = ++_requestSerial;
    _performSearch(_activeQuery, request);
  }

  void _openProfile(String username) {
    if (username.trim().isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicProfileScreen(username: username),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return PageFrame(
      title: 'Search Haven',
      subtitle: 'Find people, stories, and shared weather.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchField(
            controller: _searchController,
            focusNode: _searchFocus,
            hasText: _searchController.text.isNotEmpty,
            onChanged: _onQueryChanged,
            onSubmitted: _submit,
            onClear: _clearQuery,
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.018, 0.012),
                    end: Offset.zero,
                  ).animate(curved),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.992, end: 1).animate(curved),
                    child: child,
                  ),
                ),
              );
            },
            child: _buildSearchState(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchState() {
    if (_activeQuery.isEmpty) {
      return _SearchDiscovery(
        key: const ValueKey('discovery'),
        onQuerySelected: _chooseQuery,
      );
    }

    if (_loading) {
      return _SearchLoading(
        key: ValueKey('loading-$_activeQuery'),
        query: _activeQuery,
      );
    }

    if (_error != null) {
      return ErrorState(
        key: ValueKey('error-$_activeQuery'),
        message: friendlyError(_error!),
        onRetry: _retry,
      );
    }

    final results = _results;
    if (results == null ||
        (results.people.isEmpty && results.stories.isEmpty)) {
      return EmptyState(
        key: ValueKey('empty-$_activeQuery'),
        icon: Icons.search_off_rounded,
        title: 'Nothing under that umbrella yet',
        message:
            'Try another word, a broader topic, or a person’s username. New stories arrive all the time.',
        action: _clearQuery,
        actionLabel: 'Explore suggestions',
      );
    }

    return _SearchResultsView(
      key: ValueKey('results-$_activeQuery'),
      query: _activeQuery,
      results: results,
      onOpenProfile: _openProfile,
      onStoryChanged: _refreshAfterChange,
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final focused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: focused ? 0.94 : 0.78),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: focused
                  ? accent.withValues(alpha: 0.62)
                  : Colors.white.withValues(alpha: 0.55),
              width: focused ? 1.35 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: focused
                    ? accent.withValues(alpha: 0.16)
                    : const Color(0x112C164F),
                blurRadius: focused ? 30 : 22,
                offset: Offset(0, focused ? 12 : 9),
              ),
            ],
          ),
          child: child,
        );
      },
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        textCapitalization: TextCapitalization.sentences,
        autocorrect: false,
        decoration: InputDecoration(
          hintText: 'Search stories, people, or tags',
          prefixIcon: Icon(Icons.search_rounded, color: accent),
          suffixIcon: hasText
              ? IconButton(
                  onPressed: onClear,
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _SearchDiscovery extends StatelessWidget {
  const _SearchDiscovery({super.key, required this.onQuerySelected});

  final ValueChanged<String> onQuerySelected;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surface.withValues(alpha: 0.8),
                accent.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x102C164F),
                blurRadius: 22,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(Icons.travel_explore_rounded, color: accent),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find your corner',
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Look for a feeling, a topic, or someone whose words make the day feel less lonely.',
                      style: TextStyle(
                        color: AppTheme.secondaryInk,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const SectionHeader(title: 'Explore a corner'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 10.0;
            final tileWidth = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: communityCategories
                  .map((category) {
                    return SizedBox(
                      width: tileWidth,
                      child: _CategoryTile(
                        category: category,
                        onTap: () => onQuerySelected(
                          _SearchPageState._categoryQueries[category.key] ??
                              category.name,
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            );
          },
        ),
        const SizedBox(height: 25),
        const SectionHeader(title: 'Try searching'),
        const SizedBox(height: 11),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _SearchPageState._suggestions
              .map((suggestion) {
                return ActionChip(
                  onPressed: () => onQuerySelected(suggestion),
                  avatar: Icon(Icons.search_rounded, size: 16, color: accent),
                  label: Text(suggestion),
                  labelStyle: const TextStyle(
                    color: AppTheme.secondaryInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppTheme.surface.withValues(alpha: 0.76),
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final CommunityCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface.withValues(alpha: 0.94),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, size: 19, color: category.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchLoading extends StatelessWidget {
  const _SearchLoading({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CupertinoActivityIndicator(radius: 9),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  'Looking under every umbrella for “$query”…',
                  style: const TextStyle(
                    color: AppTheme.secondaryInk,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const LoadingCards(count: 2),
      ],
    );
  }
}

class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({
    super.key,
    required this.query,
    required this.results,
    required this.onOpenProfile,
    required this.onStoryChanged,
  });

  final String query;
  final SearchResults results;
  final ValueChanged<String> onOpenProfile;
  final VoidCallback onStoryChanged;

  @override
  Widget build(BuildContext context) {
    final total = results.people.length + results.stories.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$total ${total == 1 ? 'match' : 'matches'} for “$query”',
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (results.people.isNotEmpty) ...[
          const SizedBox(height: 22),
          SectionHeader(title: 'People · ${results.people.length}'),
          const SizedBox(height: 11),
          ...results.people.map(
            (profile) => _PersonResultTile(
              profile: profile,
              onTap: () => onOpenProfile(profile.username),
            ),
          ),
        ],
        if (results.stories.isNotEmpty) ...[
          const SizedBox(height: 22),
          SectionHeader(title: 'Stories · ${results.stories.length}'),
          const SizedBox(height: 11),
          ...results.stories.map(
            (story) => StoryCard(
              key: ValueKey('search-${story.id}'),
              story: story,
              onChanged: onStoryChanged,
              onOpenProfile: onOpenProfile,
            ),
          ),
        ],
      ],
    );
  }
}

class _PersonResultTile extends StatelessWidget {
  const _PersonResultTile({required this.profile, required this.onTap});

  final UserProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final handle = profile.pronouns.trim().isEmpty
        ? '@${profile.username}'
        : '@${profile.username} · ${profile.pronouns}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(21),
          side: const BorderSide(color: AppTheme.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileAvatar(profile: profile, size: 50),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.visibleName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        handle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.mutedInk,
                          fontSize: 12,
                        ),
                      ),
                      if (profile.statusWeather.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          profile.statusWeather,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.secondaryInk,
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                      if (profile.tags.isNotEmpty) ...[
                        const SizedBox(height: 9),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: profile.tags
                              .take(3)
                              .map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: profile.accent.withValues(
                                      alpha: 0.09,
                                    ),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: TextStyle(
                                      color: profile.accent,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              })
                              .toList(growable: false),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.mutedInk,
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
