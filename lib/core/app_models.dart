import 'package:flutter/material.dart';

class CommunityCategory {
  const CommunityCategory({
    required this.key,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
  });

  final String key;
  final String name;
  final String description;
  final Color color;
  final IconData icon;
}

const communityCategories = <CommunityCategory>[
  CommunityCategory(
    key: 'identity',
    name: 'Identity',
    description: 'Who you are, gender, sexuality, and belonging',
    color: Color(0xFF8B6FC9),
    icon: Icons.fingerprint_rounded,
  ),
  CommunityCategory(
    key: 'school',
    name: 'School life',
    description: 'Classes, friends, pressure, and fitting in',
    color: Color(0xFF4A7FD6),
    icon: Icons.school_outlined,
  ),
  CommunityCategory(
    key: 'mind',
    name: 'Mental health',
    description: 'How you are really doing on the inside',
    color: Color(0xFF3F9D9D),
    icon: Icons.psychology_alt_outlined,
  ),
  CommunityCategory(
    key: 'culture',
    name: 'Culture',
    description: 'Heritage, language, being new, and belonging',
    color: Color(0xFFE0655E),
    icon: Icons.public_rounded,
  ),
  CommunityCategory(
    key: 'wins',
    name: 'Small wins',
    description: 'Little victories that deserve a cheer',
    color: Color(0xFF3F9D78),
    icon: Icons.auto_awesome_rounded,
  ),
  CommunityCategory(
    key: 'vent',
    name: 'Venting',
    description: 'Let it out—no fixing, just release',
    color: Color(0xFF8A8A86),
    icon: Icons.air_rounded,
  ),
];

CommunityCategory categoryFor(String key) {
  return communityCategories.firstWhere(
    (category) => category.key == key,
    orElse: () => communityCategories.first,
  );
}

class WeatherChoice {
  const WeatherChoice({
    required this.value,
    required this.emoji,
    required this.label,
  });

  final int value;
  final String emoji;
  final String label;
}

const weatherChoices = <WeatherChoice>[
  WeatherChoice(value: 0, emoji: '⛈️', label: 'Heavy rain'),
  WeatherChoice(value: 1, emoji: '🌧️', label: 'Rain'),
  WeatherChoice(value: 2, emoji: '☁️', label: 'Cloudy'),
  WeatherChoice(value: 3, emoji: '🌤️', label: 'Partly sunny'),
  WeatherChoice(value: 4, emoji: '☀️', label: 'Sunny'),
];

WeatherChoice weatherFor(int value) {
  return weatherChoices.firstWhere(
    (weather) => weather.value == value,
    orElse: () => weatherChoices[2],
  );
}

const responseIntents = <String, String>{
  'similar': 'Similar stories',
  'listen': 'Just listen',
  'advice': 'Give advice',
  'resources': 'Resources',
};

class AppThemeChoice {
  const AppThemeChoice({
    required this.key,
    required this.name,
    required this.accent,
    required this.deep,
    required this.note,
  });

  final String key;
  final String name;
  final Color accent;
  final Color deep;
  final String note;
}

