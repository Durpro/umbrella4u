import 'package:flutter_test/flutter_test.dart';

import 'package:umbrella4u/core/app_models.dart';
import 'package:umbrella4u/data/umbrella_repository.dart';

void main() {
  test('ships with the Umbrella4U Supabase project configured', () {
    expect(AppConfig.isSupabaseConfigured, isTrue);
    expect(
      Uri.parse(AppConfig.supabaseUrl).host,
      'bavvgrqvwwcetebconfj.supabase.co',
    );
    expect(AppConfig.supabasePublishableKey, startsWith('sb_publishable_'));
  });

  test('maps boolean content warnings into a clear display label', () {
    expect(
      StoryItem.fromMap({'content_warning': false}).contentWarning,
      isEmpty,
    );
    expect(
      StoryItem.fromMap({'content_warning': true}).contentWarning,
      'Sensitive content',
    );
  });

  group('preview repository', () {
    late UmbrellaRepository repository;

    setUp(() => repository = UmbrellaRepository());

    test('supports feed categories and search', () async {
      final stories = await repository.fetchStories();
      final wins = await repository.fetchStories(category: 'wins');
      final search = await repository.search('school');

      expect(stories, isNotEmpty);
      expect(wins, isNotEmpty);
      expect(wins.every((story) => story.category == 'wins'), isTrue);
      expect(search.stories, isNotEmpty);
    });

    test('creates a story through the same composer contract', () async {
      final before = await repository.fetchStories();

      await repository.createStory(
        text: 'A small test win.',
        intent: 'similar',
        category: 'wins',
        anonymous: false,
        weather: 4,
        contentWarning: false,
        pollOptions: const ['Cheer', 'Celebrate'],
      );

      final after = await repository.fetchStories();
      expect(after, hasLength(before.length + 1));
      expect(after.first.text, 'A small test win.');
      expect(after.first.pollOptions, hasLength(2));
    });
  });
}
