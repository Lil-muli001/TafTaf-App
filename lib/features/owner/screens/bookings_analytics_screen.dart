import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/models/booking_model.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/shared/widgets/bottom_nav_bar.dart';

class BookingsAnalyticsScreen extends ConsumerStatefulWidget {
  const BookingsAnalyticsScreen({super.key});

  @override
  ConsumerState<BookingsAnalyticsScreen> createState() => _BookingsAnalyticsScreenState();
}

class _BookingsAnalyticsScreenState extends ConsumerState<BookingsAnalyticsScreen> {

  Future<void> _accept(BookingModel booking) async {
    await ref.read(bookingProvider.notifier).acceptBooking(booking.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking by ${booking.clientName} confirmed.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _reject(BookingModel booking) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reject Booking', style: TextStyle(color: ctx.textColor, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rejecting booking by ${booking.clientName} for "${booking.propertyTitle}".',
              style: TextStyle(color: ctx.textSecColor, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonCtrl,
              style: TextStyle(color: ctx.textColor, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                hintStyle: TextStyle(color: ctx.textMutedColor),
                filled: true,
                fillColor: ctx.bgColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ctx.divColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ctx.divColor)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: ctx.textSecColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(bookingProvider.notifier).rejectBooking(
        booking.id,
        reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking by ${booking.clientName} rejected.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    reasonCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookings   = ref.watch(bookingProvider);
    final properties = ref.watch(propertyProvider).properties;

    final total     = bookings.length;
    final pending   = bookings.where((b) => b.status == BookingStatus.pending).length;
    final confirmed = bookings.where((b) => b.status == BookingStatus.confirmed).length;
    final completed = bookings.where((b) => b.status == BookingStatus.completed).length;
    final cancelled = bookings.where((b) => b.status == BookingStatus.cancelled).length;

    final pendingList = bookings.where((b) => b.status == BookingStatus.pending).toList();

    // Bookings per property
    final perProp = <String, int>{};
    for (final p in properties) {
      perProp[p.id] = bookings.where((b) => b.propertyId == p.id).length;
    }
    final maxCount = perProp.values.fold(0, (a, b) => a > b ? a : b);

    // Booking type counts
    final viewings  = bookings.where((b) => b.type == BookingType.viewing).length;
    final inquiries = bookings.where((b) => b.type == BookingType.inquiry).length;
    final rentals   = bookings.where((b) => b.type == BookingType.rental).length;

    final recent = [...bookings]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('Booking Analytics', style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700)),
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (pending > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: Text(
                '$pending pending',
                style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: bookings.isEmpty
          ? _EmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Summary cards ─────────────────────────────────────────
                  Row(
                    children: [
                      _SummaryCard(label: 'Total', value: '$total', color: AppColors.primary, icon: Icons.calendar_month_rounded),
                      const SizedBox(width: 10),
                      _SummaryCard(label: 'Pending', value: '$pending', color: Colors.orange, icon: Icons.hourglass_top_rounded),
                    ],
                  ).animate().fadeIn().slideY(begin: 0.2),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _SummaryCard(label: 'Confirmed', value: '$confirmed', color: Colors.green, icon: Icons.check_circle_rounded),
                      const SizedBox(width: 10),
                      _SummaryCard(label: 'Completed', value: '$completed', color: Colors.blue, icon: Icons.verified_rounded),
                    ],
                  ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.2),

                  const SizedBox(height: 28),

                  // ── Pending actions ───────────────────────────────────────
                  if (pendingList.isNotEmpty) ...[
                    Row(
                      children: [
                        _SectionLabel('Pending Actions'),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${pendingList.length}',
                            style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...pendingList.asMap().entries.map((e) =>
                      _PendingBookingCard(
                        booking: e.value,
                        onAccept: () => _accept(e.value),
                        onReject: () => _reject(e.value),
                      ).animate(delay: (e.key * 40).ms).fadeIn().slideY(begin: 0.1),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Bookings by property ──────────────────────────────────
                  _SectionLabel('Bookings by Property'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.divColor),
                    ),
                    child: Column(
                      children: properties.map((p) {
                        final count = perProp[p.id] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 110,
                                child: Text(
                                  p.title,
                                  style: TextStyle(color: context.textSecColor, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: maxCount > 0 ? count / maxCount : 0,
                                    minHeight: 10,
                                    backgroundColor: context.divColor,
                                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 22,
                                child: Text(
                                  '$count',
                                  style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700, fontSize: 13),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 28),

                  // ── Booking type breakdown ────────────────────────────────
                  _SectionLabel('Type Breakdown'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _TypeChip(label: 'Viewings',  count: viewings,  color: AppColors.primary),
                      const SizedBox(width: 10),
                      _TypeChip(label: 'Inquiries', count: inquiries, color: Colors.orange),
                      const SizedBox(width: 10),
                      _TypeChip(label: 'Rent',      count: rentals,   color: Colors.blue),
                    ],
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 28),

                  // ── Status breakdown ──────────────────────────────────────
                  _SectionLabel('Status Overview'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _TypeChip(label: 'Pending',   count: pending,   color: Colors.orange),
                      const SizedBox(width: 10),
                      _TypeChip(label: 'Confirmed', count: confirmed, color: Colors.green),
                      const SizedBox(width: 10),
                      _TypeChip(label: 'Cancelled', count: cancelled, color: Colors.red),
                    ],
                  ).animate().fadeIn(delay: 240.ms),

                  const SizedBox(height: 28),

                  // ── Recent bookings ───────────────────────────────────────
                  _SectionLabel('Recent Bookings'),
                  const SizedBox(height: 12),
                  ...recent.map((b) => _BookingRow(booking: b))
                      .toList()
                      .animate(interval: 40.ms)
                      .fadeIn()
                      .slideX(begin: 0.05),

                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: const OwnerBottomNav(currentIndex: 1),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, color: context.textMutedColor, size: 56),
          const SizedBox(height: 16),
          Text('No bookings yet', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Bookings from interested clients will appear here.',
              style: TextStyle(color: context.textSecColor, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.divColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 22)),
                Text(label, style: TextStyle(color: context.textSecColor, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _TypeChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Pending booking card with Accept / Reject ─────────────────────────────────

class _PendingBookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const _PendingBookingCard({
    required this.booking,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          // header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 14),
                const SizedBox(width: 6),
                Text('Awaiting Response · ${booking.typeLabel}',
                    style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(fmt.format(booking.scheduledDate),
                    style: TextStyle(color: context.textMutedColor, fontSize: 11)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.clientName,
                              style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700, fontSize: 13)),
                          Text(booking.propertyTitle,
                              style: TextStyle(color: context.textSecColor, fontSize: 11),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                if (booking.isAirbnb && booking.checkIn != null && booking.checkOut != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${fmt.format(booking.checkIn!)} → ${fmt.format(booking.checkOut!)}  ·  ${booking.totalNights} nights',
                    style: TextStyle(color: context.textSecColor, fontSize: 11),
                  ),
                ],
                if (booking.type == BookingType.rental && booking.contractMonths != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Contract: ${booking.contractMonths} ${booking.contractMonths == 1 ? 'month' : 'months'}'
                    '${booking.pricePerNight != null ? '  ·  KES ${NumberFormat('#,###').format(booking.pricePerNight!.toInt())}/mo' : ''}',
                    style: TextStyle(color: context.textSecColor, fontSize: 11),
                  ),
                ],
                if (booking.message != null && booking.message!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '"${booking.message}"',
                    style: TextStyle(color: context.textMutedColor, fontSize: 11, fontStyle: FontStyle.italic),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded, size: 15),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(Icons.check_rounded, size: 15),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent booking row (expandable) ──────────────────────────────────────────

class _BookingRow extends StatefulWidget {
  final BookingModel booking;
  const _BookingRow({required this.booking});

  @override
  State<_BookingRow> createState() => _BookingRowState();
}

class _BookingRowState extends State<_BookingRow> {
  bool _expanded = false;

  Color _statusColor(BookingStatus s) => switch (s) {
    BookingStatus.pending   => Colors.orange,
    BookingStatus.confirmed => Colors.green,
    BookingStatus.cancelled => Colors.red,
    BookingStatus.completed => Colors.blue,
  };

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final color = _statusColor(b.status);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded ? color.withValues(alpha: 0.35) : context.divColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary row ─────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(Icons.person_outline_rounded, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.clientName,
                          style: TextStyle(color: context.textColor, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        '${b.propertyTitle} · ${b.typeLabel}',
                        style: TextStyle(color: context.textSecColor, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(b.statusLabel,
                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d MMM').format(b.scheduledDate),
                      style: TextStyle(color: context.textMutedColor, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: context.textMutedColor),
                ),
              ],
            ),
            // ── Expanded detail ──────────────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(height: 0, color: context.divColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 10),
                          _detailRow(context, Icons.event_rounded,
                              'Scheduled', DateFormat('EEE, d MMM y').format(b.scheduledDate)),
                          _detailRow(context, Icons.access_time_rounded,
                              'Booked on', DateFormat('d MMM y · HH:mm').format(b.createdAt)),
                          if (b.checkIn != null && b.checkOut != null) ...[
                            _detailRow(context, Icons.login_rounded,
                                'Check-in', DateFormat('EEE, d MMM y').format(b.checkIn!)),
                            _detailRow(context, Icons.logout_rounded,
                                'Check-out', DateFormat('EEE, d MMM y').format(b.checkOut!)),
                            if (b.totalNights > 0)
                              _detailRow(context, Icons.nights_stay_rounded,
                                  'Nights', '${b.totalNights}'),
                          ],
                          if (b.contractMonths != null)
                            _detailRow(context, Icons.calendar_today_rounded,
                                'Duration', '${b.contractMonths} month${b.contractMonths! > 1 ? 's' : ''}'),
                          if (b.pricePerNight != null)
                            _detailRow(context, Icons.payments_rounded,
                                'Price/night', 'KES ${NumberFormat('#,##0').format(b.pricePerNight)}'),
                          if (b.totalAmount > 0)
                            _detailRow(context, Icons.receipt_long_rounded,
                                'Total', 'KES ${NumberFormat('#,##0').format(b.totalAmount)}'),
                          if (b.message != null && b.message!.isNotEmpty)
                            _detailRow(context, Icons.chat_bubble_outline_rounded,
                                'Message', b.message!),
                          if (b.status == BookingStatus.cancelled &&
                              b.rejectionReason != null &&
                              b.rejectionReason!.isNotEmpty)
                            _detailRow(context, Icons.info_outline_rounded,
                                'Reason', b.rejectionReason!, valueColor: Colors.red),
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

  Widget _detailRow(BuildContext context, IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: context.textMutedColor),
          const SizedBox(width: 6),
          SizedBox(
            width: 72,
            child: Text(label,
                style: TextStyle(color: context.textMutedColor, fontSize: 11)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? context.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
