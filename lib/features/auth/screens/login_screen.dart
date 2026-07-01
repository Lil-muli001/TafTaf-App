import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/constants/app_strings.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/router/app_router.dart';
import 'package:taftaf/features/auth/widgets/auth_background.dart';
import 'package:taftaf/shared/widgets/custom_button.dart';
import 'package:taftaf/shared/widgets/loading_widget.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
          _usernameCtrl.text.trim(),
          _passwordCtrl.text,
        );

    if (!mounted) return;
    final state = ref.read(authProvider);
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: AppColors.error,
        ),
      );
      ref.read(authProvider.notifier).clearError();
      return;
    }

    final user = state.currentUser!;
    if (user.isOwner) {
      context.go(AppRoutes.ownerHome);
    } else {
      context.go(AppRoutes.clientHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final authState = ref.watch(authProvider);

    return AuthBackground(
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: height * 0.34),
                // ── Form container ──
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Logo
                        const TaftafLogo(size: 44),
                        const SizedBox(height: 20),
                        // Title
                        Text(
                          AppStrings.loginTitle,
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.signup),
                          child: Text(
                            AppStrings.loginSubtitle,
                            style: TextStyle(color: context.textSecColor, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Username field
                        _FieldLabel(AppStrings.username),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameCtrl,
                          style: TextStyle(color: context.textColor),
                          decoration: const InputDecoration(hintText: 'Enter username or email'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 20),
                        // Password field
                        _FieldLabel(AppStrings.password),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: context.textColor),
                          decoration: InputDecoration(
                            hintText: '••••••••••',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: context.textSecColor,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          onFieldSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 36),
                        // Login button
                        PrimaryButton(
                          label: AppStrings.loginBtn,
                          isLoading: authState.isLoading,
                          onTap: _login,
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.forgotPassword),
                          child: Text(
                            AppStrings.forgotPassword,
                            style: TextStyle(color: context.textSecColor, fontSize: 13),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.signup),
                          child: Text(
                            AppStrings.signup,
                            style: TextStyle(
                              color: context.textSecColor,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                              decorationColor: context.textSecColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: context.textSecColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
