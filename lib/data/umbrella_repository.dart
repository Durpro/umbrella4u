import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_models.dart';

class AppConfig {
  const AppConfig._();

  // These client-safe defaults connect the app to Umbrella4U out of the box.
  // A build can still target another project with matching --dart-define values.
  // Never put a service-role or other privileged secret in a client build.
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bavvgrqvwwcetebconfj.supabase.co',
  );
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_H7UJT62kp8-WUEmWoeg9mQ_PDidVGdW',
  );

  static bool get isSupabaseConfigured {
    return Uri.tryParse(supabaseUrl)?.hasScheme == true &&
        supabasePublishableKey.trim().isNotEmpty;
  }
}

class UmbrellaRepository {
  UmbrellaRepository({SupabaseClient? client}) : this._(client);

  UmbrellaRepository._(this._client) {
    _demoStories.addAll(_makeDemoStories());
  }

  final SupabaseClient? _client;
  final List<StoryItem> _demoStories = [];

  bool get isLive => _client != null;
  User? get currentUser => _client?.auth.currentUser;
  Stream<AuthState> get authChanges =>
      _client?.auth.onAuthStateChange ?? const Stream<AuthState>.empty();

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    return client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: kIsWeb
          ? '${Uri.base.origin}/auth/confirm'
          : 'ca.umbrella4u://login-callback/',
    );
  }

  Future<void> resetPassword(String email) async {
    final client = _requireClient();
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb
          ? '${Uri.base.origin}/auth/reset'
          : 'ca.umbrella4u://reset-password/',
    );
  }

  Future<void> updatePassword(String password) async {
    final client = _requireClient();
    _requireUser();
    await client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signOut() async {
    await _client?.auth.signOut(scope: SignOutScope.global);
  }

  Future<UserProfile?> fetchCurrentProfile() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return null;

    final map = await client
        .from('profiles')
        .select(_profileProjection)
        .eq('id', user.id)
        .maybeSingle();
    return map == null ? null : UserProfile.fromMap(map);
  }

  Future<UserProfile?> fetchProfileByUsername(String username) async {
    final client = _client;
    if (client == null) {
      return _demoPeople
          .where((profile) => profile.username == username)
          .firstOrNull;
    }
    final map = await client
        .from('profiles')
        .select(_publicProfileProjection)
        .eq('username', username)
        .eq('discoverable', true)
        .maybeSingle();
    return map == null ? null : UserProfile.fromMap(map);
  }

  Future<void> updateProfile(Map<String, dynamic> values) async {
    final client = _requireClient();
    final user = _requireUser();
    await client.from('profiles').update(values).eq('id', user.id);
  }

  Future<ProfileStats> fetchProfileStats() async {
    if (_client == null) {
      return const ProfileStats(stories: 4, received: 18, sent: 11, streak: 3);
    }
    final user = _requireUser();
    final ownIds = await fetchMyStoryIds();
    var received = 0;
    if (ownIds.isNotEmpty) {
      final rows = await _client
          .from('stories')
          .select('id,umbrella_count')
          .inFilter('id', ownIds.toList());
      for (final row in _maps(rows)) {
        received += _toInt(row['umbrella_count']);
      }
    }
    final profile = await _client
        .from('profiles')
        .select('umbrellas_sent,streak_count')
        .eq('id', user.id)
        .maybeSingle();
    return ProfileStats(
      stories: ownIds.length,
      received: received,
      sent: _toInt(profile?['umbrellas_sent']),
      streak: _toInt(profile?['streak_count']),
    );
  }

  Future<Set<String>> fetchMyStoryIds() async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) return <String>{};
    final rows = await client.from('story_authors').select('story_id');
    return _maps(
      rows,
    ).map((row) => row['story_id']?.toString()).whereType<String>().toSet();
  }

  Future<List<StoryItem>> fetchStories({String? category}) async {
    final client = _client;
    if (client == null) {
      final source = category == null
          ? _demoStories
          : _demoStories.where((story) => story.category == category);
      return List<StoryItem>.unmodifiable(source);
    }

    dynamic query = client
        .from('stories')
        .select(_storyProjection)
        .eq('state', 'live');
    if (category != null) query = query.eq('category', category);
    final rows = await query.order('created_at', ascending: false).limit(50);

    return _hydrateStoryMaps(_maps(rows));
  }

  Future<List<StoryItem>> _hydrateStoryMaps(
    List<Map<String, dynamic>> maps,
  ) async {
    final client = _client;
    if (client == null) {
      return maps.map(StoryItem.fromMap).toList(growable: false);
    }
    final ids = maps
        .map((row) => row['id']?.toString())
        .whereType<String>()
        .toList(growable: false);
    if (ids.isEmpty) return const [];

    final currentUser = client.auth.currentUser;
    final hydration = await Future.wait<dynamic>([
      client
          .from('poll_options')
          .select('id,story_id,idx,label,vote_count')
          .inFilter('story_id', ids)
          .order('idx'),
      fetchMyStoryIds(),
      if (currentUser != null)
        client
            .from('umbrellas')
            .select('story_id')
            .eq('user_id', currentUser.id)
            .inFilter('story_id', ids),
      if (currentUser != null)
        client
            .from('hugs')
            .select('story_id')
            .eq('user_id', currentUser.id)
            .inFilter('story_id', ids),
      if (currentUser != null)
        client
            .from('poll_votes')
            .select('story_id,option_id')
            .eq('user_id', currentUser.id)
            .inFilter('story_id', ids),
    ]);

    final pollsByStory = <String, List<PollOption>>{};
    final pollRows = hydration[0];
    for (final map in _maps(pollRows)) {
      final option = PollOption.fromMap(map);
      pollsByStory.putIfAbsent(option.storyId, () => []).add(option);
    }

    // story_authors is the only reliable owner mapping for anonymous stories.
    final myIds = hydration[1] as Set<String>;
    final umbrellaIds = <String>{};
    final hugIds = <String>{};
    final myVotes = <String, String>{};
    if (currentUser != null) {
      // These queries explicitly filter to the current user. Story authors can
      // read support received under RLS, but that must not mark their own action.
      final supportRows = hydration[2];
      umbrellaIds.addAll(
        _maps(
          supportRows,
        ).map((row) => row['story_id']?.toString()).whereType<String>(),
      );
      final hugRows = hydration[3];
      hugIds.addAll(
        _maps(
          hugRows,
        ).map((row) => row['story_id']?.toString()).whereType<String>(),
      );
      final voteRows = hydration[4];
      for (final row in _maps(voteRows)) {
        final storyId = row['story_id']?.toString();
        final optionId = row['option_id']?.toString();
        if (storyId != null && optionId != null) myVotes[storyId] = optionId;
      }
    }

    return maps
        .map((map) {
          final id = map['id'].toString();
          return StoryItem.fromMap(
            map,
            pollOptions: pollsByStory[id] ?? const [],
            myVoteOptionId: myVotes[id],
            isMine: myIds.contains(id),
            hasUmbrella: umbrellaIds.contains(id),
            hasHug: hugIds.contains(id),
          );
        })
        .toList(growable: false);
  }

  Future<List<StoryItem>> fetchStoriesForUser(String userId) async {
    final client = _client;
    if (client == null) {
      return _demoStories
          .where((story) => story.authorId == userId && !story.anonymous)
          .toList(growable: false);
    }
    final rows = await client
        .from('stories')
        .select(_storyProjection)
        .eq('author_id', userId)
        .eq('anonymous', false)
        .eq('state', 'live')
        .order('created_at', ascending: false)
        .limit(30);
    return _hydrateStoryMaps(_maps(rows));
  }

  Future<CommunityPulseData> fetchCommunityPulse() async {
    if (_client == null) {
      return CommunityPulseData(
        stories: _demoStories.length,
        umbrellas: _demoStories.fold(
          0,
          (total, story) => total + story.umbrellaCount,
        ),
        sunny: _demoStories.where((story) => story.weather >= 4).length,
      );
    }
    try {
      final results = await Future.wait<dynamic>([
        _client.rpc('community_pulse'),
        _client.rpc('sunny_count'),
      ]);
      final pulseData = results[0];
      final pulseRows = _maps(pulseData);
      final sunny = results[1];
      final row = pulseRows.isEmpty
          ? const <String, dynamic>{}
          : pulseRows.first;
      return CommunityPulseData(
        stories: _toInt(row['stories']),
        umbrellas: _toInt(row['umbrellas']),
        sunny: _toInt(sunny),
      );
    } catch (_) {
      // Keep this fallback independent from the feed. Calling fetchStories here
      // would repeat the feed query and all of its ownership/action hydration.
      final rows = await _client
          .from('stories')
          .select('umbrella_count,weather')
          .eq('state', 'live');
      final stories = _maps(rows);
      return CommunityPulseData(
        stories: stories.length,
        umbrellas: stories.fold(
          0,
          (total, story) => total + _toInt(story['umbrella_count']),
        ),
        sunny: stories.where(_isStorySunny).length,
      );
    }
  }

  Future<void> createStory({
    required String text,
    required String intent,
    required String category,
    required bool anonymous,
    required int weather,
    required bool contentWarning,
    List<String> pollOptions = const [],
  }) async {
    if (_client == null) {
      final storyId = 'demo-${DateTime.now().microsecondsSinceEpoch}';
      _demoStories.insert(
        0,
        StoryItem(
          id: storyId,
          authorId: 'demo-me',
          authorName: anonymous ? 'Someone' : 'You',
          anonymous: anonymous,
          text: text.trim(),
          intent: intent,
          category: category,
          contentWarning: contentWarning ? 'Sensitive topic' : '',
          umbrellaCount: 0,
          hugCount: 0,
          viewCount: 0,
          weather: weather,
          createdAt: DateTime.now(),
          isMine: true,
          pollOptions: pollOptions.indexed
              .map(
                (entry) => PollOption(
                  id: 'demo-option-${entry.$1}',
                  storyId: storyId,
                  index: entry.$1,
                  label: entry.$2,
                  voteCount: 0,
                ),
              )
              .toList(growable: false),
        ),
      );
      return;
    }
    if (anonymous && pollOptions.isNotEmpty) {
      throw const AppException(
        'Anonymous polls are temporarily unavailable while we strengthen their privacy.',
      );
    }
    _requireUser();
    final created = await _client
        .from('stories')
        .insert({
          'text': text.trim(),
          'intent': intent,
          'category': category,
          'anonymous': anonymous,
          'weather': weather,
          'content_warning': contentWarning
              ? 'This story discusses a sensitive topic.'
              : null,
        })
        .select('id')
        .single();
    if (pollOptions.isNotEmpty) {
      final storyId = created['id'].toString();
      await _client
          .from('poll_options')
          .insert(
            pollOptions.indexed
                .map(
                  (entry) => {
                    'story_id': storyId,
                    'idx': entry.$1,
                    'label': entry.$2.trim(),
                  },
                )
                .toList(growable: false),
          );
    }
  }

  Future<bool> toggleHug(StoryItem story) async {
    if (_client == null) {
      final index = _demoStories.indexWhere((item) => item.id == story.id);
      if (index >= 0) {
        _demoStories[index] = story.copyWith(
          hasHug: !story.hasHug,
          hugCount: (story.hugCount + (story.hasHug ? -1 : 1))
              .clamp(0, 999999)
              .toInt(),
        );
      }
      return !story.hasHug;
    }
    final user = _requireUser();
    if (story.hasHug) {
      await _client
          .from('hugs')
          .delete()
          .eq('story_id', story.id)
          .eq('user_id', user.id);
      return false;
    }
    await _client.from('hugs').insert({
      'story_id': story.id,
      'user_id': user.id,
    });
    return true;
  }

  Future<void> openUmbrella(StoryItem story, {String? note}) async {
    if (story.isMine) {
      throw const AppException(
        'This is your story—you cannot open an umbrella on your own post.',
      );
    }
    if (_client == null) {
      final index = _demoStories.indexWhere((item) => item.id == story.id);
      if (index >= 0) {
        _demoStories[index] = story.copyWith(
          hasUmbrella: true,
          umbrellaCount: story.umbrellaCount + 1,
        );
      }
      return;
    }
    final user = _requireUser();
    await _client.from('umbrellas').insert({
      'story_id': story.id,
      'user_id': user.id,
      'note': note?.trim().isEmpty == true ? null : note?.trim(),
    });
    if (!story.hasHug) {
      try {
        await _client.from('hugs').insert({
          'story_id': story.id,
          'user_id': user.id,
        });
      } catch (_) {
        // An umbrella is the primary action. A duplicate hug is harmless.
      }
    }
  }

  Future<void> castVote(StoryItem story, String optionId) async {
    if (_client == null) {
      final index = _demoStories.indexWhere((item) => item.id == story.id);
      if (index >= 0 && story.myVoteOptionId == null) {
        _demoStories[index] = story.copyWith(
          myVoteOptionId: optionId,
          pollOptions: story.pollOptions
              .map(
                (option) => option.id == optionId
                    ? PollOption(
                        id: option.id,
                        storyId: option.storyId,
                        index: option.index,
                        label: option.label,
                        voteCount: option.voteCount + 1,
                      )
                    : option,
              )
              .toList(growable: false),
        );
      }
      return;
    }
    final user = _requireUser();
    await _client.from('poll_votes').insert({
      'story_id': story.id,
      'option_id': optionId,
      'user_id': user.id,
    });
  }

  Future<void> reportStory(String storyId, {String reason = 'review'}) async {
    if (_client == null) return;
    final user = _requireUser();
    await _client.from('reports').insert({
      'target_type': 'story',
      'target_id': storyId,
      'reporter_id': user.id,
      'reason': reason,
    });
  }

  Future<void> markNotRelevant(String storyId) async {
    if (_client == null) return;
    final user = _requireUser();
    await _client.from('relevance_marks').insert({
      'story_id': storyId,
      'user_id': user.id,
    });
  }

  Future<void> deleteStory(String storyId) async {
    if (_client == null) {
      _demoStories.removeWhere((story) => story.id == storyId);
      return;
    }
    await _client.from('stories').delete().eq('id', storyId);
  }

  Future<SearchResults> search(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return const SearchResults(people: [], stories: []);
    if (_client == null) {
      final needle = query.toLowerCase();
      return SearchResults(
        people: _demoPeople
            .where(
              (profile) =>
                  profile.visibleName.toLowerCase().contains(needle) ||
                  profile.username.toLowerCase().contains(needle) ||
                  profile.tags.any((tag) => tag.toLowerCase().contains(needle)),
            )
            .toList(growable: false),
        stories: _demoStories
            .where((story) => story.text.toLowerCase().contains(needle))
            .toList(growable: false),
      );
    }

    final safe = query.replaceAll(RegExp(r'[,().]'), ' ').trim();
    final like = '%$safe%';
    final peopleRows = await _client
        .from('profiles')
        .select(_publicProfileProjection)
        .eq('discoverable', true)
        .or('username.ilike.$like,display_name.ilike.$like')
        .limit(20);
    final storyRows = await _client
        .from('stories')
        .select(_storyProjection)
        .eq('state', 'live')
        .ilike('text', like)
        .order('created_at', ascending: false)
        .limit(30);
    final stories = await _hydrateStoryMaps(_maps(storyRows));
    return SearchResults(
      people: _maps(
        peopleRows,
      ).map(UserProfile.fromMap).toList(growable: false),
      stories: stories,
    );
  }

  Future<List<InboxItem>> fetchInbox() async {
    if (_client == null) return _demoInbox;
    final user = _requireUser();
    final ids = await fetchMyStoryIds();
    final stories = <String, Map<String, dynamic>>{};
    if (ids.isNotEmpty) {
      final storyRows = await _client
          .from('stories')
          .select('id,text,category')
          .inFilter('id', ids.toList());
      for (final row in _maps(storyRows)) {
        stories[row['id'].toString()] = row;
      }
    }

    final sentThanks = <String, String>{};
    final sentRows = await _client
        .from('thanks')
        .select('umbrella_id,message')
        .eq('from_user', user.id);
    for (final row in _maps(sentRows)) {
      final umbrellaId = row['umbrella_id']?.toString();
      if (umbrellaId != null) {
        sentThanks[umbrellaId] = row['message']?.toString() ?? '';
      }
    }

    final items = <InboxItem>[];
    if (ids.isNotEmpty) {
      final supportRows = await _client
          .from('umbrellas')
          .select('id,story_id,note,created_at,user_id')
          .inFilter('story_id', ids.toList())
          .order('created_at', ascending: false);
      for (final row in _maps(supportRows)) {
        if (row['user_id']?.toString() == user.id) continue;
        final id = row['id'].toString();
        final story = stories[row['story_id']?.toString()];
        items.add(
          InboxItem(
            id: id,
            kind: 'umbrella',
            umbrellaId: id,
            message: row['note']?.toString() ?? '',
            storyExcerpt: _excerpt(story?['text']?.toString() ?? ''),
            createdAt:
                DateTime.tryParse(
                  row['created_at']?.toString() ?? '',
                )?.toLocal() ??
                DateTime.now(),
            thanksSent: sentThanks[id],
          ),
        );
      }
    }

    final thanksRows = await _client
        .from('thanks')
        .select('id,message,created_at')
        .eq('to_user', user.id)
        .order('created_at', ascending: false);
    for (final row in _maps(thanksRows)) {
      items.add(
        InboxItem(
          id: 'thanks-${row['id']}',
          kind: 'thanks',
          message: row['message']?.toString() ?? '',
          storyExcerpt: '',
          createdAt:
              DateTime.tryParse(
                row['created_at']?.toString() ?? '',
              )?.toLocal() ??
              DateTime.now(),
        ),
      );
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> sendThanks(String umbrellaId, String message) async {
    if (_client == null) return;
    _requireUser();
    await _client.rpc(
      'send_thanks',
      params: {'u_id': umbrellaId, 'msg': message},
    );
  }

  Future<void> submitFeedback(String message) async {
    if (_client == null) return;
    await _client.from('feedback').insert({
      'message': message.trim(),
      'user_id': _client.auth.currentUser?.id,
    });
  }

  Future<bool> isFollowing(String targetId) async {
    if (_client == null || _client.auth.currentUser == null) return false;
    final result = await _client.rpc(
      'is_following',
      params: {'target': targetId},
    );
    return result == true;
  }

  Future<bool> toggleFollow(String targetId, bool currentlyFollowing) async {
    if (_client == null) return !currentlyFollowing;
    _requireUser();
    await _client.rpc(
      currentlyFollowing ? 'unfollow' : 'follow',
      params: {'target': targetId},
    );
    return !currentlyFollowing;
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw const AppException(
        'Supabase is not configured. Start the app with your project URL and publishable key.',
      );
    }
    return client;
  }

  User _requireUser() {
    final user = _client?.auth.currentUser;
    if (user == null) {
      throw const AppException('Please log in to continue.');
    }
    return user;
  }
}