const appThemeChoices = <AppThemeChoice>[
  AppThemeChoice(
    key: 'purple',
    name: 'Umbrella',
    accent: Color(0xFF76509A),
    deep: Color(0xFF24182F),
    note: 'Umbrella4U violet',
  ),
  AppThemeChoice(
    key: 'ink',
    name: 'Ink',
    accent: Color(0xFF3F6FA3),
    deep: Color(0xFF345F8C),
    note: 'Calm editorial blue',
  ),
  AppThemeChoice(
    key: 'rose',
    name: 'Rose',
    accent: Color(0xFFC8506A),
    deep: Color(0xFFA84158),
    note: 'Warm and gentle',
  ),
  AppThemeChoice(
    key: 'forest',
    name: 'Forest',
    accent: Color(0xFF3F9D78),
    deep: Color(0xFF327D60),
    note: 'Grounded green',
  ),
  AppThemeChoice(
    key: 'dusk',
    name: 'Dusk',
    accent: Color(0xFF8B6FC9),
    deep: Color(0xFF6F56A8),
    note: 'Soft twilight purple',
  ),
  AppThemeChoice(
    key: 'amber',
    name: 'Amber',
    accent: Color(0xFFE0894A),
    deep: Color(0xFFC26F2F),
    note: 'Warm sunset',
  ),
  AppThemeChoice(
    key: 'teal',
    name: 'Teal',
    accent: Color(0xFF3F9D9D),
    deep: Color(0xFF2F7D7D),
    note: 'Cool and clear',
  ),
];

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.pronouns,
    required this.statusWeather,
    required this.aboutMe,
    required this.accentColor,
    required this.avatarUrl,
    required this.bannerTheme,
    required this.tags,
    required this.discoverable,
    required this.notifyEmail,
    required this.onboarded,
    required this.postCount,
    required this.streakCount,
    required this.umbrellasSent,
    required this.isModerator,
    this.createdAt,
  });

  final String id;
  final String username;
  final String displayName;
  final String pronouns;
  final String statusWeather;
  final String aboutMe;
  final String accentColor;
  final String avatarUrl;
  final String bannerTheme;
  final List<String> tags;
  final bool discoverable;
  final bool notifyEmail;
  final bool onboarded;
  final int postCount;
  final int streakCount;
  final int umbrellasSent;
  final bool isModerator;
  final DateTime? createdAt;

  String get visibleName {
    if (displayName.trim().isNotEmpty) return displayName.trim();
    if (username.trim().isNotEmpty) return username.trim();
    return 'Umbrella member';
  }

  String get avatarText {
    if (avatarUrl.startsWith('emoji:')) return avatarUrl.substring(6);
    return visibleName.characters.first.toUpperCase();
  }

  Color get accent {
    final value = accentColor.replaceFirst('#', '');
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null
        ? const Color(0xFF75558F)
        : Color(0xFF000000 | parsed);
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: _asString(map['id']),
      username: _asString(map['username']),
      displayName: _asString(map['display_name']),
      pronouns: _asString(map['pronouns']),
      statusWeather: _asString(map['status_weather']),
      aboutMe: _asString(map['about_me']),
      accentColor: _asString(map['accent_color'], fallback: '#75558F'),
      avatarUrl: _asString(map['avatar_url']),
      bannerTheme: _asString(map['banner_theme'], fallback: 'rain'),
      tags: _asStringList(map['tags']),
      discoverable: _asBool(map['discoverable'], fallback: true),
      notifyEmail: _asBool(map['notify_email']),
      onboarded: _asBool(map['onboarded']),
      postCount: _asInt(map['post_count']),
      streakCount: _asInt(map['streak_count']),
      umbrellasSent: _asInt(map['umbrellas_sent']),
      isModerator: _asBool(map['is_moderator']),
      createdAt: _asDate(map['created_at']),
    );
  }

  UserProfile copyWith({
    String? username,
    String? displayName,
    String? pronouns,
    String? statusWeather,
    String? aboutMe,
    String? accentColor,
    String? avatarUrl,
    String? bannerTheme,
    List<String>? tags,
    bool? discoverable,
    bool? notifyEmail,
    bool? onboarded,
    int? postCount,
    int? streakCount,
    int? umbrellasSent,
    bool? isModerator,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      pronouns: pronouns ?? this.pronouns,
      statusWeather: statusWeather ?? this.statusWeather,
      aboutMe: aboutMe ?? this.aboutMe,
      accentColor: accentColor ?? this.accentColor,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerTheme: bannerTheme ?? this.bannerTheme,
      tags: tags ?? this.tags,
      discoverable: discoverable ?? this.discoverable,
      notifyEmail: notifyEmail ?? this.notifyEmail,
      onboarded: onboarded ?? this.onboarded,
      postCount: postCount ?? this.postCount,
      streakCount: streakCount ?? this.streakCount,
      umbrellasSent: umbrellasSent ?? this.umbrellasSent,
      isModerator: isModerator ?? this.isModerator,
      createdAt: createdAt,
    );
  }
}

class PollOption {
  const PollOption({
    required this.id,
    required this.storyId,
    required this.index,
    required this.label,
    required this.voteCount,
  });

  final String id;
  final String storyId;
  final int index;
  final String label;
  final int voteCount;

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      id: _asString(map['id']),
      storyId: _asString(map['story_id']),
      index: _asInt(map['idx']),
      label: _asString(map['label']),
      voteCount: _asInt(map['vote_count']),
    );
  }
}

