
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
  );

  runApp(const UmbrellaApp());
}

final supabase = Supabase.instance.client;

class UmbrellaApp extends StatelessWidget {
  const UmbrellaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6D3CE7);

    return MaterialApp(
      title: 'Umbrella4U',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3EDFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: purple,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            color: Color(0xFF201A2D),
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.3,
          ),
          headlineMedium: TextStyle(
            color: Color(0xFF201A2D),
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
          titleLarge: TextStyle(
            color: Color(0xFF201A2D),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF625B70),
            fontSize: 16,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF756E80),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    HomePage(),
    InboxPage(),
    CreatePage(),
    SearchPage(),
    ProfilePage(),
  ];

  void _selectPage(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: PremiumBottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: _selectPage,
      ),
    );
  }
}

class PremiumBottomNavigation extends StatelessWidget {
  const PremiumBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFEDE9F4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F41237B),
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavigationItem(
              icon: Icons.umbrella_rounded,
              label: 'Home',
              selected: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),
            _NavigationItem(
              icon: Icons.mail_outline_rounded,
              selectedIcon: Icons.mail_rounded,
              label: 'Inbox',
              selected: selectedIndex == 1,
              badge: true,
              onTap: () => onSelected(1),
            ),
            _PostNavigationItem(
              selected: selectedIndex == 2,
              onTap: () => onSelected(2),
            ),
            _NavigationItem(
              icon: Icons.search_rounded,
              label: 'Search',
              selected: selectedIndex == 3,
              onTap: () => onSelected(3),
            ),
            _NavigationItem(
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: 'Profile',
              selected: selectedIndex == 4,
              onTap: () => onSelected(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedIcon,
    this.badge = false,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final bool badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6D3CE7);

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: selected ? 38 : 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFF0EAFE)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        selected ? (selectedIcon ?? icon) : icon,
                        size: 22,
                        color: selected ? purple : const Color(0xFF938B9F),
                      ),
                    ),
                    if (badge)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF5DA8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    color: selected ? purple : const Color(0xFF938B9F),
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostNavigationItem extends StatelessWidget {
  const _PostNavigationItem({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: 'Post',
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.06 : 1,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF8C5CFA), Color(0xFF5D2ED4)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4D6D3CE7),
                        blurRadius: 16,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Icon(
                    selected ? Icons.edit_rounded : Icons.add_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Post',
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF6D3CE7)
                      : const Color(0xFF938B9F),
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 16),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 122),
            sliver: SliverToBoxAdapter(child: child),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Umbrella4U',
      subtitle: 'Good afternoon, Maya — welcome back.',
      trailing: const _RoundIconButton(icon: Icons.notifications_none_rounded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C4CEC), Color(0xFF4D239F)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3D6031C9),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -15,
                  top: -28,
                  child: Icon(
                    Icons.umbrella_rounded,
                    color: Colors.white.withValues(alpha: 0.12),
                    size: 150,
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Pill(text: 'YOUR SPACE'),
                    SizedBox(height: 34),
                    Text(
                      'Everything that matters,\nunder one roof.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        height: 1.17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Stay close. Share simply.',
                      style: TextStyle(color: Color(0xFFDCCFFC), fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const _SectionHeader(title: 'Your circles', action: 'See all'),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _CircleCard(
                  icon: Icons.family_restroom_rounded,
                  title: 'Family',
                  detail: '12 updates',
                  color: Color(0xFFFFE8F2),
                  iconColor: Color(0xFFD64086),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _CircleCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Favorites',
                  detail: '8 new posts',
                  color: Color(0xFFEAE4FF),
                  iconColor: Color(0xFF6D3CE7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionHeader(title: 'Recent moment'),
          const SizedBox(height: 14),
          const _UpdateCard(),
        ],
      ),
    );
  }
}

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Inbox',
      subtitle: 'Three new moments are waiting.',
      trailing: const _RoundIconButton(icon: Icons.edit_note_rounded),
      child: Column(
        children: [
          const _SearchField(hint: 'Search conversations'),
          const SizedBox(height: 22),
          ...const [
            _MessageTile(
              initials: 'AM',
              name: 'Ava & Mom',
              message: 'The photos turned out beautifully!',
              time: '2m',
              unread: true,
              color: Color(0xFFE9DEFF),
            ),
            _MessageTile(
              initials: 'NL',
              name: 'Noah Lee',
              message: 'Let’s make it happen this weekend.',
              time: '1h',
              unread: true,
              color: Color(0xFFFFE2EF),
            ),
            _MessageTile(
              initials: 'JC',
              name: 'Jamie Chen',
              message: 'Sent a photo',
              time: '4h',
              unread: false,
              color: Color(0xFFDCF5F0),
            ),
            _MessageTile(
              initials: 'BK',
              name: 'Book club',
              message: 'Mina: I loved the ending.',
              time: 'Tue',
              unread: false,
              color: Color(0xFFFFEBCF),
            ),
          ],
        ],
      ),
    );
  }
}

