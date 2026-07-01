import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/router/app_router.dart';
import 'package:taftaf/shared/widgets/bottom_nav_bar.dart';
import 'package:taftaf/shared/widgets/custom_button.dart';
import 'package:taftaf/shared/widgets/loading_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).currentUser;
    _usernameCtrl.text = user?.username ?? '';
    _emailCtrl.text = user?.email ?? '';
    _phoneCtrl.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // Step 1: ask the user where the image comes from.
  Future<ImageSource?> _showSourcePicker() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: ctx.divColor,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text('Choose photo',
                style: TextStyle(
                    color: ctx.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: ctx.primarySurfColor,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary, size: 22),
              ),
              title: Text('Gallery',
                  style: TextStyle(
                      color: ctx.textColor, fontWeight: FontWeight.w500)),
              subtitle: Text('Choose an existing photo',
                  style:
                      TextStyle(color: ctx.textMutedColor, fontSize: 12)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: ctx.primarySurfColor,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary, size: 22),
              ),
              title: Text('Camera',
                  style: TextStyle(
                      color: ctx.textColor, fontWeight: FontWeight.w500)),
              subtitle: Text('Take a new photo',
                  style:
                      TextStyle(color: ctx.textMutedColor, fontSize: 12)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Step 2a: update profile picture
  Future<void> _pickProfilePic() async {
    final source = await _showSourcePicker();
    if (source == null || !mounted) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 88,
    );
    if (picked == null || !mounted) return;

    await ref.read(authProvider.notifier).updateProfile(profilePic: picked.path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Profile photo updated!'),
          backgroundColor: AppColors.success),
    );
  }

  // Step 2b: update cover photo
  Future<void> _pickCoverPhoto() async {
    final source = await _showSourcePicker();
    if (source == null || !mounted) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 88,
    );
    if (picked == null || !mounted) return;

    await ref.read(authProvider.notifier).updateProfile(coverPhoto: picked.path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Cover photo updated!'),
          backgroundColor: AppColors.success),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    await ref.read(authProvider.notifier).updateProfile(
          username: _usernameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
    setState(() {
      _isSaving = false;
      _isEditing = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated!'), backgroundColor: AppColors.success),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => const _HelpSheet(),
    );
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => const _PrivacySheet(),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        title: Text('Log Out', style: TextStyle(color: ctx.textColor)),
        content: Text('Are you sure you want to log out?', style: TextStyle(color: ctx.textSecColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;
    if (user == null) return const SizedBox();
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: context.textColor)),
        backgroundColor: context.bgColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(user.isOwner ? AppRoutes.ownerHome : AppRoutes.clientHome);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_isEditing) {
                setState(() {
                  _isEditing = false;
                  _usernameCtrl.text = user.username;
                  _emailCtrl.text = user.email;
                  _phoneCtrl.text = user.phone;
                });
              } else {
                setState(() => _isEditing = true);
              }
            },
            child: Text(
              _isEditing ? 'Cancel' : 'Edit',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Cover photo + avatar ───────────────────────────────────
            // Stack height = 180 (cover) + 54 (avatar radius below cover).
            // Keeping the avatar inside the Stack's bounds makes its
            // GestureDetector reachable by Flutter's hit-testing.
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Defines the Stack's intrinsic height so the avatar is inside it.
                const SizedBox(height: 234, width: double.infinity),
                // Cover image — top 180 px
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: user.coverPhoto != null && user.coverPhoto!.isNotEmpty
                        ? PropertyImageWidget(
                            path: user.coverPhoto!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/images/bg_profile_cover.jpg',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                  ),
                ),
                // Gradient fade at bottom of cover
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          isDark ? const Color(0xBB0D1B2A) : const Color(0x88F2F2F7),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Cover photo edit button — top right
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _pickCoverPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.30)),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
                // Profile picture — bottom center, within Stack bounds
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _pickProfilePic,
                      child: Stack(
                        children: [
                          UserAvatarWidget(
                            profilePic: user.profilePic,
                            displayName: user.username,
                            radius: 54,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt,
                                  color: AppColors.black, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().scale(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    user.username,
                    style: TextStyle(color: context.textColor, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.primarySurfColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.isOwner ? 'Property Owner' : 'Client',
                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Edit / View mode ──────────────────────────────────────
                  if (_isEditing) ...[
                    _InfoField(label: 'Username', controller: _usernameCtrl, icon: Icons.person_outline),
                    const SizedBox(height: 12),
                    _InfoField(label: 'Email', controller: _emailCtrl, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _InfoField(label: 'Phone', controller: _phoneCtrl, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                    const SizedBox(height: 24),
                    PrimaryButton(label: 'Save Changes', isLoading: _isSaving, onTap: _saveProfile),
                  ] else ...[
                    _InfoTile(icon: Icons.person_outline, label: 'Username', value: user.username),
                    _InfoTile(icon: Icons.email_outlined, label: 'Email', value: user.email),
                    _InfoTile(icon: Icons.phone_outlined, label: 'Phone', value: user.phone.isNotEmpty ? user.phone : '—'),
                    _InfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Member Since',
                      value: '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                    ),
                  ],
                  const SizedBox(height: 20),

                  // ── Quick links ───────────────────────────────────────────
                  _MenuTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () => context.push(AppRoutes.notifications)),
                  if (user.isOwner)
                    _MenuTile(icon: Icons.bar_chart_rounded, label: 'Analytics', onTap: () => context.push(AppRoutes.analytics)),
                  _MenuTile(icon: Icons.lock_outline_rounded, label: 'Change Password', onTap: () => _showChangePasswordSheet(context)),
                  _ThemeToggleTile(
                    isDark: isDark,
                    onToggle: () => ref.read(themeModeProvider.notifier).toggle(),
                  ),
                  _MenuTile(icon: Icons.help_outline_rounded, label: 'Help & Support', onTap: () => _showHelpSheet(context)),
                  _MenuTile(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () => _showPrivacySheet(context)),
                  const SizedBox(height: 8),
                  _MenuTile(
                    icon: Icons.logout_rounded,
                    label: 'Log Out',
                    onTap: _logout,
                    iconColor: const Color(0xFF8CBB00),
                    textColor: const Color(0xFF8CBB00),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: user.isOwner
          ? const OwnerBottomNav(currentIndex: 4)
          : const ClientBottomNav(currentIndex: 4),
    );
  }
}

// ── Theme Toggle Tile ─────────────────────────────────────────────────────────

class _ThemeToggleTile extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const _ThemeToggleTile({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.divColor),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          leading: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          title: Text('Dark Mode', style: TextStyle(color: context.textColor, fontSize: 14)),
          trailing: Switch.adaptive(
            value: isDark,
            onChanged: (_) => onToggle(),
            activeThumbColor: AppColors.black,
            activeTrackColor: AppColors.primary,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ── Info Tile ─────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: context.textMutedColor, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Info Field ────────────────────────────────────────────────────────────────

class _InfoField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;

  const _InfoField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.textSecColor, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: context.textColor),
          decoration: InputDecoration(prefixIcon: Icon(icon, color: context.textSecColor, size: 20)),
        ),
      ],
    );
  }
}