class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

String friendlyError(Object error) {
  final source = error.toString();
  if (source.contains('blocked_content')) {
    return 'This text may contain harmful language. Please rephrase it with care.';
  }
  if (source.contains('personal_info') ||
      source.contains('no_names_in_reply')) {
    return 'Please remove names, email addresses, or other identifying details.';
  }
  if (source.contains('daily_story_limit')) {
    return 'You have shared your five stories for today. A fresh page begins tomorrow.';
  }
  if (source.contains('daily_umbrella_limit')) {
    return 'You have opened all five of today’s umbrellas. They refill tomorrow.';
  }
  if (source.contains('self_umbrella')) {
    return 'You cannot open an umbrella on your own story.';
  }
  if (source.contains('duplicate') || source.contains('unique')) {
    return 'You have already done that.';
  }
  if (source.contains('Invalid login credentials')) {
    return 'That email and password do not match an account.';
  }
  if (source.contains('Email not confirmed')) {
    return 'Please confirm your email before logging in.';
  }
  return source
      .replaceFirst('AuthException(message: ', '')
      .replaceFirst('PostgrestException(message: ', '')
      .split(', code:')[0]
      .replaceAll(RegExp(r'\)$'), '');
}

const _profileProjection =
    'id,username,display_name,pronouns,status_weather,about_me,accent_color,'
    'avatar_url,banner_url,banner_theme,tags,discoverable,notify_email,onboarded,'
    'post_count,streak_count,umbrellas_sent,is_moderator,created_at';

