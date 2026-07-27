import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_controller.dart';
import '../../core/app_theme.dart';
import '../create/create_page.dart';
import '../feed/home_page.dart';
import '../inbox/inbox_page.dart';
import '../profile/profile_screens.dart';
import '../search/search_page.dart';
import '../settings/settings_screens.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _homeKey = GlobalKey<HomePageState>();
  final _inboxKey = GlobalKey<InboxPageState>();
  final _createKey = GlobalKey<CreatePageState>();
  late final List<Widget?> _pages;
  late final AnimationController _tabTransitionController;
  late final Animation<double> _tabOpacity;
  late final Animation<Offset> _tabOffset;
  int _selectedIndex = 0;
  double _tabSwipeDistance = 0;

  @override
  void initState() {
    super.initState();
    _pages = List<Widget?>.filled(5, null);
    _pages[0] = _buildPage(0);
    _tabTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 190),
      value: 1,
    );
    final curve = CurvedAnimation(
      parent: _tabTransitionController,
      curve: Curves.easeOutCubic,
    );
    _tabOpacity = Tween<double>(begin: 0.88, end: 1).animate(curve);
    _tabOffset = Tween<Offset>(
      begin: const Offset(0, 0.008),
      end: Offset.zero,
    ).animate(curve);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabTransitionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _homeKey.currentState?.refresh();
    if (_selectedIndex == 1) _inboxKey.currentState?.refresh();
  }

  void _selectPage(int index) {
    if (_selectedIndex == index) {
      if (index == 0) _homeKey.currentState?.refresh();
      if (index == 1) _inboxKey.currentState?.refresh();
      return;
    }
    final page = _pages[index] ?? _buildPage(index);
    HapticFeedback.selectionClick();
    setState(() {
      _pages[index] = page;
      _selectedIndex = index;
    });
    _animateTabChange();
    if (index == 1) _inboxKey.currentState?.refresh();
  }

  Widget _buildPage(int index) {
    return switch (index) {
      0 => HomePage(
        key: _homeKey,
        onOpenNotifications: _showNotificationsPreview,
        onCreate: () => _selectPage(2),
        onOpenMenu: () => openMoreMenu(context),
      ),
      1 => InboxPage(key: _inboxKey),
      2 => CreatePage(key: _createKey, onPosted: _afterPosting),
      3 => const SearchPage(),
      4 => const ProfilePage(),
      _ => const SizedBox.shrink(),
    };
  }

  void _afterPosting() {
    _createKey.currentState?.resetDraft();
    _homeKey.currentState?.refresh();
    setState(() => _selectedIndex = 0);
    _animateTabChange();
  }

  void _showNotificationsPreview() {
    showNotificationsPreview(context, onViewAll: () => _selectPage(1));
  }

  void _trackTabSwipe(DragUpdateDetails details) {
    _tabSwipeDistance += details.primaryDelta ?? 0;
  }

  void _handleTabSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final distance = _tabSwipeDistance;
    _tabSwipeDistance = 0;
    if (velocity.abs() < 360 && distance.abs() < 80) return;
    final direction = velocity.abs() >= 360
        ? (velocity.isNegative ? 1 : -1)
        : (distance.isNegative ? 1 : -1);
    final destination = (_selectedIndex + direction).clamp(0, 4).toInt();
    if (destination != _selectedIndex) _selectPage(destination);
  }

  void _animateTabChange() {
    if (MediaQuery.maybeOf(context)?.disableAnimations == true) {
      _tabTransitionController.value = 1;
      return;
    }
    _tabTransitionController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: _trackTabSwipe,
        onHorizontalDragEnd: _handleTabSwipe,
        onHorizontalDragCancel: () => _tabSwipeDistance = 0,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE4D4EC),
                AppTheme.background,
                Color(0xFFEDE3F2),
              ],
            ),
          ),
          child: ScrollConfiguration(
            behavior: const CozyScrollBehavior(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: FadeTransition(
                  opacity: _tabOpacity,
                  child: SlideTransition(
                    position: _tabOffset,
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: List<Widget>.generate(
                        _pages.length,
                        (index) =>
                            _pages[index] ??
                            SizedBox.shrink(
                              key: ValueKey<String>('unmounted-tab-$index'),
                            ),
                        growable: false,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: PremiumBottomNavigation(
            selectedIndex: _selectedIndex,
            showInboxBadge: AppScope.of(context).isLoggedIn,
            onSelected: _selectPage,
          ),
        ),
      ),
    );
  }
}

