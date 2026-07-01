import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/constants/app_strings.dart';
import 'package:taftaf/core/models/property_model.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/router/app_router.dart';
import 'package:taftaf/shared/widgets/custom_button.dart';

class ListingPaymentScreen extends ConsumerStatefulWidget {
  final PropertyModel property;
  const ListingPaymentScreen({super.key, required this.property});

  @override
  ConsumerState<ListingPaymentScreen> createState() => _ListingPaymentScreenState();
}

class _ListingPaymentScreenState extends ConsumerState<ListingPaymentScreen> {
  bool _addVerification = false;
  bool _isProcessing = false;

  static const int _baseFee = 100;
  static const int _verificationFee = 50;

  int get _totalFee => _baseFee + (_addVerification ? _verificationFee : 0);

  Future<void> _payAndPublish() async {
    // Navigate to M-Pesa screen; returns true when payment is confirmed.
    final paid = await context.push<bool>(
      AppRoutes.mpesaPayment,
      extra: {
        'amount': _totalFee,
        'description': _addVerification
            ? 'Property Listing + Verification Fee'
            : 'Property Listing Fee',
        'reference': 'TafTaf-Listing',
      },
    );
    if (paid != true || !mounted) return;
    setState(() => _isProcessing = true);
    final propertyToSave = widget.property.copyWith(isVerified: _addVerification);
    await ref.read(propertyProvider.notifier).addProperty(propertyToSave);
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_addVerification
            ? '🎉 Property published & verified!'
            : '🎉 Property published successfully!'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
    context.go(AppRoutes.ownerHome);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: context.divColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: context.primarySurfColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: const Icon(Icons.home_work_rounded, color: AppColors.primary, size: 36),
                  ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.listingFeeTitle,
                    style: TextStyle(color: context.textColor, fontSize: 22, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.listingFeeSubtitle,
                    style: TextStyle(color: context.textSecColor, fontSize: 13),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 180.ms),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Property Summary Card ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.divColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.primarySurfColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p.typeLabel,
                          style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.title,
                          style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(p.location,
                            style: TextStyle(color: context.textSecColor, fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.payments_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('${p.priceFormatted}${p.priceSuffix}',
                          style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.1),
            const SizedBox(height: 20),

            // ── Base Listing Fee ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [context.primarySurfColor, const Color(0xFF0F1E00)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Listing Fee', style: TextStyle(color: context.textSecColor, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('One-time fee per new listing', style: TextStyle(color: context.textMutedColor, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text('KES $_baseFee', style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),

            // ── Verification Add-On ───────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: _addVerification ? context.primarySurfColor : context.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _addVerification ? AppColors.primary : context.divColor,
                  width: _addVerification ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  // Toggle row
                  InkWell(
                    onTap: () => setState(() => _addVerification = !_addVerification),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _addVerification
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : context.cardColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified_rounded,
                              color: _addVerification ? AppColors.primary : context.textMutedColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Verify This Listing',
                                        style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.w700)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('+ KES 50',
                                          style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text('Boost trust & visibility with a verified badge',
                                    style: TextStyle(color: context.textSecColor, fontSize: 11)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _addVerification,
                            onChanged: (v) => setState(() => _addVerification = v),
                            activeThumbColor: AppColors.primary,
                            activeTrackColor: context.primarySurfColor,
                            inactiveThumbColor: context.textMutedColor,
                            inactiveTrackColor: context.cardColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Expanded benefits (only when toggled on)
                  if (_addVerification)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          Container(height: 0.5, color: context.divColor),
                          const SizedBox(height: 12),
                          ...[
                            (Icons.verified_rounded, 'Verified badge shown on your listing'),
                            (Icons.star_rounded, 'Featured in the "Featured Properties" section'),
                            (Icons.search_rounded, 'Priority placement in search results'),
                            (Icons.thumb_up_rounded, 'Increases client trust & enquiries'),
                          ].map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(e.$1, size: 15, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Text(e.$2, style: TextStyle(color: context.textSecColor, fontSize: 12)),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.1),
            const SizedBox(height: 20),

            // ── What's Included (base) ────────────────────────────────────
            Text(
              "WHAT'S INCLUDED",
              style: TextStyle(color: context.textColor, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ).animate().fadeIn(delay: 420.ms),
            const SizedBox(height: 12),
            ...[
              (Icons.visibility_rounded, 'Visible to all clients immediately'),
              (Icons.chat_bubble_rounded, 'Clients can message you directly'),
              (Icons.bar_chart_rounded, 'Tracked in your analytics dashboard'),
            ].asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: context.primarySurfColor, shape: BoxShape.circle),
                      child: Icon(e.value.$1, color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Text(e.value.$2, style: TextStyle(color: context.textSecColor, fontSize: 13)),
                  ],
                ).animate().fadeIn(delay: (440 + e.key * 50).ms).slideX(begin: 0.1),
              );
            }),
            const SizedBox(height: 24),

            // ── Total ─────────────────────────────────────────────────────
            Container(height: 0.5, color: context.divColor),
            const SizedBox(height: 14),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Due Today',
                        style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                    if (_addVerification)
                      Text('Listing KES 100 + Verification KES 50',
                          style: TextStyle(color: context.textMutedColor, fontSize: 11)),
                  ],
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    'KES $_totalFee',
                    key: ValueKey(_totalFee),
                    style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 580.ms),
            const SizedBox(height: 24),

            // ── Pay Button ────────────────────────────────────────────────
            PrimaryButton(
              label: _isProcessing
                  ? 'Publishing...'
                  : 'Pay KES $_totalFee via M-Pesa',
              isLoading: _isProcessing,
              onTap: _isProcessing ? null : _payAndPublish,
            ).animate().fadeIn(delay: 620.ms).slideY(begin: 0.2),
            const SizedBox(height: 14),
            Center(
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Text(
                  'Cancel — go back to edit',
                  style: TextStyle(
                    color: context.textSecColor,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: context.textSecColor,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 660.ms),
            const SizedBox(height: 20),

            // ── Note ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.divColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: context.textMutedColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.listingFeeNote,
                      style: TextStyle(color: context.textMutedColor, fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 700.ms),
          ],
        ),
      ),
    );
  }
}