const _publicProfileProjection =
    'id,username,display_name,pronouns,status_weather,about_me,accent_color,'
    'avatar_url,banner_theme,tags,discoverable,post_count,streak_count,'
    'umbrellas_sent,created_at';

const _storyProjection =
    'id,author_id,author_name,anonymous,text,intent,category,content_warning,'
    'umbrella_count,state,created_at,boost_count,hug_count,off_topic_count,'
    'prompt_id,view_count,weather,channel_id';

List<Map<String, dynamic>> _maps(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }
  return const [];
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _isStorySunny(Map<String, dynamic> story) {
  final weather = _toInt(story['weather']).clamp(0, 4).toInt();
  final threshold = [50, 35, 22, 12, 8][weather];
  return _toInt(story['umbrella_count']) >= threshold;
}

String _excerpt(String value) {
  return value.length <= 80 ? value : '${value.substring(0, 80)}…';
}

List<StoryItem> _makeDemoStories() {
  final now = DateTime.now();
  return [
    StoryItem(
      id: 'demo-1',
      authorId: 'demo-rain',
      authorName: 'rainyday',
      anonymous: false,
      text:
          'I finally told a friend what has been weighing on me. I was scared, but they stayed and listened.',
      intent: 'listen',
      category: 'mind',
      contentWarning: '',
      umbrellaCount: 8,
      hugCount: 5,
      viewCount: 24,
      weather: 1,
      createdAt: now.subtract(const Duration(minutes: 18)),
    ),
    StoryItem(
      id: 'demo-2',
      authorId: null,
      authorName: 'Someone',
      anonymous: true,
      text:
          'Being the new person at school is exhausting. Does anyone else rehearse every sentence before speaking?',
      intent: 'similar',
      category: 'school',
      contentWarning: '',
      umbrellaCount: 13,
      hugCount: 9,
      viewCount: 41,
      weather: 2,
      createdAt: now.subtract(const Duration(hours: 2)),
      pollOptions: const [
        PollOption(
          id: 'demo-poll-1',
          storyId: 'demo-2',
          index: 0,
          label: 'All the time',
          voteCount: 12,
        ),
        PollOption(
          id: 'demo-poll-2',
          storyId: 'demo-2',
          index: 1,
          label: 'Sometimes',
          voteCount: 7,
        ),
      ],
    ),
    StoryItem(
      id: 'demo-3',
      authorId: 'demo-sun',
      authorName: 'softsteps',
      anonymous: false,
      text:
          'Small win: I wore the thing I actually wanted to wear today and stopped apologizing for taking up space.',
      intent: 'similar',
      category: 'wins',
      contentWarning: '',
      umbrellaCount: 19,
      hugCount: 16,
      viewCount: 67,
      weather: 4,
      createdAt: now.subtract(const Duration(hours: 7)),
    ),
    StoryItem(
      id: 'demo-4',
      authorId: 'demo-culture',
      authorName: 'betweenworlds',
      anonymous: false,
      text:
          'I love both of my cultures, but sometimes it feels like everyone expects me to choose one.',
      intent: 'similar',
      category: 'culture',
      contentWarning: '',
      umbrellaCount: 6,
      hugCount: 11,
      viewCount: 29,
      weather: 2,
      createdAt: now.subtract(const Duration(days: 1)),
    ),
  ];
}

