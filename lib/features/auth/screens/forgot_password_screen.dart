import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/router/app_router.dart';
import 'package:taftaf/features/auth/widgets/auth_background.dart';
import 'package:taftaf/shared/widgets/custom_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _codeSent  = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).sendPasswordResetOtp(_emailCtrl.text.trim());
      if (mounted) {
        setState(() { _isLoading = false; _codeSent = true; });
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
            SizedBox(height: height * 0.34),
            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: height * 0.66),
              decoration: BoxDecoration(
                color: context.bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
              child: _codeSent ? _SuccessView(email: _emailCtrl.text.trim()) : _FormView(
                formKey: _formKey,
                emailCtrl: _emailCtrl,
                isLoading: _isLoading,
                error: _error,
                onSend: _send,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool isLoading;
  final String? error;
  final VoidCallback onSend;

  const _FormView({
    required this.formKey,
    required this.emailCtrl,
    required this.isLoading,
    required this.error,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back
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
          const SizedBox(height: 28),
          Text(
            'Forgot Password?',
            style: TextStyle(color: context.textColor, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the email address linked to your account and we\'ll send you a 6-digit reset code.',
            style: TextStyle(color: context.textSecColor, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 32),

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

          // Email label
          Text(
            'EMAIL ADDRESS',
            style: TextStyle(color: context.textSecColor, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: context.textColor),
            decoration: const InputDecoration(
              hintText: 'you@example.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
              return null;
            },
            onFieldSubmitted: (_) => onSend(),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Send Reset Code',
            isLoading: isLoading,
            onTap: onSend,
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.login),
              child: Text(
                'Back to login',
                style: TextStyle(
                  color: context.textSecColor,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: context.textSecColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  const _SuccessView({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 40),
        )
            .animate()
            .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 700.ms)
            .fadeIn(duration: 400.ms),
        const SizedBox(height: 28),
        Text(
          'Check your email',
          style: TextStyle(color: context.textColor, fontSize: 26, fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 12),
        Text(
          'We sent a 6-digit reset code to\n$email\n\nIt expires in 15 minutes.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.textSecColor, fontSize: 14, height: 1.6),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 40),
        PrimaryButton(
          label: 'Enter Reset Code',
          onTap: () => context.push(AppRoutes.resetPassword, extra: email),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () => context.go(AppRoutes.login),
            child: Text(
              'Back to login',
              style: TextStyle(
                color: context.textSecColor,
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: context.textSecColor,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}
