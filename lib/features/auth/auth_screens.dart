import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_controller.dart';
import '../../core/app_models.dart';
import '../../core/app_theme.dart';
import '../../data/umbrella_repository.dart';
import '../../widgets/app_components.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return _AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EntranceReveal(
            duration: const Duration(milliseconds: 380),
            slideFrom: const Offset(0, -0.018),
            scaleFrom: 0.995,
            child: const BrandMark(size: 54),
          ),
          const Spacer(),
          EntranceReveal(
            delay: const Duration(milliseconds: 55),
            duration: const Duration(milliseconds: 460),
            slideFrom: const Offset(0, 0.035),
            scaleFrom: 0.988,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.umbrella_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Come in from\nthe rain.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.8,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'A kind, anonymous space to share what’s really going on—and hold an umbrella for someone else.',
                  style: TextStyle(
                    color: Color(0xFFE8DFFD),
                    fontSize: 16,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          EntranceReveal(
            delay: const Duration(milliseconds: 135),
            duration: const Duration(milliseconds: 440),
            slideFrom: const Offset(0, 0.028),
            scaleFrom: 0.992,
            child: Column(
              children: [
                if (controller.isDemo)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.science_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Preview mode is active. Connect Supabase to use real accounts.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: PremiumButtonMotion(
                    enabled: !controller.isDemo,
                    child: FilledButton(
                      onPressed: controller.isDemo
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SignupScreen(),
                              ),
                            ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                      ),
                      child: const Text('Create an account'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: PremiumButtonMotion(
                    enabled: !controller.isDemo,
                    child: OutlinedButton(
                      onPressed: controller.isDemo
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const LoginScreen(),
                              ),
                            ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Text('Log in'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: PremiumButtonMotion(
                    child: TextButton(
                      onPressed: controller.browseAsGuest,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        controller.isDemo
                            ? 'Explore the full preview'
                            : 'Browse as a guest',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Peer support—not a substitute for professional or crisis help.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFCCBDEB), fontSize: 10.5),
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AppScope.of(
        context,
      ).signIn(email: _email.text.trim(), password: _password.text);
      if (!mounted) return;
      TextInput.finishAutofillContext();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      AppScope.of(context).reportRequestFailure(error);
      if (mounted) showAppMessage(context, friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _LightAuthScaffold(
      title: 'Welcome back',
      subtitle: 'Your stories and umbrellas are waiting.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (value) => value?.contains('@') == true
                  ? null
                  : 'Enter your email address.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) =>
                  value?.isNotEmpty == true ? null : 'Enter your password.',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: PremiumButtonMotion(
                enabled: !_busy,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CupertinoActivityIndicator(
                            color: Colors.white,
                            radius: 10,
                          ),
                        )
                      : const Text('Log in'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            PremiumButtonMotion(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                ),
                child: const Text('Forgot your password?'),
              ),
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('New here?'),
                PremiumButtonMotion(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const SignupScreen(),
                      ),
                    ),
                    child: const Text('Create an account'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _agree = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      showAppMessage(
        context,
        'Please confirm that you are 13 or older and agree to the Terms and Privacy Policy.',
        error: true,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final signedIn = await AppScope.of(
        context,
      ).signUp(email: _email.text.trim(), password: _password.text);
      if (!mounted) return;
      TextInput.finishAutofillContext(shouldSave: true);
      if (signedIn) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: Icon(
              Icons.mark_email_read_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Check your email'),
            content: const Text(
              'We sent you a confirmation link. Open it, then return here and log in. Check your junk folder if it takes a minute.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      AppScope.of(context).reportRequestFailure(error);
      if (mounted) showAppMessage(context, friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _LightAuthScaffold(
      title: 'Come in from the rain',
      subtitle:
          'Create an anonymous account. Your email is only for login and password recovery.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (value) => value?.contains('@') == true
                  ? null
                  : 'Enter a valid email address.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Password (8+ characters)',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => (value?.length ?? 0) >= 8
                  ? null
                  : 'Use at least eight characters.',
            ),
            const SizedBox(height: 15),
            CheckboxListTile(
              value: _agree,
              onChanged: (value) => setState(() => _agree = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'I’m 13 or older and agree to the Terms of Use, Privacy Policy, and Community Guidelines.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: PremiumButtonMotion(
                enabled: !_busy && _agree,
                child: FilledButton(
                  onPressed: _busy || !_agree ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CupertinoActivityIndicator(
                            color: Colors.white,
                            radius: 10,
                          ),
                        )
                      : const Text('Create account'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already a member?'),
                PremiumButtonMotion(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                    ),
                    child: const Text('Log in'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_email.text.contains('@')) {
      showAppMessage(context, 'Enter your email address.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await AppScope.of(context).resetPassword(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) showAppMessage(context, friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _LightAuthScaffold(
      title: 'Reset your password',
      subtitle: 'We’ll send a private recovery link to your email.',
      child: _sent
          ? const EmptyState(
              icon: Icons.mark_email_read_outlined,
              title: 'Recovery email sent',
              message:
                  'Open the link in your email to choose a new password. Check your junk folder too.',
            )
          : Column(
              children: [
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: PremiumButtonMotion(
                    enabled: !_busy,
                    child: FilledButton(
                      onPressed: _busy ? null : _send,
                      child: Text(_busy ? 'Sending…' : 'Send recovery link'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AppScope.of(context).finishPasswordRecovery(_password.text);
      if (mounted) {
        showAppMessage(context, 'Your password has been updated.');
      }
    } catch (error) {
      if (mounted) showAppMessage(context, friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _LightAuthScaffold(
      title: 'Choose a new password',
      subtitle: 'Make it at least eight characters and hard to guess.',
      canGoBack: false,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'New password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => (value?.length ?? 0) >= 8
                  ? null
                  : 'Use at least eight characters.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmation,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
              validator: (value) => value == _password.text
                  ? null
                  : 'The passwords do not match.',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: PremiumButtonMotion(
                enabled: !_busy,
                child: FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CupertinoActivityIndicator(
                            color: Colors.white,
                            radius: 10,
                          ),
                        )
                      : const Text('Save new password'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _pronouns = TextEditingController();
  final _status = TextEditingController();
  final _about = TextEditingController();
  final _tagInput = TextEditingController();
  final List<String> _tags = [];
  int _page = 0;
  String _avatar = 'emoji:☂️';
  bool _kindness = false;
  bool _busy = false;

  static const _avatars = ['☂️', '🌙', '🌱', '⭐', '🌈', '🫂', '🎧', '📚', '🎨'];

  @override
  void dispose() {
    _pageController.dispose();
    _username.dispose();
    _displayName.dispose();
    _pronouns.dispose();
    _status.dispose();
    _about.dispose();
    _tagInput.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 0 && !_validUsername(_username.text)) {
      showAppMessage(
        context,
        'Choose 3–24 lowercase letters, numbers, or underscores.',
        error: true,
      );
      return;
    }
    if (_page < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (!_kindness) {
      showAppMessage(
        context,
        'Please agree to meet the community with kindness.',
        error: true,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await AppScope.of(context).completeOnboarding(
        username: _username.text,
        displayName: _displayName.text,
        pronouns: _pronouns.text,
        statusWeather: _status.text,
        aboutMe: _about.text,
        avatarUrl: _avatar,
        tags: _tags,
      );
    } catch (error) {
      if (mounted) showAppMessage(context, friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addTag() {
    var tag = _tagInput.text.trim().replaceFirst('#', '').toLowerCase();
    if (tag.length > 20) tag = tag.substring(0, 20);
    if (tag.isNotEmpty && !_tags.contains(tag) && _tags.length < 8) {
      setState(() => _tags.add(tag));
    }
    _tagInput.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  const BrandMark(size: 38),
                  const Spacer(),
                  Text(
                    '${_page + 1} of 4',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (_page + 1) / 4,
                  minHeight: 6,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _OnboardingPage(
                    eyebrow: 'YOUR SAFE NAME',
                    title: 'Who should we call you?',
                    description:
                        'No real name needed. Pick an anonymous handle that feels like you.',
                    child: Column(
                      children: [
                        TextField(
                          controller: _username,
                          autocorrect: false,
                          maxLength: 24,
                          textCapitalization: TextCapitalization.none,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixText: '@',
                            hintText: 'softsteps',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _displayName,
                          maxLength: 30,
                          decoration: const InputDecoration(
                            labelText: 'Display name (optional)',
                            hintText: 'Soft Steps',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _OnboardingPage(
                    eyebrow: 'MAKE IT YOURS',
                    title: 'Choose your little corner.',
                    description:
                        'Pick an avatar and the color that makes Haven feel comfortable.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _avatars
                              .map(
                                (emoji) => ChoiceChip(
                                  label: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 23),
                                  ),
                                  selected: _avatar == 'emoji:$emoji',
                                  onSelected: (_) =>
                                      setState(() => _avatar = 'emoji:$emoji'),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Color theme',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: appThemeChoices
                              .map(
                                (choice) => GestureDetector(
                                  onTap: () =>
                                      AppScope.of(context).setTheme(choice),
                                  child: Semantics(
                                    button: true,
                                    label: choice.name,
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: choice.accent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              AppScope.of(context).theme.key ==
                                                  choice.key
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 4,
                                        ),
                                        boxShadow:
                                            AppScope.of(context).theme.key ==
                                                choice.key
                                            ? [
                                                BoxShadow(
                                                  color: choice.accent
                                                      .withValues(alpha: 0.35),
                                                  blurRadius: 10,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                  _OnboardingPage(
                    eyebrow: 'A LITTLE ABOUT YOU',
                    title: 'Share only what feels safe.',
                    description:
                        'Keep out real names, schools, locations, phone numbers, emails, and socials.',
                    child: Column(
                      children: [
                        TextField(
                          controller: _pronouns,
                          maxLength: 30,
                          decoration: const InputDecoration(
                            labelText: 'Pronouns (optional)',
                            hintText: 'they/them',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _status,
                          maxLength: 60,
                          decoration: const InputDecoration(
                            labelText: 'Today’s weather',
                            hintText: '🌤️ better than yesterday',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _about,
                          maxLength: 300,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'About me',
                            hintText: 'Music, rainy days, and trying my best.',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _tagInput,
                          maxLength: 20,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addTag(),
                          decoration: InputDecoration(
                            labelText: 'Interests',
                            hintText: 'music',
                            suffixIcon: IconButton(
                              onPressed: _addTag,
                              icon: const Icon(Icons.add_rounded),
                            ),
                          ),
                        ),
                        if (_tags.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: _tags
                                  .map(
                                    (tag) => InputChip(
                                      label: Text('#$tag'),
                                      onDeleted: () =>
                                          setState(() => _tags.remove(tag)),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _OnboardingPage(
                    eyebrow: 'OUR KINDNESS AGREEMENT',
                    title: 'We hold umbrellas here.',
                    description:
                        'Haven works when everyone protects the person behind the post.',
                    child: Column(
                      children: [
                        ...const [
                          _GuidelineRow(
                            icon: '🫂',
                            text: 'Respect every identity.',
                          ),
                          _GuidelineRow(
                            icon: '💬',
                            text: 'Criticize ideas, never people.',
                          ),
                          _GuidelineRow(
                            icon: '🔒',
                            text: 'Never reveal anyone’s real identity.',
                          ),
                          _GuidelineRow(
                            icon: '☂️',
                            text:
                                'Respond the way someone asked to be supported.',
                          ),
                        ],
                        CheckboxListTile(
                          value: _kindness,
                          onChanged: (value) =>
                              setState(() => _kindness = value ?? false),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text(
                            'I’ll protect this space and meet people with kindness.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (_page > 0)
                    PremiumButtonMotion(
                      child: OutlinedButton(
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_page > 0) const SizedBox(width: 10),
                  Expanded(
                    child: PremiumButtonMotion(
                      enabled: !_busy,
                      child: FilledButton(
                        onPressed: _busy ? null : _next,
                        child: Text(
                          _busy
                              ? 'Saving…'
                              : _page == 3
                              ? 'Enter Haven'
                              : 'Continue',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rainfall extends StatefulWidget {
  const _Rainfall({
    this.color = Colors.white,
    this.opacity = 0.16,
    this.dropCount = 22,
    this.dropLength = 15,
  });

  final Color color;
  final double opacity;
  final int dropCount;
  final double dropLength;

  @override
  State<_Rainfall> createState() => _RainfallState();
}

class _RainfallState extends State<_Rainfall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool? _lastReducedMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_lastReducedMotion == reduceMotion) return;
    _lastReducedMotion = reduceMotion;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RainPainter(
        animation: _controller,
        color: widget.color,
        opacity: widget.opacity,
        dropCount: widget.dropCount,
        dropLength: widget.dropLength,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter({
    required this.animation,
    required this.color,
    required this.opacity,
    required this.dropCount,
    required this.dropLength,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final double opacity;
  final int dropCount;
  final double dropLength;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final progress = animation.value;
    for (var index = 0; index < dropCount; index++) {
      final xRatio = ((index * 47) % 101) / 100;
      final startRatio = ((index * 71) % 113) / 100;
      final yRatio = ((startRatio + progress * 1.25) % 1.18) - 0.12;
      final start = Offset(xRatio * size.width, yRatio * size.height);
      canvas.drawLine(start, start + Offset(-2.5, dropLength), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => false;
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8858F3), Color(0xFF4B218F)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: _Rainfall(opacity: 0.15, dropCount: 26),
              ),
            ),
            const Positioned(
              right: -116,
              top: -124,
              child: IgnorePointer(
                child: SizedBox(
                  width: 330,
                  height: 330,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x30FFFFFF), Color(0x00FFFFFF)],
                        stops: [0, 0.72],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: -104,
              bottom: 36,
              child: IgnorePointer(
                child: SizedBox(
                  width: 252,
                  height: 252,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x0DFFFFFF),
                      border: Border.fromBorderSide(
                        BorderSide(color: Color(0x18FFFFFF), width: 1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 44,
                    ),
                    // The welcome layout uses a Spacer for its relaxed,
                    // full-screen composition. IntrinsicHeight keeps that
                    // composition on tall screens while allowing it to scroll
                    // instead of overflowing on short or narrow windows.
                    child: IntrinsicHeight(child: child),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LightAuthScaffold extends StatelessWidget {
  const _LightAuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.canGoBack = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool canGoBack;

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.maybeOf(context)?.highContrast ?? false;
    return SwipeBackScope(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: canGoBack,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: _Rainfall(
                  color: Theme.of(context).colorScheme.primary,
                  opacity: 0.08,
                  dropCount: 18,
                  dropLength: 12,
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EntranceReveal(
                      duration: const Duration(milliseconds: 350),
                      slideFrom: const Offset(0, -0.015),
                      scaleFrom: 0.996,
                      child: const BrandMark(size: 42),
                    ),
                    const SizedBox(height: 36),
                    EntranceReveal(
                      delay: const Duration(milliseconds: 45),
                      duration: const Duration(milliseconds: 400),
                      slideFrom: const Offset(0, 0.024),
                      scaleFrom: 0.995,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    EntranceReveal(
                      delay: const Duration(milliseconds: 105),
                      duration: const Duration(milliseconds: 440),
                      slideFrom: const Offset(0, 0.032),
                      scaleFrom: 0.988,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: highContrast
                                ? const [Color(0xFFFFFFFF), Color(0xFFF9F6FD)]
                                : [
                                    Colors.white.withValues(alpha: 0.9),
                                    Colors.white.withValues(alpha: 0.74),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: highContrast
                                ? AppTheme.border
                                : Colors.white.withValues(alpha: 0.78),
                            width: 0.9,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1241237B),
                              blurRadius: 26,
                              spreadRadius: -3,
                              offset: Offset(0, 11),
                            ),
                          ],
                        ),
                        child: child,
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
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

class _GuidelineRow extends StatelessWidget {
  const _GuidelineRow({required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.maybeOf(context)?.highContrast ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: highContrast
              ? const [Color(0xFFFFFFFF), Color(0xFFF9F6FD)]
              : [
                  Colors.white.withValues(alpha: 0.82),
                  Colors.white.withValues(alpha: 0.64),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highContrast
              ? AppTheme.border
              : Colors.white.withValues(alpha: 0.78),
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D41237B),
            blurRadius: 14,
            spreadRadius: -4,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 21)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

bool _validUsername(String value) {
  return RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(value.trim().toLowerCase());
}

Future<bool> requireMember(BuildContext context) async {
  final controller = AppScope.of(context);
  if (controller.isLoggedIn || controller.isDemo) return true;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(
        Icons.umbrella_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Come in from the rain'),
      content: const Text(
        'Create an anonymous account or log in to post, vote, hug, and open umbrellas. You can keep browsing without one.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep browsing'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(false);
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
            );
          },
          child: const Text('Log in'),
        ),
      ],
    ),
  );
  return result ?? false;
}