class PremiumBottomNavigation extends StatelessWidget {
  const PremiumBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.showInboxBadge = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool showInboxBadge;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(31);
    final highContrast = MediaQuery.maybeOf(context)?.highContrast ?? false;
    final glassSurface = Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: highContrast
              ? const [Color(0xF23A2047), Color(0xF21E1029)]
              : const [Color(0xD94A2858), Color(0xE3261432)],
          stops: const [0, 1],
        ),
        borderRadius: borderRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: highContrast ? 0.3 : 0.17),
          width: 0.8,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: 0.76,
                child: Container(
                  height: 0.8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.36),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: Row(
              children: [
                _NavigationItem(
                  icon: Icons.umbrella_outlined,
                  selectedIcon: Icons.umbrella_rounded,
                  label: 'Home',
                  selected: selectedIndex == 0,
                  onTap: () => onSelected(0),
                ),
                _NavigationItem(
                  icon: Icons.mail_outline_rounded,
                  selectedIcon: Icons.mail_rounded,
                  label: 'Inbox',
                  selected: selectedIndex == 1,
                  badge: showInboxBadge,
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
        ],
      ),
    );
    final filteredSurface = kIsWeb
        ? glassSurface
        : BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: glassSurface,
          );

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 11),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x18311930),
          borderRadius: borderRadius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x40311930),
              blurRadius: 30,
              spreadRadius: -4,
              offset: Offset(0, 14),
            ),
            BoxShadow(
              color: Color(0x182B142C),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: borderRadius, child: filteredSurface),
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
    final primary = Theme.of(context).colorScheme.primary;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          key: ValueKey('nav-${label.toLowerCase()}'),
          onTap: onTap,
          overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSlide(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  offset: selected ? const Offset(0, -0.06) : Offset.zero,
                  child: AnimatedScale(
                    duration: duration,
                    curve: Curves.easeOutBack,
                    scale: selected ? 1.04 : 1,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: duration,
                          curve: Curves.easeOutCubic,
                          width: selected ? 42 : 34,
                          height: 33,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.navigationOn
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: selected
                                ? Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  )
                                : null,
                          ),
                          child: Icon(
                            selected ? (selectedIcon ?? icon) : icon,
                            size: 21,
                            color: selected
                                ? primary
                                : AppTheme.navigationMuted,
                          ),
                        ),
                        if (badge)
                          Positioned(
                            right: -1,
                            top: -2,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF082A4),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.navigationPlum,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    color: selected
                        ? AppTheme.navigationOn
                        : AppTheme.navigationMuted,
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    letterSpacing: selected ? -0.05 : 0,
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
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 230);
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: 'Post',
        child: InkWell(
          key: const ValueKey('nav-post'),
          onTap: onTap,
          overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
          customBorder: const CircleBorder(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSlide(
                duration: duration,
                curve: Curves.easeOutCubic,
                offset: selected ? const Offset(0, -0.05) : Offset.zero,
                child: AnimatedScale(
                  scale: selected ? 1.06 : 1,
                  duration: duration,
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    width: selected ? 52 : 49,
                    height: selected ? 52 : 49,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [scheme.primary, scheme.secondary],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.navigationOn,
                        width: 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.4),
                          blurRadius: selected ? 17 : 12,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Icon(
                      selected ? Icons.edit_rounded : Icons.add_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: duration,
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  color: selected
                      ? AppTheme.navigationOn
                      : AppTheme.navigationMuted,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
                child: const Text('Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
