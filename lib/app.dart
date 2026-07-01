import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taftaf/core/models/booking_model.dart';
import 'package:taftaf/core/models/transaction_model.dart';
import 'package:taftaf/core/providers/call_provider.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/router/app_router.dart';
import 'package:taftaf/core/theme/app_theme.dart';
import 'package:taftaf/features/call/call_overlay.dart';
import 'package:uuid/uuid.dart';

class TafTafApp extends ConsumerStatefulWidget {
  const TafTafApp({super.key});

  @override
  ConsumerState<TafTafApp> createState() => _TafTafAppState();
}

class _TafTafAppState extends ConsumerState<TafTafApp> {
  Timer? _callPollTimer;

  @override
  void initState() {
    super.initState();
    // Poll SharedPreferences every 2 s for incoming call invites.
    // Works reliably on the same device (demo / testing).
    // Replace this with a cloud push signal (Firebase, Supabase, etc.)
    // to enable cross-device real-time delivery in production.
    // Both owners (client calls) and clients (owner callbacks) are polled.
    _callPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;
      final user = ref.read(authProvider).currentUser;
      if (user == null) return;

      final cs = ref.read(callProvider);
      if (cs.status != CallStatus.idle) return;

      final incoming = await CallNotifier.pollForIncoming(user.id);
      if (incoming != null && mounted) {
        ref.read(callProvider.notifier).notifyIncoming(incoming);
      }
    });
  }

  @override
  void dispose() {
    _callPollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = createRouter(ref);
    final themeMode = ref.watch(themeModeProvider);

    // ── New-booking notification ────────────────────────────────────────────
    ref.listen<List<BookingModel>>(bookingProvider, (prev, next) {
      if (prev == null || !mounted) return;
      final user = ref.read(authProvider).currentUser;
      if (user == null || !user.isOwner) return;

      final prevPendingIds = prev
          .where((b) => b.status == BookingStatus.pending)
          .map((b) => b.id)
          .toSet();

      final newPending = next.where(
        (b) => b.status == BookingStatus.pending && !prevPendingIds.contains(b.id),
      );

      for (final booking in newPending) {
        ref.read(notificationsProvider.notifier).add(NotificationModel(
          id: const Uuid().v4(),
          userId: user.id,
          title: 'New Booking Request',
          body:
              '${booking.clientName} has requested a ${booking.typeLabel.toLowerCase()} for ${booking.propertyTitle}.',
          propertyId: booking.propertyId,
          isRead: false,
          createdAt: DateTime.now(),
          type: NotificationType.bookingReceived,
        ));
      }
    });

    // ── Missed-call notification ───────────────────────────────────────────
    ref.listen<CallState>(callProvider, (prev, next) {
      if (prev == null || !mounted) return;
      if (prev.status == CallStatus.ringing && next.status == CallStatus.idle) {
        final call = prev.call;
        final user = ref.read(authProvider).currentUser;
        if (call != null && user != null) {
          ref.read(notificationsProvider.notifier).add(NotificationModel(
            id: const Uuid().v4(),
            userId: user.id,
            title: 'Missed Call',
            body: 'You missed a call from ${call.callerName}.',
            isRead: false,
            createdAt: DateTime.now(),
            type: NotificationType.missedCall,
            callerId: call.callerId,
            callerName: call.callerName,
          ));
        }
      }
    });

    return MaterialApp.router(
      title: 'TafTaf',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => Stack(
        children: [
          child ?? const SizedBox(),
          // Full-screen call overlay — only visible when a call is active
          const Positioned.fill(child: CallOverlay()),
        ],
      ),
    );
  }
}
