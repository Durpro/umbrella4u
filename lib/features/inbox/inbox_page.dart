import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../core/app_models.dart';
import '../../core/app_theme.dart';
import '../../data/umbrella_repository.dart';
import '../../widgets/app_components.dart';
import '../auth/auth_screens.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => InboxPageState();
}

class InboxPageState extends State<InboxPage>
    with AutomaticKeepAliveClientMixin {
  List<InboxItem> _items = const [];
  Object? _error;
  bool _loading = true;
  String? _busyId;

  static const _thanks = [
    'Thank you for sharing 💛',
    'Thank you for your advice 🙏',
    'This really helped, thank you 🫂',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
  }

  Future<void> refresh() async {
    final controller = AppScope.of(context);
    if (!controller.isLoggedIn && !controller.isDemo) {
      // There is nothing to fetch for a guest, but the header spinner still
      // has to stop or it runs forever behind the sign-in prompt.
      if (mounted && _loading) setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await controller.repository.fetchInbox();
      if (!mounted) return;
      controller.reportRequestSuccess();
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      controller.reportRequestFailure(error);
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  /// Keeps the pull-to-refresh header open for the same length of time as
  /// the refresh itself, so the completed gesture feels deliberate.
  Future<void> _refreshWithExtendedHold() async {
    final stopwatch = Stopwatch()..start();
    await refresh();
    await Future<void>.delayed(stopwatch.elapsed);
  }

  Future<void> _sendThanks(InboxItem item, String message) async {
    final umbrellaId = item.umbrellaId;
    if (umbrellaId == null || _busyId != null) return;
    setState(() => _busyId = item.id);
    try {
      await AppScope.of(context).repository.sendThanks(umbrellaId, message);
      final index = _items.indexWhere((candidate) => candidate.id == item.id);
      if (index >= 0) {
        final updated = InboxItem(
          id: item.id,
          kind: item.kind,
          message: item.message,
          storyExcerpt: item.storyExcerpt,
          createdAt: item.createdAt,
          umbrellaId: item.umbrellaId,
          thanksSent: message,
        );
        setState(() {
          _items = [..._items]..[index] = updated;
        });
      }
      if (mounted) showAppMessage(context, 'Your thank-you was sent.');
    } catch (error) {
      if (mounted) {
        AppScope.of(context).reportRequestFailure(error);
        showAppMessage(context, friendlyError(error), error: true);
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = AppScope.of(context);
    final authenticated = controller.isLoggedIn || controller.isDemo;
    return _InboxRefreshFrame(
      title: 'Inbox',
      subtitle: 'Umbrellas, kind words, and thank-yous.',
      onRefresh: _refreshWithExtendedHold,
      trailing: _loading
          ? CupertinoActivityIndicator(
              radius: 9,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      child: !authenticated
          ? EmptyState(
              icon: Icons.mark_email_unread_outlined,
              title: 'Your support stays private',
              message:
                  'Log in to see umbrellas opened on your stories and private thank-yous from people you helped.',
              action: () => requireMember(context),
              actionLabel: 'Log in or sign up',
            )
          : _error != null && _items.isEmpty
          ? ErrorState(message: friendlyError(_error!), onRetry: refresh)
          : _items.isEmpty
          ? const EmptyState(
              icon: Icons.umbrella_outlined,
              title: 'No support notes yet',
              message:
                  'When someone opens an umbrella on your story, you’ll see it here.',
            )
          : Column(
              children: [
                if (_error != null) ...[
                  _InboxRefreshNotice(
                    message: friendlyError(_error!),
                    onRetry: refresh,
                  ),
                  const SizedBox(height: 12),
                ],
                _InboxExplainer(count: _items.length),
                const SizedBox(height: 14),
                ..._items.asMap().entries.map(
                  (entry) => EntranceReveal(
                    key: ValueKey<String>('inbox-${entry.value.id}'),
                    delay: Duration(
                      milliseconds: (entry.key * 36).clamp(0, 180).toInt(),
                    ),
                    duration: const Duration(milliseconds: 360),
                    child: _InboxCard(
                      item: entry.value,
                      options: _thanks,
                      busy: _busyId == entry.value.id,
                      onThanks: (message) => _sendThanks(entry.value, message),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Opens the compact notification preview used by the bell on Home. It is a
/// standard draggable modal: swipe it down or tap the scrim to dismiss it.
Future<void> showNotificationsPreview(
  BuildContext context, {
  required VoidCallback onViewAll,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x33241132),
    builder: (sheetContext) => _NotificationsPreviewSheet(
      onViewAll: () {
        Navigator.of(sheetContext).pop();
        onViewAll();
      },
    ),
  );
}

class _NotificationsPreviewSheet extends StatefulWidget {
  const _NotificationsPreviewSheet({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  State<_NotificationsPreviewSheet> createState() =>
      _NotificationsPreviewSheetState();
}

class _NotificationsPreviewSheetState
    extends State<_NotificationsPreviewSheet> {
  List<InboxItem> _items = const [];
  Object? _error;
  bool _loading = true;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _load();
    }
  }

  Future<void> _load() async {
    final controller = AppScope.of(context);
    if (!controller.isLoggedIn && !controller.isDemo) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await controller.repository.fetchInbox();
      if (!mounted) return;
      controller.reportRequestSuccess();
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      controller.reportRequestFailure(error);
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewItems = _items.take(4).toList(growable: false);
    final accent = Theme.of(context).colorScheme.primary;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: GlassSurface(
          borderRadius: BorderRadius.circular(28),
          opacity: 1,
          tint: accent,
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.mutedInk.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications',
                              style: TextStyle(
                                color: AppTheme.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'A few recent moments from your Haven.',
                              style: TextStyle(
                                color: AppTheme.secondaryInk,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close notifications',
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const SizedBox(
                      height: 112,
                      child: Center(
                        child: PremiumActivityIndicator(
                          semanticLabel: 'Loading notifications',
                        ),
                      ),
                    )
                  else if (_error != null)
                    _NotificationPreviewMessage(
                      icon: Icons.cloud_off_outlined,
                      message: friendlyError(_error!),
                      actionLabel: 'Try again',
                      onAction: _load,
                    )
                  else if (previewItems.isEmpty)
                    _NotificationPreviewMessage(
                      icon: Icons.umbrella_outlined,
                      message: 'No new support moments just yet.',
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.34,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: previewItems.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 7),
                        itemBuilder: (context, index) =>
                            _NotificationPreviewTile(item: previewItems[index]),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: widget.onViewAll,
                    icon: const Icon(Icons.mail_outline_rounded, size: 18),
                    label: const Text('View all inbox'),
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

class _NotificationPreviewMessage extends StatelessWidget {
  const _NotificationPreviewMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _NotificationPreviewTile extends StatelessWidget {
  const _NotificationPreviewTile({required this.item});

  final InboxItem item;

  @override
  Widget build(BuildContext context) {
    final isThankYou = item.kind == 'thanks';
    final title = isThankYou
        ? 'Someone you helped said thanks'
        : item.message.isNotEmpty
        ? 'Someone left you a kind word'
        : 'Someone opened an umbrella';
    final symbol = isThankYou
        ? '💛'
        : item.message.isNotEmpty
        ? '💬'
        : '☂️';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.54)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(symbol, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      relativeTime(item.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (item.message.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.secondaryInk,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxRefreshFrame extends StatelessWidget {
  const _InboxRefreshFrame({
    required this.title,
    required this.subtitle,
    required this.onRefresh,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Future<void> Function() onRefresh;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: const PageStorageKey<String>('page-Inbox'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
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
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 122),
            sliver: SliverToBoxAdapter(
              child: EntranceReveal(
                delay: const Duration(milliseconds: 65),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxRefreshNotice extends StatelessWidget {
  const _InboxRefreshNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 9, 7, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1CFD5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: Color(0xFFB44359),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF7B3947), fontSize: 11),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _InboxExplainer extends StatelessWidget {
  const _InboxExplainer({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.13),
            AppTheme.surface.withValues(alpha: 0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.umbrella_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count moments of support',
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'This is not direct messaging. Replies stay short, intentional, and connected to an umbrella.',
                  style: TextStyle(
                    color: AppTheme.secondaryInk,
                    fontSize: 11,
                    height: 1.35,
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

class _InboxCard extends StatelessWidget {
  const _InboxCard({
    required this.item,
    required this.options,
    required this.busy,
    required this.onThanks,
  });

  final InboxItem item;
  final List<String> options;
  final bool busy;
  final ValueChanged<String> onThanks;

  @override
  Widget build(BuildContext context) {
    final isThankYou = item.kind == 'thanks';
    final recent = DateTime.now().difference(item.createdAt).inHours < 24;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: recent
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.58),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isThankYou
                  ? const Color(0xFFFFECF3)
                  : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.11),
              shape: BoxShape.circle,
            ),
            child: Text(
              isThankYou
                  ? '💛'
                  : item.message.isNotEmpty
                  ? '💬'
                  : '☂️',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isThankYou
                            ? 'Someone you helped said thanks'
                            : item.message.isNotEmpty
                            ? 'Someone left you a kind word'
                            : 'Someone opened an umbrella',
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      relativeTime(item.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (item.message.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '“${item.message}”',
                    style: const TextStyle(
                      color: AppTheme.secondaryInk,
                      fontSize: 13,
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (item.storyExcerpt.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    'On “${item.storyExcerpt}”',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.mutedInk,
                      fontSize: 10.5,
                      height: 1.35,
                    ),
                  ),
                ],
                if (item.canThank) ...[
                  const SizedBox(height: 12),
                  if (item.thanksSent != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F7F0),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Sent · ${item.thanksSent}',
                        style: const TextStyle(
                          color: Color(0xFF2F7A58),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: options
                          .map(
                            (message) => ActionChip(
                              onPressed: busy ? null : () => onThanks(message),
                              avatar: busy
                                  ? const SizedBox(
                                      width: 13,
                                      height: 13,
                                      child: CupertinoActivityIndicator(
                                        radius: 6,
                                      ),
                                    )
                                  : null,
                              label: Text(
                                message,
                                style: const TextStyle(fontSize: 10.5),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
