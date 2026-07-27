import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/umbrella_repository.dart';
import 'app_models.dart';

class AppController extends ChangeNotifier {
  AppController(this.repository);

  final UmbrellaRepository repository;

  StreamSubscription<AuthState>? _authSubscription;
  bool _ready = false;
  bool _guestMode = false;
  bool _loadingProfile = false;
  bool _passwordRecovery = false;
  UserProfile? _profile;
  AppThemeChoice _theme = appThemeChoices.first;

  bool get ready => _ready;
  bool get guestMode => _guestMode;
  bool get isLoggedIn => repository.currentUser != null;
  bool get isDemo => !repository.isLive;
  UserProfile? get profile => _profile;
  AppThemeChoice get theme => _theme;
  bool get passwordRecovery => _passwordRecovery;
  bool get needsOnboarding =>
      isLoggedIn && !_loadingProfile && (_profile?.onboarded != true);

  Future<void> start() async {
    if (repository.isLive) {
      _authSubscription = repository.authChanges.listen((state) async {
        if (state.event == AuthChangeEvent.passwordRecovery) {
          _passwordRecovery = true;
        }
        if (state.session?.user == null) {
          _profile = null;
          _guestMode = false;
          notifyListeners();
          return;
        }
        await refreshProfile();
      });
      if (isLoggedIn) await refreshProfile(notify: false);
    } else {
      _guestMode = true;
    }
    _ready = true;
    notifyListeners();
  }

  void browseAsGuest() {
    _guestMode = true;
    notifyListeners();
  }

  void leaveGuestMode() {
    if (isLoggedIn) return;
    _guestMode = false;
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    await repository.signIn(email: email, password: password);
    _guestMode = false;
    await refreshProfile();
  }

  Future<bool> signUp({required String email, required String password}) async {
    final response = await repository.signUp(email: email, password: password);
    if (response.session != null) {
      _guestMode = false;
      await refreshProfile();
      return true;
    }
    return false;
  }

  Future<void> resetPassword(String email) => repository.resetPassword(email);

  Future<void> finishPasswordRecovery(String password) async {
    await repository.updatePassword(password);
    _passwordRecovery = false;
    notifyListeners();
  }

  Future<void> refreshProfile({bool notify = true}) async {
    if (!isLoggedIn) {
      _profile = null;
      if (notify) notifyListeners();
      return;
    }
    _loadingProfile = true;
    if (notify) notifyListeners();
    try {
      _profile = await repository.fetchCurrentProfile();
      final profileAccent = _profile?.accentColor.toLowerCase();
      if (profileAccent != null) {
        _theme = appThemeChoices.firstWhere(
          (choice) =>
              _hex(choice.accent).toLowerCase() == profileAccent ||
              choice.key == profileAccent,
          orElse: () => _theme,
        );
      }
    } finally {
      _loadingProfile = false;
      if (notify) notifyListeners();
    }
  }

  Future<void> completeOnboarding({
    required String username,
    required String displayName,
    required String pronouns,
    required String statusWeather,
    required String aboutMe,
    required String avatarUrl,
    required List<String> tags,
  }) async {
    await repository.updateProfile({
      'username': username.trim().toLowerCase(),
      'display_name': displayName.trim(),
      'pronouns': pronouns.trim(),
      'status_weather': statusWeather.trim(),
      'about_me': aboutMe.trim(),
      'avatar_url': avatarUrl,
      'tags': tags,
      'accent_color': _hex(_theme.accent),
      'onboarded': true,
    });
    await refreshProfile();
  }

  Future<void> saveProfile(Map<String, dynamic> values) async {
    await repository.updateProfile(values);
    await refreshProfile();
  }

  Future<void> updatePreference(String key, bool value) async {
    await repository.updateProfile({key: value});
    if (_profile != null) {
      _profile = key == 'discoverable'
          ? _profile!.copyWith(discoverable: value)
          : _profile!.copyWith(notifyEmail: value);
      notifyListeners();
    }
  }

  Future<void> setTheme(AppThemeChoice choice) async {
    _theme = choice;
    notifyListeners();
    if (isLoggedIn) {
      try {
        await repository.updateProfile({'accent_color': _hex(choice.accent)});
        _profile = _profile?.copyWith(accentColor: _hex(choice.accent));
      } catch (_) {
        // The visual selection remains local if the profile cannot be updated.
      }
    }
  }

  Future<void> signOut() async {
    await repository.signOut();
    _profile = null;
    _guestMode = false;
    _passwordRecovery = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this context.');
    return scope!.notifier!;
  }
}

String _hex(Color color) {
  final value = color.toARGB32() & 0x00FFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
