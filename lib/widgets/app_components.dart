import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';

import '../core/app_models.dart';
import '../core/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 42, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.1),
          decoration: BoxDecoration(
            color: AppTheme.softSurface,
            borderRadius: BorderRadius.circular(size * 0.3),
            border: Border.all(color: AppTheme.border),
          ),
          child: Image.asset(
            'assets/images/umbrella_logo.png',
            semanticLabel: 'Umbrella4U logo',
          ),
        ),
        if (showName) ...[
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Haven',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: size * 0.48,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'BY UMBRELLA4U',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class EntranceReveal extends StatefulWidget {
  const EntranceReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.slideFrom = const Offset(0, 0.025),
    this.scaleFrom = 0.992,
    this.curve = Curves.easeOutCubic,
  }) : assert(duration > Duration.zero),
       assert(scaleFrom > 0 && scaleFrom <= 1);

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset slideFrom;
  final double scaleFrom;
  final Curve curve;

  @override
  State<EntranceReveal> createState() => _EntranceRevealState();
}

class _EntranceRevealState extends State<EntranceReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<Offset> _slide;
  Timer? _delayTimer;
  bool _started = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _configureAnimations();
  }

  void _configureAnimations() {
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _scale = Tween<double>(begin: widget.scaleFrom, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: widget.slideFrom,
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _reduceMotion = true;
      _delayTimer?.cancel();
      _controller.value = 1;
      _started = true;
      return;
    }
    if (!_started) _start();
  }

  @override
  void didUpdateWidget(covariant EntranceReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.curve != widget.curve ||
        oldWidget.slideFrom != widget.slideFrom ||
        oldWidget.scaleFrom != widget.scaleFrom) {
      _configureAnimations();
    }
  }

  void _start() {
    _started = true;
    if (widget.delay == Duration.zero) {
      _controller.forward();
      return;
    }
    _delayTimer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.tint,
    this.surfaceColor,
    this.opacity = 0.82,
    this.showShadow = true,
  }) : assert(opacity >= 0 && opacity <= 1);

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;
  final Color? tint;
  final Color? surfaceColor;
  final double opacity;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final accent = tint ?? Theme.of(context).colorScheme.primary;
    final base = (surfaceColor ?? AppTheme.surface).withValues(alpha: opacity);
    final highlight = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.18),
      base,
    );
    final tinted = Color.alphaBlend(accent.withValues(alpha: 0.035), base);
    final borderColor = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.36),
      AppTheme.border.withValues(alpha: 0.82),
    );

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [highlight, base, tinted],
          stops: const [0, 0.56, 1],
        ),
        borderRadius: borderRadius,
        border: Border.all(color: borderColor),
        boxShadow: showShadow
            ? const [
                BoxShadow(
                  color: Color(0x1823152B),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: Offset(0, 9),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Adds a familiar iOS-style left-edge gesture to pages that were pushed onto
/// the navigator. The interaction stays deliberately small so horizontal
/// lists, text selection, and the main tab swipe remain unaffected.
class SwipeBackScope extends StatefulWidget {
  const SwipeBackScope({super.key, required this.child});

  final Widget child;

  @override
  State<SwipeBackScope> createState() => _SwipeBackScopeState();
}

class _SwipeBackScopeState extends State<SwipeBackScope> {
  static const _edgeWidth = 28.0;
  static const _dismissDistance = 72.0;
  double _dragDistance = 0;

  void _updateDrag(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    if (delta == 0) return;
    setState(() {
      _dragDistance = (_dragDistance + delta).clamp(0, 110).toDouble();
    });
  }

  void _endDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldPop = _dragDistance >= _dismissDistance || velocity >= 420;
    setState(() => _dragDistance = 0);
    if (shouldPop) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    if (!Navigator.of(context).canPop()) return widget.child;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: _edgeWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: _updateDrag,
            onHorizontalDragEnd: _endDrag,
            onHorizontalDragCancel: () => setState(() => _dragDistance = 0),
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedOpacity(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 140),
                  opacity: _dragDistance == 0 ? 0 : 0.72,
                  child: Transform.translate(
                    offset: Offset((_dragDistance / 8) - 12, 0),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
    this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 122),
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SwipeBackScope(
      child: ScrollConfiguration(
        behavior: const CozyScrollBehavior(),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            key: PageStorageKey<String>('page-$title'),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: EntranceReveal(
                    duration: const Duration(milliseconds: 360),
                    slideFrom: const Offset(0, 0.018),
                    scaleFrom: 0.996,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
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
                          const SizedBox(width: 12),
                          trailing!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: padding,
                sliver: SliverToBoxAdapter(
                  child: EntranceReveal(
                    delay: const Duration(milliseconds: 65),
                    child: child,
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

class RoundIconButton extends StatefulWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool badge;

  @override
  State<RoundIconButton> createState() => _RoundIconButtonState();
}

class _RoundIconButtonState extends State<RoundIconButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final pressDuration = reduceMotion
        ? Duration.zero
        : Duration(milliseconds: _pressed ? 85 : 180);
    final radius = BorderRadius.circular(17);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Semantics(
          button: true,
          label: widget.tooltip,
          onTap: widget.onPressed,
          child: Tooltip(
            message: widget.tooltip,
            excludeFromSemantics: true,
            child: AnimatedScale(
              scale: reduceMotion ? 1 : (_pressed ? 0.94 : 1),
              duration: pressDuration,
              curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: _pressed ? 0.78 : 1,
                duration: pressDuration,
                curve: Curves.easeOut,
                child: GlassSurface(
                  borderRadius: radius,
                  tint: Theme.of(context).colorScheme.primary,
                  opacity: 0.76,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: radius,
                    child: InkWell(
                      onTap: widget.onPressed,
                      onHighlightChanged: _setPressed,
                      excludeFromSemantics: true,
                      borderRadius: radius,
                      overlayColor: const WidgetStatePropertyAll<Color>(
                        Colors.transparent,
                      ),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          widget.icon,
                          color: AppTheme.secondaryInk,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.badge)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFEF5DA8),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 27,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (action != null && actionLabel != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: action, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Couldn’t load this',
      message: message,
      action: onRetry,
      actionLabel: 'Try again',
    );
  }
}

class LoadingCards extends StatelessWidget {
  const LoadingCards({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (index) {
        return Container(
          height: index == 0 ? 156 : 132,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppTheme.softSurface,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonLine(widthFactor: index.isEven ? 0.38 : 0.46),
                        const SizedBox(height: 8),
                        const _SkeletonLine(widthFactor: 0.25, height: 7),
                      ],
                    ),
                  ),
                  if (index == 0) const PremiumActivityIndicator(radius: 9),
                ],
              ),
              const SizedBox(height: 18),
              const _SkeletonLine(widthFactor: 0.94),
              const SizedBox(height: 9),
              _SkeletonLine(widthFactor: index.isEven ? 0.72 : 0.84),
              if (index == 0) ...[
                const SizedBox(height: 9),
                const _SkeletonLine(widthFactor: 0.56),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor, this.height = 9});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.border.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.profile, this.size = 48});

  final UserProfile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile.avatarUrl;
    final isImage =
        imageUrl.startsWith('https://') || imageUrl.startsWith('http://');
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: profile.accent, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: isImage
          ? Image.network(
              imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _avatarText(),
            )
          : _avatarText(),
    );
  }

  Widget _avatarText() {
    return Text(
      profile.avatarText,
      style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.4,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class PremiumActivityIndicator extends StatelessWidget {
  const PremiumActivityIndicator({
    super.key,
    this.radius = 10,
    this.color,
    this.semanticLabel = 'Loading',
  });

  final double radius;
  final Color? color;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? Theme.of(context).colorScheme.primary;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: reduceMotion
            ? CupertinoActivityIndicator.partiallyRevealed(
                radius: radius,
                color: indicatorColor,
                progress: 0.65,
              )
            : CupertinoActivityIndicator(radius: radius, color: indicatorColor),
      ),
    );
  }
}

void showAppMessage(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

String relativeTime(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.isNegative || difference.inMinutes < 1) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m';
  if (difference.inHours < 24) return '${difference.inHours}h';
  if (difference.inDays < 7) return '${difference.inDays}d';
  final weeks = (difference.inDays / 7).floor();
  return '${weeks}w';
}
