import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/constants/app_strings.dart';
import 'package:taftaf/core/models/user_model.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/router/app_router.dart';
import 'package:taftaf/features/auth/widgets/auth_background.dart';
import 'package:taftaf/shared/widgets/custom_button.dart';
import 'package:taftaf/shared/widgets/loading_widget.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  UserRole _selectedRole = UserRole.client;
  bool _obscurePw = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).signup(
          _usernameCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _phoneCtrl.text.trim(),
          _selectedRole,
          _passwordCtrl.text,
        );

    if (!mounted) return;
    final state = ref.read(authProvider);
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error!), backgroundColor: AppColors.error),
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
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header with title overlay on background
            SizedBox(
              height: height * 0.28,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    AppStrings.createAccount,
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: height * 0.72),
              decoration: BoxDecoration(
                color: context.bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const TaftafLogo(size: 40),
                    const SizedBox(height: 24),
                    _FieldLabel(AppStrings.username),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameCtrl,
                      style: TextStyle(color: context.textColor),
                      decoration: const InputDecoration(hintText: 'Your username'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel(AppStrings.email),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: context.textColor),
                      decoration: const InputDecoration(hintText: 'techguy@gmail.com'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel(AppStrings.phoneNo),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: context.textColor),
                      decoration: const InputDecoration(hintText: '07XXXXXXXX'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel(AppStrings.signUpRole),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: context.inputBgColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<UserRole>(
                          value: _selectedRole,
                          isExpanded: true,
                          dropdownColor: context.surfaceColor,
                          style: TextStyle(color: context.textColor, fontSize: 14),
                          icon: Icon(Icons.keyboard_arrow_down, color: context.textSecColor),
                          items: const [
                            DropdownMenuItem(
                              value: UserRole.client,
                              child: Text('Client'),
                            ),
                            DropdownMenuItem(
                              value: UserRole.owner,
                              child: Text('Property Owner'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _selectedRole = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel(AppStrings.password),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePw,
                      style: TextStyle(color: context.textColor),
                      decoration: InputDecoration(
                        hintText: '••••••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePw ? Icons.visibility_off : Icons.visibility,
                            color: context.textSecColor,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePw = !_obscurePw),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 6) return 'Min 6 characters';
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel(AppStrings.confirmPassword),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      style: TextStyle(color: context.textColor),
                      decoration: InputDecoration(
                        hintText: '••••••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                            color: context.textSecColor,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v != _passwordCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: AppStrings.signupBtn,
                      isLoading: authState.isLoading,
                      onTap: _signup,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppStrings.alreadyRegistered,
                      style: TextStyle(color: context.textSecColor, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: Text(
                        AppStrings.logInHere,
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
