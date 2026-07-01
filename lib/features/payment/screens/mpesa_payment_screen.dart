import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/services/mpesa_service.dart';

const _kGreen = Color(0xFF39B54A); // Safaricom / M-Pesa brand green (from SVG)

enum _Phase { input, waiting, success, failed }

// ── Public screen ─────────────────────────────────────────────────────────────

class MpesaPaymentScreen extends StatefulWidget {
  final int amount;
  final String description;
  final String accountReference;

  const MpesaPaymentScreen({
    super.key,
    required this.amount,
    required this.description,
    required this.accountReference,
  });

  @override
  State<MpesaPaymentScreen> createState() => _MpesaPaymentScreenState();
}

class _MpesaPaymentScreenState extends State<MpesaPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController(text: '07');
  final _mpesa = MpesaService();

  _Phase _phase = _Phase.input;
  String? _errorMsg;
  String? _checkoutId;
  Timer? _pollTimer;
  int _pollCount = 0;
  int _unknownCount = 0;
  // 12 polls × 15 s = 180 s (3 min total wait).
  static const _maxPolls = 12;
  static const _pollInterval = Duration(seconds: 15);

  @override
  void dispose() {
    _pollTimer?.cancel();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your M-Pesa number';
    final formatted = _mpesa.formatPhone(v.replaceAll(RegExp(r'[\s\-+()]'), ''));
    if (formatted.length != 12) {
      return 'Enter a valid Kenyan number (e.g. 0712 345 678)';
    }
    return null;
  }

  Future<void> _sendStkPush() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _Phase.waiting;
      _errorMsg = null;
      _pollCount = 0;
      _unknownCount = 0;
    });

    final result = await _mpesa.initiateStkPush(
      phoneNumber: _phoneCtrl.text,
      amount: widget.amount,
      accountReference: widget.accountReference,
      transactionDescription: widget.description,
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _phase = _Phase.failed;
        _errorMsg = result.errorMessage;
      });
      return;
    }

    _checkoutId = result.checkoutRequestId;
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (!mounted) {
        _pollTimer?.cancel();
        return;
      }
      final id = _checkoutId;
      if (id == null) return;
      final status = await _mpesa.queryStatus(id);
      if (!mounted) return;

      switch (status) {
        case TransactionStatus.success:
          _pollTimer?.cancel();
          HapticFeedback.heavyImpact();
          setState(() => _phase = _Phase.success);
          await Future.delayed(const Duration(milliseconds: 1800));
          if (mounted) context.pop(true);

        case TransactionStatus.cancelled:
          _pollTimer?.cancel();
          setState(() {
            _phase = _Phase.failed;
            _errorMsg = 'You cancelled the M-Pesa request. Tap Try Again to retry.';
          });

        case TransactionStatus.insufficientBalance:
          _pollTimer?.cancel();
          setState(() {
            _phase = _Phase.failed;
            _errorMsg = 'Insufficient M-Pesa balance. Top up and try again.';
          });

        case TransactionStatus.failed:
          _pollTimer?.cancel();
          setState(() {
            _phase = _Phase.failed;
            _errorMsg = 'Payment failed. Please try again.';
          });

        case TransactionStatus.unknown:
          // Network/auth hiccup — don't count toward the poll limit.
          // Allow up to 12 consecutive failures (~60 s) before giving up.
          _unknownCount++;
          if (_unknownCount > 12) {
            _pollTimer?.cancel();
            setState(() {
              _phase = _Phase.failed;
              _errorMsg = 'Lost connection to payment server. '
                  'Check your internet and try again.';
            });
          }

        default: // pending
          _unknownCount = 0;
          _pollCount++;
          if (_pollCount >= _maxPolls) {
            _pollTimer?.cancel();
            setState(() {
              _phase = _Phase.failed;
              _errorMsg =
                  'No response received. Please check your M-Pesa '
                  'messages — if you received a prompt but did not '
                  'approve it, tap Try Again and enter your PIN. '
                  'If you were charged, please contact support.';
            });
          } else {
            setState(() {}); // refresh progress bar
          }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase != _Phase.waiting,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 52),
            constraints: BoxConstraints(
              maxWidth: 440,
              maxHeight: MediaQuery.of(context).size.height * 0.80,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.30),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.11),
                  blurRadius: 72,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: _kGreen.withValues(alpha: 0.09),
                  blurRadius: 44,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.58),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModalHeader(context),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.06),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _buildPhase(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        border: Border(bottom: BorderSide(color: context.divColor, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          if (_phase != _Phase.waiting)
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: context.textColor, size: 18),
              onPressed: () => context.pop(false),
              padding: const EdgeInsets.all(8),
            )
          else
            const SizedBox(width: 40),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _MpesaBadge(size: 26),
                const SizedBox(width: 10),
                Text(
                  'M-Pesa Payment',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _Phase.input:
        return _InputPhase(
          key: const ValueKey('input'),
          formKey: _formKey,
          phoneCtrl: _phoneCtrl,
          amount: widget.amount,
          description: widget.description,
          onPay: _sendStkPush,
          validatePhone: _validatePhone,
        );
      case _Phase.waiting:
        return _WaitingPhase(
          key: const ValueKey('waiting'),
          phone: _mpesa.formatPhone(_phoneCtrl.text),
          amount: widget.amount,
          pollCount: _pollCount,
          maxPolls: _maxPolls,
        );
      case _Phase.success:
        return _SuccessPhase(
          key: const ValueKey('success'),
          amount: widget.amount,
        );
      case _Phase.failed:
        return _FailedPhase(
          key: const ValueKey('failed'),
          message: _errorMsg ?? 'Payment failed. Please try again.',
          onRetry: () => setState(() => _phase = _Phase.input),
        );
    }
  }
}