class CreatePage extends StatelessWidget {
  const CreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Create',
      subtitle: 'Share something worth remembering.',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF241835),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFCAB6FF),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'What’s on your mind?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start with a photo, a thought, or a small moment.',
                  style: TextStyle(color: Color(0xFFBDB2C8), height: 1.5),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Start a post'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7E4CF0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Row(
            children: [
              Expanded(
                child: _CreateOption(
                  icon: Icons.photo_library_outlined,
                  title: 'Photo',
                  detail: 'Share a memory',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _CreateOption(
                  icon: Icons.text_fields_rounded,
                  title: 'Note',
                  detail: 'Write a thought',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _CreateOption(
                  icon: Icons.poll_outlined,
                  title: 'Question',
                  detail: 'Ask your circle',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _CreateOption(
                  icon: Icons.event_outlined,
                  title: 'Event',
                  detail: 'Make a plan',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Discover',
      subtitle: 'Find people, circles, and moments.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SearchField(
            hint: 'What are you looking for?',
            autofocus: false,
          ),
          const SizedBox(height: 28),
          const _SectionHeader(title: 'Popular right now'),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TopicChip(label: 'Slow Sundays', icon: '☕'),
              _TopicChip(label: 'Little wins', icon: '✨'),
              _TopicChip(label: 'Weekend plans', icon: '🌿'),
              _TopicChip(label: 'Photo walks', icon: '📷'),
              _TopicChip(label: 'Good reads', icon: '📚'),
            ],
          ),
          const SizedBox(height: 30),
          const _SectionHeader(title: 'Suggested people', action: 'See all'),
          const SizedBox(height: 14),
          ...const [
            _PersonTile(
              initials: 'AR',
              name: 'Amelia Rose',
              detail: '5 mutual connections',
              color: Color(0xFFE9DEFF),
            ),
            _PersonTile(
              initials: 'OS',
              name: 'Oliver Stone',
              detail: 'Photography · Vancouver',
              color: Color(0xFFDDF3EF),
            ),
            _PersonTile(
              initials: 'MP',
              name: 'Mia Park',
              detail: '3 mutual connections',
              color: Color(0xFFFFE5EF),
            ),
          ],
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Profile',
      subtitle: 'Your corner of Umbrella4U.',
      trailing: const _RoundIconButton(icon: Icons.settings_outlined),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFEDE9F4)),
            ),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFAA84FF), Color(0xFF6939DF)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'MM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Maya Morgan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text('@mayam', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    _ProfileStat(value: '48', label: 'Posts'),
                    _VerticalDivider(),
                    _ProfileStat(value: '286', label: 'Friends'),
                    _VerticalDivider(),
                    _ProfileStat(value: '12', label: 'Circles'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _ProfileMenuItem(
            icon: Icons.bookmark_border_rounded,
            title: 'Saved moments',
          ),
          const _ProfileMenuItem(
            icon: Icons.people_outline_rounded,
            title: 'Friends & circles',
          ),
          const _ProfileMenuItem(
            icon: Icons.lock_outline_rounded,
            title: 'Privacy',
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEDE9F4)),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: const Color(0xFF5E5569), size: 22),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFECE4FF),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              color: Color(0xFF6D3CE7),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE9F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2B2335),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(detail, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE9F4)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InitialAvatar(initials: 'NL', color: Color(0xFFE9DEFF), size: 45),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Noah shared a moment',
                  style: TextStyle(
                    color: Color(0xFF2B2335),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Golden hour by the water. A perfect way to end the day.',
                  style: TextStyle(
                    color: Color(0xFF756E80),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  '18 min ago',
                  style: TextStyle(
                    color: Color(0xFFA29BAA),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, this.autofocus = false});

  final String hint;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: autofocus,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9E97A7), fontSize: 14),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF756E80),
          size: 22,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 17),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFEDE9F4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF7D4BED), width: 1.5),
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.initials,
    required this.name,
    required this.message,
    required this.time,
    required this.unread,
    required this.color,
  });

  final String initials;
  final String name;
  final String message;
  final String time;
  final bool unread;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: unread ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                _InitialAvatar(initials: initials, color: color, size: 50),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: const Color(0xFF2B2335),
                          fontSize: 15,
                          fontWeight: unread
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unread
                              ? const Color(0xFF5F5769)
                              : const Color(0xFF8A8392),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFFA29BAA),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6D3CE7),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({
    required this.initials,
    required this.color,
    required this.size,
  });

  final String initials;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF4E376D),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CreateOption extends StatelessWidget {
  const _CreateOption({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFEDE9F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6D3CE7), size: 25),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2B2335),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF8A8392), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label, required this.icon});

  final String label;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFE9E4F0)),
      ),
      child: Text(
        '$icon  $label',
        style: const TextStyle(
          color: Color(0xFF4A4254),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.initials,
    required this.name,
    required this.detail,
    required this.color,
  });

  final String initials;
  final String name;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _InitialAvatar(initials: initials, color: color, size: 48),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF2B2335),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFF8A8392),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6D3CE7),
              side: const BorderSide(color: Color(0xFFD9CCFA)),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Follow'),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2B2335),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8A8392), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: const Color(0xFFEDE9F4));
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EDFD),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: const Color(0xFF6D3CE7), size: 20),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF3A3244),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFA29BAA),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
