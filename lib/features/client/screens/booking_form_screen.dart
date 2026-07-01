import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/models/booking_model.dart';
import 'package:taftaf/core/models/property_model.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/router/app_router.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  final PropertyModel property;
  const BookingFormScreen({super.key, required this.property});

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _msgCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  BookingType _type           = BookingType.viewing;
  DateTime?   _date;
  DateTime?   _checkIn;
  DateTime?   _checkOut;
  int         _contractMonths = 6;
  bool        _submitting     = false;

  bool get _isAirbnb => widget.property.type == PropertyType.airbnb;
  int  get _nights   => (_checkIn != null && _checkOut != null)
      ? _checkOut!.difference(_checkIn!).inDays
      : 0;
  double get _total  => widget.property.price.toDouble() * _nights;

  @override
  void initState() {
    super.initState();
    _type = _isAirbnb ? BookingType.rental : BookingType.viewing;
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickCheckIn() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkIn ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Check-in date',
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (picked == null) return;
    setState(() {
      _checkIn = picked;
      if (_checkOut != null && !_checkOut!.isAfter(_checkIn!)) {
        _checkOut = _checkIn!.add(const Duration(days: 1));
      }
    });
  }

  Future<void> _pickCheckOut() async {
    if (_checkIn == null) {
      _showSnack('Pick a check-in date first');
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOut ?? _checkIn!.add(const Duration(days: 1)),
      firstDate: _checkIn!.add(const Duration(days: 1)),
      lastDate: _checkIn!.add(const Duration(days: 90)),
      helpText: 'Check-out date',
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (picked != null) setState(() => _checkOut = picked);
  }

  Widget _datePickerTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: AppColors.black,
          surface: ctx.cardColor,
          onSurface: ctx.textColor,
        ),
      ),
      child: child!,
    );
  }

  bool get _canSubmit {
    if (_isAirbnb) return _checkIn != null && _checkOut != null && _nights > 0;
    return _date != null;
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      _showSnack(_isAirbnb ? 'Please select check-in and check-out dates' : 'Please select a date');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(clientBookingProvider.notifier).createBooking(
        property:       widget.property,
        type:           _type,
        scheduledDate:  _isAirbnb ? (_checkIn ?? DateTime.now()) : _date!,
        message:        _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
        checkIn:        _isAirbnb ? _checkIn : null,
        checkOut:       _isAirbnb ? _checkOut : null,
        contractMonths: (!_isAirbnb && _type == BookingType.rental) ? _contractMonths : null,
      );
      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      if (mounted) _showSnack('Failed to submit booking. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                'Booking Submitted!',
                style: TextStyle(color: context.textColor, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'Your request has been sent to ${widget.property.ownerName}. '
                'You\'ll be notified once they respond.',
                style: TextStyle(color: context.textSecColor, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // close dialog
                    context.go(AppRoutes.myBookings);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('View My Bookings', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pop();
                },
                child: Text('Back to Property', style: TextStyle(color: context.textSecColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    final fmt = DateFormat('EEE, d MMM yyyy');

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(
          _isAirbnb ? 'Book Stay' : 'Request Booking',
          style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700),
        ),
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Property card ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.divColor),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: p.images.isNotEmpty
                          ? Image.network(p.images.first, width: 72, height: 72, fit: BoxFit.cover,
                              errorBuilder: (ctx, e, s) => _imgPlaceholder())
                          : _imgPlaceholder(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title,
                              style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700, fontSize: 14),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Text(p.location,
                              style: TextStyle(color: context.textSecColor, fontSize: 11),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Text(
                            'KES ${NumberFormat('#,###').format(p.price)} / ${_isAirbnb ? 'night' : 'month'}',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 24),

              // ── Airbnb: date range ────────────────────────────────────────
              if (_isAirbnb) ...[
                _SectionLabel('Select Dates'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label: 'Check-in',
                        value: _checkIn != null ? fmt.format(_checkIn!) : null,
                        icon: Icons.flight_land_rounded,
                        onTap: _pickCheckIn,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DateButton(
                        label: 'Check-out',
                        value: _checkOut != null ? fmt.format(_checkOut!) : null,
                        icon: Icons.flight_takeoff_rounded,
                        onTap: _pickCheckOut,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 80.ms),
                if (_nights > 0) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.nights_stay_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_nights ${_nights == 1 ? 'night' : 'nights'}',
                                style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              Text(
                                '${fmt.format(_checkIn!)} → ${fmt.format(_checkOut!)}',
                                style: TextStyle(color: context.textSecColor, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'KES ${NumberFormat('#,###').format(_total.toInt())}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 120.ms),
                ],
              ],

              // ── Apartment: type + date ────────────────────────────────────
              if (!_isAirbnb) ...[
                _SectionLabel('Booking Type'),
                const SizedBox(height: 10),
                Row(
                  children: [BookingType.viewing, BookingType.rental].map((t) {
                    final sel = _type == t;
                    final label = switch (t) {
                      BookingType.viewing => 'Viewing',
                      BookingType.rental  => 'Rent',
                      _                   => '',
                    };
                    final icon = switch (t) {
                      BookingType.viewing => Icons.visibility_rounded,
                      BookingType.rental  => Icons.home_rounded,
                      _                   => Icons.circle,
                    };
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary.withValues(alpha: 0.12) : context.surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: sel ? AppColors.primary : context.divColor,
                              width: sel ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(icon, color: sel ? AppColors.primary : context.textMutedColor, size: 22),
                              const SizedBox(height: 5),
                              Text(
                                label,
                                style: TextStyle(
                                  color: sel ? AppColors.primary : context.textSecColor,
                                  fontSize: 11,
                                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ).animate().fadeIn(delay: 80.ms),
                const SizedBox(height: 20),
                _SectionLabel(_type == BookingType.rental ? 'Preferred Start Date' : 'Preferred Date'),
                const SizedBox(height: 10),
                _DateButton(
                  label: 'Select a date',
                  value: _date != null ? fmt.format(_date!) : null,
                  icon: Icons.calendar_today_rounded,
                  onTap: _pickDate,
                  fullWidth: true,
                ).animate().fadeIn(delay: 130.ms),

                // ── Rent-specific fields ──────────────────────────────────
                if (_type == BookingType.rental) ...[
                  const SizedBox(height: 20),
                  _SectionLabel('Monthly Rent'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.divColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'KES ${NumberFormat('#,###').format(p.price.toInt())} / month',
                          style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const Spacer(),
                        Text('As listed', style: TextStyle(color: context.textMutedColor, fontSize: 11)),
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 20),
                  _SectionLabel('Contract Duration'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [3, 6, 12, 24].map((m) {
                      final sel = _contractMonths == m;
                      final label = m == 12 ? '1 year' : m == 24 ? '2 years' : '$m months';
                      return GestureDetector(
                        onTap: () => setState(() => _contractMonths = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary.withValues(alpha: 0.12) : context.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel ? AppColors.primary : context.divColor,
                              width: sel ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: sel ? AppColors.primary : context.textSecColor,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ).animate().fadeIn(delay: 160.ms),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calculate_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Total for $_contractMonths ${_contractMonths == 1 ? 'month' : 'months'}',
                          style: TextStyle(color: context.textSecColor, fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          'KES ${NumberFormat('#,###').format((p.price * _contractMonths).toInt())}',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 170.ms),
                ],
              ],

              // ── Message ───────────────────────────────────────────────────
              const SizedBox(height: 20),
              _SectionLabel('Message (optional)'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _msgCtrl,
                maxLines: 3,
                style: TextStyle(color: context.textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: _isAirbnb
                      ? 'Any special requests or questions for the host?'
                      : 'Tell the owner about yourself or any specific requirements...',
                  hintStyle: TextStyle(color: context.textMutedColor, fontSize: 13),
                  filled: true,
                  fillColor: context.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.divColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.divColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ).animate().fadeIn(delay: 170.ms),

              // ── Price breakdown ───────────────────────────────────────────
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.divColor),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Property',
                      value: p.title,
                      bold: false,
                    ),
                    if (_isAirbnb) ...[
                      const Divider(height: 20),
                      _InfoRow(
                        label: 'KES ${NumberFormat('#,###').format(p.price)} × $_nights nights',
                        value: 'KES ${NumberFormat('#,###').format(_total.toInt())}',
                        bold: false,
                      ),
                      const Divider(height: 20),
                      _InfoRow(
                        label: 'Total',
                        value: 'KES ${NumberFormat('#,###').format(_total.toInt())}',
                        bold: true,
                      ),
                    ] else ...[
                      const Divider(height: 20),
                      _InfoRow(
                        label: 'Type',
                        value: _type == BookingType.viewing ? 'Property Viewing' : 'Rent Request',
                        bold: false,
                      ),
                      if (_date != null) ...[
                        const Divider(height: 20),
                        _InfoRow(
                          label: _type == BookingType.rental ? 'Start Date' : 'Preferred Date',
                          value: fmt.format(_date!),
                          bold: false,
                        ),
                      ],
                      if (_type == BookingType.rental) ...[
                        const Divider(height: 20),
                        _InfoRow(
                          label: 'Monthly Rent',
                          value: 'KES ${NumberFormat('#,###').format(p.price.toInt())}',
                          bold: false,
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          label: 'Contract',
                          value: '$_contractMonths ${_contractMonths == 1 ? 'month' : 'months'}',
                          bold: false,
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          label: 'Total Rent',
                          value: 'KES ${NumberFormat('#,###').format((p.price * _contractMonths).toInt())}',
                          bold: true,
                        ),
                      ],
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: context.bgColor,
          border: Border(top: BorderSide(color: context.divColor)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canSubmit ? AppColors.primary : context.divColor,
              foregroundColor: AppColors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.black),
                  )
                : Text(
                    _isAirbnb
                        ? (_nights > 0
                            ? 'Confirm Booking · KES ${NumberFormat('#,###').format(_total.toInt())}'
                            : 'Select Dates to Continue')
                        : 'Submit Request',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    width: 72, height: 72,
    color: context.divColor,
    child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 32),
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.w700),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final bool fullWidth;
  const _DateButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    Widget btn = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue ? AppColors.primary.withValues(alpha: 0.6) : context.divColor,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: hasValue ? AppColors.primary : context.textMutedColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: context.textMutedColor, fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                  if (hasValue) ...[
                    const SizedBox(height: 2),
                    Text(
                      value!,
                      style: TextStyle(color: context.textColor, fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _InfoRow({required this.label, required this.value, required this.bold});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: bold ? context.textColor : context.textSecColor,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              fontSize: bold ? 14 : 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            color: bold ? AppColors.primary : context.textColor,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            fontSize: bold ? 15 : 13,
          ),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
