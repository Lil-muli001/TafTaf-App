import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taftaf/core/models/property_model.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/features/auth/screens/forgot_password_screen.dart';
import 'package:taftaf/features/auth/screens/login_screen.dart';
import 'package:taftaf/features/auth/screens/listing_payment_screen.dart' show ListingPaymentScreen;
import 'package:taftaf/features/auth/screens/reset_password_screen.dart';
import 'package:taftaf/features/auth/screens/signup_screen.dart';
import 'package:taftaf/features/auth/screens/splash_screen.dart';
import 'package:taftaf/features/onboarding/screens/onboarding_screen.dart';
import 'package:taftaf/features/chat/screens/chat_list_screen.dart';
import 'package:taftaf/features/chat/screens/chat_room_screen.dart';
import 'package:taftaf/features/client/screens/client_home_screen.dart';
import 'package:taftaf/features/client/screens/favorites_screen.dart';
import 'package:taftaf/features/client/screens/property_detail_screen.dart';
import 'package:taftaf/features/client/screens/search_screen.dart';
import 'package:taftaf/features/notifications/screens/notifications_screen.dart' show NotificationsOverlay;
import 'package:taftaf/features/owner/screens/add_property_screen.dart';
import 'package:taftaf/features/owner/screens/analytics_screen.dart';
import 'package:taftaf/features/client/screens/booking_form_screen.dart';
import 'package:taftaf/features/client/screens/my_bookings_screen.dart';
import 'package:taftaf/features/owner/screens/bookings_analytics_screen.dart';
import 'package:taftaf/features/owner/screens/owner_home_screen.dart';
import 'package:taftaf/features/payment/screens/mpesa_payment_screen.dart';
import 'package:taftaf/features/profile/screens/profile_screen.dart';

class AppRoutes {
  static const splash          = '/';
  static const onboarding      = '/onboarding';
  static const login           = '/login';
  static const signup          = '/signup';
  static const forgotPassword  = '/forgot-password';
  static const resetPassword   = '/reset-password';
  static const listingPayment  = '/listing-payment';
  static const clientHome = '/client-home';
  static const ownerHome = '/owner-home';
  static const propertyDetail = '/property/:id';
  static const addProperty = '/add-property';
  static const analytics = '/analytics';
  static const bookingsAnalytics = '/bookings-analytics';
  static const bookProperty = '/book-property';
  static const myBookings = '/my-bookings';
  static const chatList = '/chats';
  static const chatRoom = '/chats/:chatId';
  static const profile = '/profile';
  static const search = '/search';
  static const favorites = '/favorites';
  static const notifications = '/notifications';
  static const mpesaPayment = '/mpesa-payment';

  static String propertyDetailPath(String id) => '/property/$id';
  static String chatRoomPath(String chatId) => '/chats/$chatId';
}

GoRouter createRouter(WidgetRef ref) {
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.uri.path;

      if (authState.isLoading) return null;

      final publicRoutes = [
        AppRoutes.splash, AppRoutes.onboarding,
        AppRoutes.login, AppRoutes.signup,
        AppRoutes.forgotPassword, AppRoutes.resetPassword,
      ];
      final isPublic = publicRoutes.contains(location);

      if (!authState.isAuthenticated) {
        return isPublic ? null : AppRoutes.login;
      }

      final user = authState.currentUser!;

      // Redirect from auth routes to home when already logged in
      if (isPublic && location != AppRoutes.splash) {
        return user.isOwner ? AppRoutes.ownerHome : AppRoutes.clientHome;
      }

      // ── Role-based route guards ─────────────────────────────────────────────
      // Owners must never see client-only screens (and vice versa).
      const ownerOnlyRoutes = [
        AppRoutes.addProperty,
        AppRoutes.analytics,
        AppRoutes.bookingsAnalytics,
      ];
      const clientOnlyRoutes = [
        AppRoutes.search,
        AppRoutes.favorites,
        AppRoutes.bookProperty,
        AppRoutes.myBookings,
        AppRoutes.clientHome,
      ];

      if (user.isOwner && clientOnlyRoutes.contains(location)) {
        return AppRoutes.ownerHome;
      }
      if (!user.isOwner && ownerOnlyRoutes.contains(location)) {
        return AppRoutes.clientHome;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (_, state) => _fadePage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, state) => _fadePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (_, state) => _fadePage(state, const SignupScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (_, state) => _slidePage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        pageBuilder: (_, state) {
          final email = state.extra as String? ?? '';
          return _slidePage(state, ResetPasswordScreen(email: email));
        },
      ),
      GoRoute(
        path: AppRoutes.listingPayment,
        pageBuilder: (_, state) {
          final property = state.extra as PropertyModel;
          return _slidePage(state, ListingPaymentScreen(property: property));
        },
      ),
      GoRoute(
        path: AppRoutes.clientHome,
        pageBuilder: (_, state) => _fadePage(state, const ClientHomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.ownerHome,
        pageBuilder: (_, state) => _fadePage(state, const OwnerHomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.propertyDetail,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _slidePage(state, PropertyDetailScreen(propertyId: id));
        },
      ),
      GoRoute(
        path: AppRoutes.addProperty,
        pageBuilder: (_, state) {
          final editProperty = state.extra as PropertyModel?;
          return _slidePage(state, AddPropertyScreen(editProperty: editProperty));
        },
      ),
      GoRoute(
        path: AppRoutes.analytics,
        pageBuilder: (_, state) => _slidePage(state, const AnalyticsScreen()),
      ),
      GoRoute(
        path: AppRoutes.bookingsAnalytics,
        pageBuilder: (_, state) => _slidePage(state, const BookingsAnalyticsScreen()),
      ),
      GoRoute(
        path: AppRoutes.bookProperty,
        pageBuilder: (_, state) {
          final property = state.extra as PropertyModel;
          return _slidePage(state, BookingFormScreen(property: property));
        },
      ),
      GoRoute(
        path: AppRoutes.myBookings,
        pageBuilder: (_, state) => _slidePage(state, const MyBookingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.chatList,
        pageBuilder: (_, state) => _slidePage(state, const ChatListScreen()),
      ),
      GoRoute(
        path: AppRoutes.chatRoom,
        pageBuilder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return _slidePage(
            state,
            ChatRoomScreen(chatId: chatId, chatTitle: extra?['title'] ?? 'Chat'),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (_, state) => _slidePage(state, const ProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.search,
        pageBuilder: (_, state) => _slidePage(state, const SearchScreen()),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        pageBuilder: (_, state) => _slidePage(state, const FavoritesScreen()),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (_, state) => _overlayPage(state, const NotificationsOverlay()),
      ),
      GoRoute(
        path: AppRoutes.mpesaPayment,
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return _dialogPage(
            state,
            MpesaPaymentScreen(
              amount: extra['amount'] as int,
              description: extra['description'] as String,
              accountReference: extra['reference'] as String,
            ),
          );
        },
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}', style: const TextStyle(color: Colors.white)),
      ),
    ),
  );
}

// Transparent overlay that slides down from the top — used for the
// notifications panel so the active screen stays visible behind it.
CustomTransitionPage<void> _overlayPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    opaque: false,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.50),
    child: child,
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.0, -0.05),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<void> _dialogPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    opaque: false,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.60),
    child: child,
    transitionsBuilder: (_, animation, _, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final scale = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(scale),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

CustomTransitionPage<void> _slidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (_, animation, _, child) {
      final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeInOut));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
