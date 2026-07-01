import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/models/transaction_model.dart';
import 'package:taftaf/core/providers/call_provider.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/router/app_router.dart';

// ── Public entry point used by the router ─────────────────────────────────────

class NotificationsOverlay extends ConsumerStatefulWidget {
  const NotificationsOverlay({super.key});

  @override
  ConsumerState<NotificationsOverlay> createState() =>
      _NotificationsOverlayState();
}

class _NotificationsOverlayState extends ConsumerState<NotificationsOverlay> {
  String? _expandedId;

  Future<void> _initiateCallBack(NotificationModel n) async {
    final calleeId = n.callerId!;
    final calleeName = n.callerName ?? 'Client';
    final owner = ref.read(authProvider).currentUser;
    if (owner == null) return;

    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required to make calls.')),
      );
      return;
    }

    context.pop();
    await ref.read(callProvider.notifier).startCall(
      callerId: owner.id,
      callerName: owner.username,
      calleeId: calleeId,
      calleeName: calleeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final unread = notifications.where((n) => !n.isRead).length;

    return Material(
      color: Colors.transparent,
      // Tap on the backdrop (outside the panel) dismisses the overlay.
      child: GestureDetector(
        onTap: () => context.pop(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: GestureDetector(
              // Absorb taps inside the panel so they don't bubble to the backdrop.
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.72,
                ),
                decoration: BoxDecoration(
                  color: context.bgColor.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.divColor.withValues(alpha: 0.7),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.50),
                      blurRadius: 56,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      blurRadius: 36,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PanelHeader(
                        unread: unread,
                        onMarkAll: unread > 0
                            ? () => ref
                                .read(notificationsProvider.notifier)
                                .markAllRead()
                            : null,
                        onClose: () => context.pop(),
                      ),
                      if (notifications.isEmpty)
                        const _EmptyState()
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.only(bottom: 14),
                            itemCount: notifications.length,
                            separatorBuilder: (_, i) => Divider(
                              height: 0,
                              color: context.divColor.withValues(alpha: 0.4),
                              indent: 66,
                              endIndent: 16,
                            ),
                            itemBuilder: (_, i) {
                              final n = notifications[i];
                              return _NotifRow(
                                notification: n,
                                isExpanded: _expandedId == n.id,
                                onTap: () {
                                  if (!n.isRead) {
                                    ref
                                        .read(notificationsProvider.notifier)
                                        .markRead(n.id);
                                  }
                                  setState(() {
                                    _expandedId =
                                        _expandedId == n.id ? null : n.id;
                                  });
                                },
                                onNavigate: n.propertyId != null
                                    ? () {
                                        context.pop();
                                        context.push(AppRoutes
                                            .propertyDetailPath(n.propertyId!));
                                      }
                                    : null,
                                onCallBack: n.type == NotificationType.missedCall &&
                                        n.callerId != null
                                    ? () => _initiateCallBack(n)
                                    : null,
                              ).animate().fadeIn(delay: (i * 45).ms);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 180.ms).slideY(begin: -0.04),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Panel header ──────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  final int unread;
  final VoidCallback? onMarkAll;
  final VoidCallback onClose;

  const _PanelHeader({
    required this.unread,
    this.onMarkAll,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.divColor.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Notifications',
            style: TextStyle(
              color: context.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (onMarkAll != null)
            TextButton(
              onPressed: onMarkAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Mark all read',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: context.textSecColor, size: 20),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 54,
            color: context.textSecColor.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            'No notifications',
            style: TextStyle(
              color: context.textColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "You're all caught up!",
            style: TextStyle(color: context.textMutedColor, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Individual notification row (expandable) ──────────────────────────────────

class _NotifRow extends StatelessWidget {
  final NotificationModel notification;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onNavigate;
  final VoidCallback? onCallBack;

  const _NotifRow({
    required this.notification,
    required this.isExpanded,
    required this.onTap,
    this.onNavigate,
    this.onCallBack,
  });

  // Returns the icon and accent colour for each notification type.
  (IconData, Color) get _style {
    switch (notification.type) {
      case NotificationType.welcome:
        return (Icons.celebration_rounded, const Color(0xFFE8A30B));
      case NotificationType.accountInfo:
        return (Icons.manage_accounts_rounded, const Color(0xFF2980B9));
      case NotificationType.bookingReceived:
        return (Icons.event_available_rounded, const Color(0xFF27AE60));
      case NotificationType.bookingConfirmed:
        return (Icons.check_circle_rounded, const Color(0xFF27AE60));
      case NotificationType.bookingCancelled:
        return (Icons.cancel_rounded, AppColors.error);
      case NotificationType.newMessage:
        return (Icons.chat_bubble_rounded, const Color(0xFF2980B9));
      case NotificationType.paymentSuccess:
        return (Icons.payments_rounded, const Color(0xFF27AE60));
      case NotificationType.propertyVerified:
        return (Icons.verified_rounded, AppColors.primary);
      case NotificationType.system:
        return (Icons.shield_rounded, AppColors.primary);
      case NotificationType.missedCall:
        return (Icons.phone_missed_rounded, AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _style;
    final isRead = notification.isRead;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isRead
            ? Colors.transparent
            : AppColors.primary.withValues(alpha: 0.05),
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isRead ? 0.09 : 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                // Title + preview / full body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                color: context.textColor,
                                fontWeight: isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(notification.createdAt),
                            style: TextStyle(
                              color: context.textMutedColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      if (!isExpanded) ...[
                        const SizedBox(height: 3),
                        Text(
                          notification.body,
                          style: TextStyle(
                            color: context.textSecColor,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Unread dot
                if (!isRead) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                // Expand chevron
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 1),
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: context.textMutedColor,
                    ),
                  ),
                ),
              ],
            ),
            // ── Expanded detail ───────────────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(left: 50, top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.body,
                            style: TextStyle(
                              color: context.textSecColor,
                              fontSize: 13,
                              height: 1.55,
                            ),
                          ),
                          if (onNavigate != null || onCallBack != null) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (onNavigate != null)
                                  _ActionChip(
                                    icon: Icons.open_in_new_rounded,
                                    label: 'View Property',
                                    color: AppColors.primary,
                                    onTap: onNavigate!,
                                  ),
                                if (onCallBack != null)
                                  _ActionChip(
                                    icon: Icons.phone_rounded,
                                    label: 'Call Back',
                                    color: AppColors.error,
                                    onTap: onCallBack!,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${t.day}/${t.month}/${t.year}';
  }
}

// ── Shared action chip ────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