class StoryItem {
  const StoryItem({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.anonymous,
    required this.text,
    required this.intent,
    required this.category,
    required this.contentWarning,
    required this.umbrellaCount,
    required this.hugCount,
    required this.viewCount,
    required this.weather,
    required this.createdAt,
    this.pollOptions = const [],
    this.myVoteOptionId,
    this.isMine = false,
    this.hasUmbrella = false,
    this.hasHug = false,
  });

  final String id;
  final String? authorId;
  final String authorName;
  final bool anonymous;
  final String text;
  final String intent;
  final String category;
  final String contentWarning;
  final int umbrellaCount;
  final int hugCount;
  final int viewCount;
  final int weather;
  final DateTime createdAt;
  final List<PollOption> pollOptions;
  final String? myVoteOptionId;
  final bool isMine;
  final bool hasUmbrella;
  final bool hasHug;

  factory StoryItem.fromMap(
    Map<String, dynamic> map, {
    List<PollOption> pollOptions = const [],
    String? myVoteOptionId,
    bool isMine = false,
    bool hasUmbrella = false,
    bool hasHug = false,
  }) {
    return StoryItem(
      id: _asString(map['id']),
      authorId: map['author_id'] == null ? null : _asString(map['author_id']),
      authorName: _asString(map['author_name'], fallback: 'Someone'),
      anonymous: _asBool(map['anonymous']),
      text: _asString(map['text']),
      intent: _asString(map['intent'], fallback: 'similar'),
      category: _asString(map['category'], fallback: 'identity'),
      contentWarning: _contentWarningText(map['content_warning']),
      umbrellaCount: _asInt(map['umbrella_count']),
      hugCount: _asInt(map['hug_count']),
      viewCount: _asInt(map['view_count']),
      weather: _asInt(map['weather'], fallback: 2),
      createdAt: _asDate(map['created_at']) ?? DateTime.now(),
      pollOptions: pollOptions,
      myVoteOptionId: myVoteOptionId,
      isMine: isMine,
      hasUmbrella: hasUmbrella,
      hasHug: hasHug,
    );
  }

  StoryItem copyWith({
    int? umbrellaCount,
    int? hugCount,
    List<PollOption>? pollOptions,
    String? myVoteOptionId,
    bool? isMine,
    bool? hasUmbrella,
    bool? hasHug,
  }) {
    return StoryItem(
      id: id,
      authorId: authorId,
      authorName: authorName,
      anonymous: anonymous,
      text: text,
      intent: intent,
      category: category,
      contentWarning: contentWarning,
      umbrellaCount: umbrellaCount ?? this.umbrellaCount,
      hugCount: hugCount ?? this.hugCount,
      viewCount: viewCount,
      weather: weather,
      createdAt: createdAt,
      pollOptions: pollOptions ?? this.pollOptions,
      myVoteOptionId: myVoteOptionId ?? this.myVoteOptionId,
      isMine: isMine ?? this.isMine,
      hasUmbrella: hasUmbrella ?? this.hasUmbrella,
      hasHug: hasHug ?? this.hasHug,
    );
  }
}

class InboxItem {
  const InboxItem({
    required this.id,
    required this.kind,
    required this.message,
    required this.storyExcerpt,
    required this.createdAt,
    this.umbrellaId,
    this.thanksSent,
  });

  final String id;
  final String kind;
  final String message;
  final String storyExcerpt;
  final DateTime createdAt;
  final String? umbrellaId;
  final String? thanksSent;

  bool get canThank => kind == 'umbrella' && message.isNotEmpty;
}

class SearchResults {
  const SearchResults({required this.people, required this.stories});

  final List<UserProfile> people;
  final List<StoryItem> stories;
}

class ProfileStats {
  const ProfileStats({
    required this.stories,
    required this.received,
    required this.sent,
    required this.streak,
  });

  final int stories;
  final int received;
  final int sent;
  final int streak;
}

class CommunityPulseData {
  const CommunityPulseData({
    required this.stories,
    required this.umbrellas,
    required this.sunny,
  });

  final int stories;
  final int umbrellas;
  final int sunny;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

String _contentWarningText(dynamic value) {
  if (value == null || value == false) return '';
  if (value is bool) return 'Sensitive content';

  final text = value.toString().trim().toLowerCase();
  if (text.isEmpty || text == 'false' || text == '0' || text == 'null') {
    return '';
  }
  return 'Sensitive content';
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value == null) return fallback;
  return value.toString().toLowerCase() == 'true';
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }
  return const [];
}