// ── M-Pesa logo widget ────────────────────────────────────────────────────────
// Renders the official M-PESA SVG wordmark inside a white rounded pill.
// `size` controls the pill height; width expands to the logo's natural ratio.

class _MpesaBadge extends StatelessWidget {
  final double size;
  const _MpesaBadge({required this.size});

  @override
  Widget build(BuildContext context) {
    final logoH = size * 0.52;
    final padH = size * 0.20;
    final padV = size * 0.12;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: SvgPicture.asset(
        'assets/icons/mpesa.svg',
        height: logoH,
        fit: BoxFit.fitHeight,
      ),
    );
  }
}

// ── Input phase ───────────────────────────────────────────────────────────────

class _InputPhase extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneCtrl;
  final int amount;
  final String description;
  final VoidCallback onPay;
  final FormFieldValidator<String> validatePhone;

  const _InputPhase({
    super.key,
    required this.formKey,
    required this.phoneCtrl,
    required this.amount,
    required this.description,
    required this.onPay,
    required this.validatePhone,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Branding + amount ─────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  const _MpesaBadge(size: 76),
                  const SizedBox(height: 20),
                  Text(
                    'KES $amount',
                    style: TextStyle(
                        color: context.textColor,
                        fontSize: 46,
                        fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                        color: context.textSecColor, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08),
            ),
            const SizedBox(height: 36),

            // ── Phone field ───────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'M-Pesa Phone Number',
                  style: TextStyle(
                      color: context.textSecColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                      color: context.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9\s\-+]')),
                  ],
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🇰🇪',
                              style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Container(
                              width: 1, height: 24, color: context.divColor),
                        ],
                      ),
                    ),
                    hintText: '0712 345 678',
                    hintStyle: TextStyle(
                        color: context.textMutedColor, fontSize: 16),
                    filled: true,
                    fillColor: context.surfaceColor,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 16),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.divColor)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.divColor)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: _kGreen, width: 1.8)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.error)),
                    focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.error, width: 1.8)),
                    errorStyle: const TextStyle(color: AppColors.error),
                  ),
                  validator: validatePhone,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the number registered on M-Pesa. You\'ll receive a PIN prompt.',
                  style: TextStyle(color: context.textMutedColor, fontSize: 12, height: 1.4),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
            const SizedBox(height: 32),

            // ── Pay button (M-Pesa green) ─────────────────────────────────
            SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: onPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _MpesaBadge(size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Pay KES $amount via M-Pesa',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 180.ms, duration: 300.ms).slideY(begin: 0.12),
            const SizedBox(height: 14),

            // ── Security note ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 13, color: context.textMutedColor),
                const SizedBox(width: 5),
                Text(
                  'Secured by Safaricom Daraja API',
                  style: TextStyle(color: context.textMutedColor, fontSize: 12),
                ),
              ],
            ).animate().fadeIn(delay: 250.ms),

          ],
        ),
      ),
    );
  }
}