// ── Menu Tile ─────────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.divColor),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
          title: Text(label, style: TextStyle(color: textColor ?? context.textColor, fontSize: 14)),
          trailing: Icon(Icons.chevron_right, color: context.textSecColor, size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ── Change Password sheet ─────────────────────────────────────────────────────

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _isSaving       = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isSaving = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).changePassword(
        currentPassword: _currentCtrl.text,
        newPassword:     _newCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(color: context.divColor, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Change Password',
                    style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Enter your current password, then choose a new one.',
                    style: TextStyle(color: context.textSecColor, fontSize: 13)),
                const SizedBox(height: 24),
                _PasswordField(
                  label: 'Current Password',
                  controller: _currentCtrl,
                  obscure: _obscureCurrent,
                  onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  label: 'New Password',
                  controller: _newCtrl,
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  label: 'Confirm New Password',
                  controller: _confirmCtrl,
                  obscure: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v != _newCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x22FF6B6B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B6B), size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(label: 'Update Password', isLoading: _isSaving, onTap: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.textSecColor, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller:  controller,
          obscureText: obscure,
          style:       TextStyle(color: context.textColor),
          validator:   validator,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline_rounded, color: context.textSecColor, size: 20),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: context.textSecColor, size: 20),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Help & Support sheet ──────────────────────────────────────────────────────

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: context.divColor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Text('Help & Support', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('How can we help you?', style: TextStyle(color: context.textSecColor, fontSize: 13)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: const [
                _HelpItem(icon: Icons.question_answer_rounded, title: 'FAQs', subtitle: 'Answers to common questions about listings, payments, and accounts'),
                _HelpItem(icon: Icons.email_outlined, title: 'Email Support', subtitle: 'support@taftaf.co.ke\nWe respond within 24 hours'),
                _HelpItem(icon: Icons.phone_outlined, title: 'Call Us', subtitle: '+254 700 000 000\nMon – Fri, 8 AM – 6 PM EAT'),
                _HelpItem(icon: Icons.chat_bubble_outline_rounded, title: 'Live Chat', subtitle: 'Chat with our support team in real time'),
                _HelpItem(icon: Icons.bug_report_outlined, title: 'Report a Bug', subtitle: 'Found something broken? Let us know so we can fix it'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _HelpItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.divColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: context.primarySurfColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: context.textColor, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: context.textSecColor, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.textMutedColor, size: 18),
        ],
      ),
    );
  }
}

// ── Privacy Policy sheet ──────────────────────────────────────────────────────

class _PrivacySheet extends StatelessWidget {
  const _PrivacySheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: context.divColor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Text('Privacy Policy', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Last updated: May 2026', style: TextStyle(color: context.textMutedColor, fontSize: 12)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: const [
                _PolicySection(title: '1. Information We Collect', body: 'We collect information you provide directly, such as your name, email address, phone number, and property details when you register or list a property on TafTaf.'),
                _PolicySection(title: '2. How We Use Your Information', body: 'Your information is used to operate and improve the platform, connect property owners with clients, send notifications about your listings or inquiries, and process payments securely.'),
                _PolicySection(title: '3. Data Sharing', body: 'We do not sell your personal data. We may share information with service providers who assist in operating the platform, subject to strict confidentiality agreements.'),
                _PolicySection(title: '4. Data Security', body: 'We implement industry-standard security measures to protect your information. However, no method of transmission over the internet is 100% secure.'),
                _PolicySection(title: '5. Your Rights', body: 'You have the right to access, correct, or delete your personal data at any time. Contact us at privacy@taftaf.co.ke to exercise these rights.'),
                _PolicySection(title: '6. Contact Us', body: 'For any privacy-related questions, reach us at:\nEmail: privacy@taftaf.co.ke\nPhone: +254 700 000 000'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;
  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(color: context.textSecColor, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }
}
