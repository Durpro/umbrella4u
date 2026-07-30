import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../create/create_page.dart';
import '../feed/home_page.dart';
import '../inbox/inbox_page.dart';
import '../profile/profile_screens.dart';
import '../search/search_page.dart';
import '../settings/settings_screens.dart';
import '../../widgets/app_components.dart';

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
  late final List<Widget> _pages;
  late final PageController _pageController;
  late final ValueNotifier<double> _pagePosition;
  late final AnimationController _tapLiftController;
  late final Animation<double> _tapLift;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pages = List<Widget>.generate(5, _buildPage, growable: false);
    _pagePosition = ValueNotifier<double>(0);
    _pageController = PageController()..addListener(_trackPagePosition);
    _tapLiftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _tapLift = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: -6,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -6,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 58,
      ),
    ]).animate(_tapLiftController);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _pagePosition.dispose();
    _tapLiftController.dispose();
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
    HapticFeedback.selectionClick();
    _pageController.jumpToPage(index);
    if (MediaQuery.maybeOf(context)?.disableAnimations != true) {
      _tapLiftController.forward(from: 0);
    }
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
    _selectPage(0);
  }

  void _showNotificationsPreview() {
    showNotificationsPreview(context, onViewAll: () => _selectPage(1));
  }

  void _trackPagePosition() {
    final page = _pageController.page;
    if (page != null && (page - _pagePosition.value).abs() > 0.001) {
      _pagePosition.value = page;
    }
  }

  void _handlePageChanged(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
    if (index == 1) _inboxKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: ScrollConfiguration(
          behavior: const CozyScrollBehavior(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: AnimatedBuilder(
                animation: _tapLift,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _handlePageChanged,
                  physics: const PageScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  children: _pages,
                ),
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _tapLift.value),
                  child: child,
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
          child: ValueListenableBuilder<double>(
            valueListenable: _pagePosition,
            builder: (context, pagePosition, _) => PremiumBottomNavigation(
              selectedIndex: _selectedIndex,
              pagePosition: pagePosition,
              showInboxBadge: false,
              onSelected: _selectPage,
            ),
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
    required this.pagePosition,
    required this.onSelected,
    this.showInboxBadge = false,
  });

  final int selectedIndex;
  final double pagePosition;
  final ValueChanged<int> onSelected;
  final bool showInboxBadge;

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.maybeOf(context)?.highContrast ?? false;
    final scheme = Theme.of(context).colorScheme;
    final selectorPosition = pagePosition.clamp(0.0, 4.0).toDouble();
    final travelMorph =
        ((selectorPosition - selectorPosition.round()).abs() * 2)
            .clamp(0.0, 1.0)
            .toDouble();
    final postMorph = (1 - (selectorPosition - 2).abs())
        .clamp(0.0, 1.0)
        .toDouble();
    final barHeight = 71 + (5 * travelMorph);
    final borderRadius = BorderRadius.circular(27 + (3 * travelMorph));
    final selectorWidth = 42 + (4 * postMorph) + (7 * travelMorph);
    final selectorHeight = 29 + (12 * postMorph) + (3 * travelMorph);
    final selectorTop = 12 - (5 * postMorph) + (2 * travelMorph);
    final glassSurface = Container(
      height: barHeight,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: highContrast
              ? [
                  scheme.secondary,
                  Color.lerp(scheme.secondary, Colors.black, 0.56)!,
                ]
              : [
                  Color.lerp(scheme.secondary, scheme.primary, 0.2)!,
                  Color.lerp(scheme.secondary, Colors.black, 0.5)!,
                ],
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
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / 5;
                  final selectorLeft =
                      (itemWidth * (selectorPosition + 0.5)) -
                      (selectorWidth / 2);
                  return Stack(
                    children: [
                      Positioned(
                        left: selectorLeft,
                        top: selectorTop,
                        child: Container(
                          width: selectorWidth,
                          height: selectorHeight,
                          decoration: BoxDecoration(
                            color: AppTheme.navigationOn,
                            borderRadius: BorderRadius.circular(
                              14 + (85 * postMorph) + (10 * travelMorph),
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withValues(alpha: 0.26),
                                blurRadius: 18,
                                spreadRadius: -3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
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
        child: ClipRRect(borderRadius: borderRadius, child: glassSurface),
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
        child: PremiumButtonMotion(
          glowColor: primary,
          pressScale: 1.1,
          hoverScale: 1.06,
          child: InkWell(
            key: ValueKey('nav-${label.toLowerCase()}'),
            onTap: onTap,
            overlayColor: const WidgetStatePropertyAll<Color>(
              Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
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
                            width: 42,
                            height: 30,
                            decoration: const BoxDecoration(),
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
                  const SizedBox(height: 3),
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
        child: PremiumButtonMotion(
          glowColor: scheme.primary,
          pressScale: 1.1,
          hoverScale: 1.06,
          child: InkWell(
            key: const ValueKey('nav-post'),
            onTap: onTap,
            overlayColor: const WidgetStatePropertyAll<Color>(
              Colors.transparent,
            ),
            customBorder: const CircleBorder(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSlide(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  offset: selected ? const Offset(0, -0.05) : Offset.zero,
                  child: AnimatedScale(
                    scale: 1,
                    duration: duration,
                    curve: Curves.easeOutBack,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: AnimatedContainer(
                          duration: duration,
                          curve: Curves.easeOutCubic,
                          width: selected ? 40 : 42,
                          height: selected ? 40 : 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [scheme.primary, scheme.secondary],
                            ),
                            shape: BoxShape.circle,
                            border: selected
                                ? null
                                : Border.all(
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
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 1),
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
      ),
    );
  }
}
