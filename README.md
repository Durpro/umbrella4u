# Haven — Umbrella4U

The Flutter mobile app for [umbrella4u.ca](https://umbrella4u.ca). It keeps the
original five-button mobile layout and merges in the website's Haven community,
Supabase data, authentication, profiles, search, support inbox, and story tools.

## Run it

Install Flutter, open PowerShell in this folder, and run:

```powershell
flutter pub get
flutter run -d chrome
```

The app connects to Umbrella4U's Supabase project automatically. Its client-side
publishable key is intentionally safe to ship in a mobile or web app. Never put
the `service_role` key in Flutter.

To point a development build at a different Supabase project, create
`config/local.json`:

```json
{
  "SUPABASE_URL": "https://YOUR-PROJECT.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "YOUR-PUBLISHABLE-KEY"
}
```

Then run:

```powershell
flutter run -d chrome --dart-define-from-file=config/local.json
```

`config/local.json` is ignored by Git. Preview data is used only by automated
tests or when a repository is intentionally created without a Supabase client.

## Main app areas

- Home: community pulse, category filters, stories, polls, hugs, and umbrellas.
- Inbox: umbrellas and private support notes received on your stories.
- Post: weather, intent, category, anonymity, sensitive-content cover, and polls.
- Search: discoverable people, tags, topics, and community stories.
- Profile: public identity, stats, badges, stories, preferences, and themes.
- More: resources, community guidelines, tour, feedback, legal, and team pages.

## Supabase setup notes

Add these redirect URLs to **Authentication → URL Configuration**:

```text
ca.umbrella4u://login-callback/
ca.umbrella4u://reset-password/
```

The app intentionally relies on Row Level Security. Backend-only secrets,
moderation keys, admin operations, and service-role access must remain on a
trusted server or Supabase Edge Function.

## Checks

```powershell
dart format .
flutter analyze
flutter test
flutter build web --release
```

An iOS release must be built and signed on a Mac with Xcode and an Apple
Developer account.