// ── Waiting phase ─────────────────────────────────────────────────────────────

class _WaitingPhase extends StatefulWidget {
  final String phone;
  final int amount;
  final int pollCount;
  final int maxPolls;

  const _WaitingPhase({
    super.key,
    required this.phone,
    required this.amount,
    required this.pollCount,
    required this.maxPolls,
  });

  @override
  State<_WaitingPhase> createState() => _WaitingPhaseState();
}

class _WaitingPhaseState extends State<_WaitingPhase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.pollCount / widget.maxPolls).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pulsing phone icon
          Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kGreen.withValues(
                      alpha: 0.06 + (_pulse.value * 0.10)),
                ),
                child: child,
              ),
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                    color: _kGreen, shape: BoxShape.circle),
                child: const Icon(Icons.phone_android_rounded,
                    color: Colors.white, size: 46),
              ),
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'Check Your Phone',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: context.textColor,
                fontSize: 24,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'An M-Pesa prompt has been sent to\n${widget.phone}',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: context.textSecColor, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Steps
          ...[
            (
              '1',
              'Open the M-Pesa notification on your phone',
              Icons.notifications_active_rounded
            ),
            (
              '2',
              'Enter your M-Pesa PIN when prompted',
              Icons.pin_rounded
            ),
            (
              '3',
              'Tap OK — payment confirms automatically',
              Icons.check_circle_rounded
            ),
          ].map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _kGreen.withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Text(
                        s.$1,
                        style: const TextStyle(
                            color: _kGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      s.$2,
                      style: TextStyle(
                          color: context.textSecColor,
                          fontSize: 13,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: context.divColor,
              valueColor: const AlwaysStoppedAnimation(_kGreen),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'This may take up to 3 minutes — keep this screen open',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: context.textMutedColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Success phase ─────────────────────────────────────────────────────────────

class _SuccessPhase extends StatelessWidget {
  final int amount;
  const _SuccessPhase({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.5),
                    width: 2),
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.success, size: 54),
            )
                .animate()
                .scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 26),
            Text(
              'Payment Successful!',
              style: TextStyle(
                  color: context.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'KES $amount paid via M-Pesa',
              style: TextStyle(
                  color: context.textSecColor, fontSize: 14),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 16),
            Text(
              'Returning you now...',
              style:
                  TextStyle(color: context.textMutedColor, fontSize: 13),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}

// ── Failed phase ──────────────────────────────────────────────────────────────

class _FailedPhase extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _FailedPhase(
      {super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                    width: 1.5),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 46),
            ).animate().scale(duration: 350.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'Payment Failed',
              style: TextStyle(
                  color: context.textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.textSecColor,
                  fontSize: 13,
                  height: 1.55),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 36),
            SizedBox(
              width: 200,
              height: 52,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Try Again',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ).animate().fadeIn(delay: 280.ms),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(false),
              child: Text('Cancel',
                  style: TextStyle(color: context.textSecColor)),
            ).animate().fadeIn(delay: 330.ms),
          ],
        ),
      ),
    );
  }
}
