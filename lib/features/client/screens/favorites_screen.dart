import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/shared/widgets/bottom_nav_bar.dart';
import 'package:taftaf/shared/widgets/property_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;
    final favoritesAsync = ref.watch(favoritesProvider(user?.id ?? ''));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('FAVORITES', style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5)),
        backgroundColor: context.bgColor,
        automaticallyImplyLeading: false,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: context.divColor),
        ),
      ),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        data: (favorites) {
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, color: context.textSecColor, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet.\nTap the heart on a property to save it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textSecColor, fontSize: 14),
                  ),
                ],
              ).animate().fadeIn(),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (_, i) => PropertyListCard(property: favorites[i])
                .animate()
                .fadeIn(delay: (i * 80).ms)
                .slideY(begin: 0.1),
          );
        },
      ),
      bottomNavigationBar: const ClientBottomNav(currentIndex: 2),
    );
  }
}
