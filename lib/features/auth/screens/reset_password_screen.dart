import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/router/app_router.dart';
import 'package:taftaf/features/auth/widgets/auth_background.dart';
import 'package:taftaf/shared/widgets/custom_button.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _otpCtrl        = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  final _confirmCtrl    = TextEditingController();
  bool _obscurePw       = true;
  bool _obscureConfirm  = true;
  bool _isLoading       = false;
  bool _success         = false;
  String? _error;

  @override
  void dispose() {
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).resetPasswordWithOtp(
        email: widget.email,
        otp: _otpCtrl.text.trim(),
        newPassword: _passwordCtrl.text,
      );
      if (mounted) {
        setState(() { _isLoading = false; _success = true; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return AuthBackground(
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: height * 0.30),
            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: height * 0.70),
              decoration: BoxDecoration(
                color: context.bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
              child: _success ? _SuccessView() : _FormView(
                formKey: _formKey,
                email: widget.email,
                otpCtrl: _otpCtrl,
                passwordCtrl: _passwordCtrl,
                confirmCtrl: _confirmCtrl,
                obscurePw: _obscurePw,
                obscureConfirm: _obscureConfirm,
                isLoading: _isLoading,
                error: _error,
                onTogglePw: () => setState(() => _obscurePw = !_obscurePw),
                onToggleConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
                onReset: _reset,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── Form ────────────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String email;
  final TextEditingController otpCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePw;
  final bool obscureConfirm;
  final bool isLoading;
  final String? error;
  final VoidCallback onTogglePw;
  final VoidCallback onToggleConfirm;
  final VoidCallback onReset;

  const _FormView({
    required this.formKey,
    required this.email,
    required this.otpCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.obscurePw,
    required this.obscureConfirm,
    required this.isLoading,
    required this.error,
    required this.onTogglePw,
    required this.onToggleConfirm,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: context.divColor),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: context.textColor, size: 16),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Reset Password',
            style: TextStyle(color: context.textColor, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(color: context.textSecColor, fontSize: 13, height: 1.5),
              children: [
                const TextSpan(text: 'Enter the 6-digit code sent to '),
                TextSpan(
                  text: email,
                  style: TextStyle(color: context.textColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Error banner
          if (error != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          _Label('RESET CODE'),
          const SizedBox(height: 8),
          TextFormField(
            controller: otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: TextStyle(
              color: context.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '• • • • • •',
              hintStyle: TextStyle(color: context.textMutedColor, letterSpacing: 6),
              counterText: '',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (v.trim().length != 6) return 'Code must be 6 digits';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),

          _Label('NEW PASSWORD'),
          const SizedBox(height: 8),
          TextFormField(
            controller: passwordCtrl,
            obscureText: obscurePw,
            style: TextStyle(color: context.textColor),
            decoration: InputDecoration(
              hintText: '••••••••••',
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePw ? Icons.visibility_off : Icons.visibility,
                  color: context.textSecColor,
                  size: 20,
                ),
                onPressed: onTogglePw,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.length < 6) return 'Min 6 characters';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),

          _Label('CONFIRM NEW PASSWORD'),
          const SizedBox(height: 8),
          TextFormField(
            controller: confirmCtrl,
            obscureText: obscureConfirm,
            style: TextStyle(color: context.textColor),
            decoration: InputDecoration(
              hintText: '••••••••••',
              suffixIcon: IconButton(
                icon: Icon(
                  obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: context.textSecColor,
                  size: 20,
                ),
                onPressed: onToggleConfirm,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v != passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
            onFieldSubmitted: (_) => onReset(),
          ),
          const SizedBox(height: 32),

          PrimaryButton(
            label: 'Reset Password',
            isLoading: isLoading,
            onTap: onReset,
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.textSecColor,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Success ─────────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_open_rounded, color: AppColors.primary, size: 40),
        )
            .animate()
            .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 700.ms)
            .fadeIn(duration: 400.ms),
        const SizedBox(height: 28),
        Text(
          'Password Reset!',
          style: TextStyle(color: context.textColor, fontSize: 26, fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 12),
        Text(
          'Your password has been updated successfully.\nYou can now log in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.textSecColor, fontSize: 14, height: 1.6),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 40),
        PrimaryButton(
          label: 'Back to Login',
          onTap: () => context.go(AppRoutes.login),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}