final _demoPeople = <UserProfile>[
  UserProfile(
    id: 'demo-rain',
    username: 'rainyday',
    displayName: 'Rainy Day',
    pronouns: 'they/them',
    statusWeather: '🌧️ taking it slowly',
    aboutMe: 'Here to listen and make hard days feel a little less lonely.',
    accentColor: '#8B6FC9',
    avatarUrl: 'emoji:🌙',
    bannerTheme: 'rain',
    tags: const ['music', 'school', 'kindness'],
    discoverable: true,
    notifyEmail: false,
    onboarded: true,
    postCount: 8,
    streakCount: 4,
    umbrellasSent: 21,
    isModerator: false,
  ),
  UserProfile(
    id: 'demo-sun',
    username: 'softsteps',
    displayName: 'Soft Steps',
    pronouns: '',
    statusWeather: '🌤️ better than yesterday',
    aboutMe: 'Big feelings, small steps.',
    accentColor: '#3F9D78',
    avatarUrl: 'emoji:🌱',
    bannerTheme: 'meadow',
    tags: const ['art', 'books', 'smallwins'],
    discoverable: true,
    notifyEmail: false,
    onboarded: true,
    postCount: 12,
    streakCount: 7,
    umbrellasSent: 34,
    isModerator: false,
  ),
];

final _demoInbox = <InboxItem>[
  InboxItem(
    id: 'demo-inbox-1',
    kind: 'umbrella',
    umbrellaId: 'demo-umbrella-1',
    message: 'You are not alone in this. Thank you for saying it out loud.',
    storyExcerpt: 'I finally told a friend what has been weighing on me…',
    createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
  ),
  InboxItem(
    id: 'demo-inbox-2',
    kind: 'thanks',
    message: 'This really helped, thank you 🫂',
    storyExcerpt: '',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
];

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
