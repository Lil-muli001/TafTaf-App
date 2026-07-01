import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taftaf/core/router/app_router.dart';
import 'package:intl/intl.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/models/booking_model.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/shared/widgets/bottom_nav_bar.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientBookingProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await ref.read(clientBookingProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _refreshing = false);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
          const SnackBar(
            content: Text('Bookings refreshed'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
  }

  Future<void> _cancel(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel Booking', style: TextStyle(color: ctx.textColor, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to cancel your ${booking.typeLabel.toLowerCase()} '
          'for "${booking.propertyTitle}"?',
          style: TextStyle(color: ctx.textSecColor, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep', style: TextStyle(color: ctx.textSecColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(clientBookingProvider.notifier).cancelBooking(booking.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(clientBookingProvider);
    final active   = bookings.where((b) => b.status == BookingStatus.pending || b.status == BookingStatus.confirmed).toList();
    final past     = bookings.where((b) => b.status == BookingStatus.completed || b.status == BookingStatus.cancelled).toList();

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('My Bookings', style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700)),
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.clientHome),
        ),
        actions: [
          IconButton(
            icon: _refreshing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _refreshing ? null : _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.textMutedColor,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'All (${bookings.length})'),
            Tab(text: 'Active (${active.length})'),
            Tab(text: 'Past (${past.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _BookingList(bookings: bookings, onCancel: _cancel, onRefresh: _refresh),
          _BookingList(bookings: active,   onCancel: _cancel, onRefresh: _refresh),
          _BookingList(bookings: past,     onCancel: _cancel, onRefresh: _refresh),
        ],
      ),
      bottomNavigationBar: const ClientBottomNav(currentIndex: 2),
    );
  }
}

// ── Booking list ───────────────────────────────────────────────────────────────

class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final Future<void> Function(BookingModel) onCancel;
  final Future<void> Function() onRefresh;
  const _BookingList({required this.bookings, required this.onCancel, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, color: context.textMutedColor, size: 52),
            const SizedBox(height: 16),
            Text('No bookings here', style: TextStyle(color: context.textColor, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Browse properties to make a booking.',
                style: TextStyle(color: context.textSecColor, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: bookings.length,
        itemBuilder: (ctx, i) => _BookingCard(
          booking: bookings[i],
          onCancel: onCancel,
        ).animate(delay: (i * 40).ms).fadeIn().slideY(begin: 0.1),
      ),
    );
  }
}

// ── Single booking card ────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final Future<void> Function(BookingModel) onCancel;
  const _BookingCard({required this.booking, required this.onCancel});

  Color _statusColor(BookingStatus s) => switch (s) {
    BookingStatus.pending   => Colors.orange,
    BookingStatus.confirmed => Colors.green,
    BookingStatus.cancelled => Colors.red,
    BookingStatus.completed => Colors.blue,
  };

  IconData _statusIcon(BookingStatus s) => switch (s) {
    BookingStatus.pending   => Icons.hourglass_top_rounded,
    BookingStatus.confirmed => Icons.check_circle_rounded,
    BookingStatus.cancelled => Icons.cancel_rounded,
    BookingStatus.completed => Icons.verified_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(booking.status);
    final fmt   = DateFormat('EEE, d MMM yyyy');
    final canCancel = booking.status == BookingStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.divColor),
      ),
      child: Column(
        children: [
          // ── Header bar with status ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(booking.status), color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  booking.statusLabel,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  booking.typeLabel,
                  style: TextStyle(color: context.textMutedColor, fontSize: 11),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.propertyTitle,
                  style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700, fontSize: 15),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Dates
                if (booking.isAirbnb && booking.checkIn != null && booking.checkOut != null) ...[
                  _DateRow(
                    icon: Icons.flight_land_rounded,
                    label: 'Check-in',
                    value: fmt.format(booking.checkIn!),
                  ),
                  const SizedBox(height: 4),
                  _DateRow(
                    icon: Icons.flight_takeoff_rounded,
                    label: 'Check-out',
                    value: fmt.format(booking.checkOut!),
                  ),
                  const SizedBox(height: 4),
                  _DateRow(
                    icon: Icons.nights_stay_rounded,
                    label: 'Duration',
                    value: '${booking.totalNights} ${booking.totalNights == 1 ? 'night' : 'nights'}'
                        '  ·  KES ${NumberFormat('#,###').format(booking.totalAmount.toInt())}',
                  ),
                ] else ...[
                  _DateRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: fmt.format(booking.scheduledDate),
                  ),
                ],

                if (booking.type == BookingType.rental && booking.contractMonths != null) ...[
                  const SizedBox(height: 4),
                  _DateRow(
                    icon: Icons.description_rounded,
                    label: 'Contract',
                    value: '${booking.contractMonths} ${booking.contractMonths == 1 ? 'month' : 'months'}'
                        '  ·  KES ${NumberFormat('#,###').format((booking.pricePerNight ?? 0).toInt())} / mo',
                  ),
                ],

                if (booking.message != null && booking.message!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.format_quote_rounded, color: context.textMutedColor, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            booking.message!,
                            style: TextStyle(color: context.textSecColor, fontSize: 12, fontStyle: FontStyle.italic),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Rejection reason
                if (booking.rejectionReason != null && booking.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Colors.red, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Reason: ${booking.rejectionReason}',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Actions
                if (canCancel) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => onCancel(booking),
                      icon: const Icon(Icons.close_rounded, size: 15),
                      label: const Text('Cancel Booking'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
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

class _DateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DateRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: context.textMutedColor),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(color: context.textMutedColor, fontSize: 12)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: context.textSecColor, fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
