import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/models/booking_model.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/router/app_router.dart';

// ── Client nav (unchanged layout, updated colors) ─────────────────────────────

class ClientBottomNav extends StatelessWidget {
  final int currentIndex;
  const ClientBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return _ClientNavBar(
      currentIndex: currentIndex,
      items: const [
        _NavItem(icon: Icons.home_rounded,              label: 'Home'),
        _NavItem(icon: Icons.search_rounded,             label: 'Search'),
        _NavItem(icon: Icons.calendar_month_rounded,     label: 'Bookings'),
        _NavItem(icon: Icons.chat_bubble_rounded,        label: 'Chat'),
        _NavItem(icon: Icons.person_rounded,             label: 'Profile'),
      ],
      onTap: (i) {
        switch (i) {
          case 0: context.go(AppRoutes.clientHome);
          case 1: context.go(AppRoutes.search);
          case 2: context.go(AppRoutes.myBookings);
          case 3: context.go(AppRoutes.chatList);
          case 4: context.go(AppRoutes.profile);
        }
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _ClientNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final void Function(int) onTap;

  const _ClientNavBar({required this.currentIndex, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.bgColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final active = i == currentIndex;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap(i);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary.withValues(alpha: 0.14) : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: active ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            item.icon,
                            color: active ? AppColors.primary : context.textMutedColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: active ? AppColors.primary : context.textMutedColor,
                            fontSize: 9,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Owner nav — floating pill (Apple Fitness style) ───────────────────────────

class OwnerBottomNav extends ConsumerWidget {
  final int currentIndex;
  const OwnerBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref
        .watch(bookingProvider)
        .where((b) => b.status == BookingStatus.pending)
        .length;

    return Container(
      color: context.bgColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _PillItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => context.go(AppRoutes.ownerHome),
                ),
                _PillItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Bookings',
                  isSelected: currentIndex == 1,
                  onTap: () => context.go(AppRoutes.bookingsAnalytics),
                  badgeCount: pendingCount,
                ),
                // ── Centre FAB ──
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push(AppRoutes.addProperty);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: AppColors.black, size: 28),
                  ),
                ),
                _PillItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Messages',
                  isSelected: currentIndex == 3,
                  onTap: () => context.go(AppRoutes.chatList),
                ),
                _PillItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: currentIndex == 4,
                  onTap: () => context.go(AppRoutes.profile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _PillItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Badge(
                isLabelVisible: badgeCount > 0,
                label: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800),
                ),
                backgroundColor: AppColors.error,
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : context.textMutedColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : context.textMutedColor,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
