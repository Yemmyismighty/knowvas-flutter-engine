import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/manage_devices_screen.dart';
import '../features/auth/presentation/screens/landing_screen.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/auth/presentation/screens/sign_up_screen.dart';
import '../features/auth/presentation/screens/verify_email_screen.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/cart/presentation/screens/screens.dart';
import '../features/checkout/presentation/screens/screens.dart';
import '../features/content/presentation/screens/screens.dart';
import '../features/curated/presentation/screens/curated_genre_screen.dart';
import '../features/discover/presentation/screens/screens.dart';
import '../features/home/presentation/screens/homepage_screen.dart';
import '../features/library/presentation/screens/screens.dart';
import '../features/profile/presentation/screens/screens.dart';
import '../features/reader/presentation/screens/iridium_epub_reader_screen.dart';
import '../features/reader/presentation/screens/webview_reader_screen.dart';
import '../features/settings/presentation/screens/screens.dart';
import '../features/social/presentation/screens/screens.dart';
import '../features/subscription/presentation/screens/pricing_screen.dart';

/// Tracks whether onboarding has been completed (loaded once at startup)
final onboardingDoneProvider = FutureProvider<bool>((ref) => hasSeenOnboarding());

/// Router configuration provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider.select((state) => (
    isInitialized: state.isInitialized,
    isAuthenticated: state.isAuthenticated,
  )));
  final onboardingAsync = ref.watch(onboardingDoneProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isInitialized = authState.isInitialized;
      final isAuthenticated = authState.isAuthenticated;
      final isGoingToAuth = state.matchedLocation.startsWith('/auth');
      final isOnRoot = state.matchedLocation == '/';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // Wait for auth initialization
      if (!isInitialized) return null;

      // Show onboarding on very first launch (only from root)
      if (isOnRoot && !isAuthenticated) {
        final onboardingDone = onboardingAsync.valueOrNull ?? true;
        if (!onboardingDone) return '/onboarding';
        return '/landing';
      }

      // Skip onboarding if already authenticated
      if (isAuthenticated && isOnboarding) return '/home';

      // Redirect authenticated users from auth pages to home
      if (isAuthenticated && (isGoingToAuth || isOnRoot)) {
        return '/home';
      }

      // Redirect unauthenticated users from protected pages to landing
      if (!isAuthenticated && !isGoingToAuth && !isOnRoot && !isOnboarding) {
        return '/landing';
      }

      return null;
    },
    routes: [
      // Root - minimal splash while router resolves redirect
      GoRoute(
        path: '/',
        name: 'landing',
        builder: (context, state) => const _SplashScreen(),
      ),

      // Onboarding (first launch only)
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Landing page for returning unauthenticated users
      GoRoute(
        path: '/landing',
        name: 'landing-page',
        builder: (context, state) => const LandingScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/auth/sign-in',
        name: 'sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/auth/sign-up',
        name: 'sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/auth/verify-email',
        name: 'verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),
      GoRoute(
        path: '/auth/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/manage-devices',
        name: 'manage-devices',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ManageDevicesScreen(token: token);
        },
      ),
      GoRoute(
        path: '/auth/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Main app routes with shell for bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          // Home
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomepageScreen(),
          ),

          // Discover
          GoRoute(
            path: '/discover',
            name: 'discover',
            builder: (context, state) => const DiscoverScreen(),
          ),

          // Library
          GoRoute(
            path: '/library',
            name: 'library',
            builder: (context, state) => const LibraryScreen(),
          ),

          // Profile
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'edit-profile',
                builder: (context, state) => const EditProfileScreen(),
              ),
              GoRoute(
                path: 'following',
                name: 'following',
                builder: (context, state) => const FollowingScreen(),
              ),
              GoRoute(
                path: 'followers',
                name: 'followers',
                builder: (context, state) => const FollowersScreen(),
              ),
            ],
          ),
        ],
      ),

      // Content details (outside shell - no bottom navigation)
      GoRoute(
        path: '/content/:id',
        name: 'content-details',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ContentDetailsScreen(contentId: id);
        },
      ),

      // Reader (outside shell - no bottom navigation)
      GoRoute(
        path: '/reader/:id',
        name: 'reader',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final type = state.uri.queryParameters['type'] ?? 'book';
          final isPreview = state.uri.queryParameters['preview'] == 'true';
          
          // Use Iridium for EPUB (books), WebView for PDF (comics/magazines/newspapers)
          if (type == 'book' || type == 'epub') {
            return IridiumEpubReaderScreen(
              contentId: id,
              isPreview: isPreview,
            );
          } else {
            return WebViewReaderScreen(
              contentId: id,
              contentType: type,
              isPreview: isPreview,
            );
          }
        },
      ),

      // Author/Creator profile (outside shell - no bottom navigation)
      GoRoute(
        path: '/author/:id',
        name: 'author-profile',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AuthorProfileScreen(authorId: id);
        },
      ),

      // Curated genre page (outside shell - no bottom navigation)
      GoRoute(
        path: '/curated/:genreId',
        name: 'curated-genre',
        builder: (context, state) {
          final genreId = state.pathParameters['genreId']!;
          return CuratedGenreScreen(genreId: genreId);
        },
      ),

      // Settings (outside shell - no bottom navigation)
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'notifications',
            name: 'notification-settings',
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
        ],
      ),

      // Pricing/Subscription (outside shell - no bottom navigation)
      GoRoute(
        path: '/pricing',
        name: 'pricing',
        builder: (context, state) => const PricingScreen(),
      ),

      // Checkout (outside shell - no bottom navigation)
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),

      // Payment Success
      GoRoute(
        path: '/payment-success',
        name: 'payment-success',
        builder: (context, state) {
          final reference = state.uri.queryParameters['reference'] ?? '';
          final type = state.uri.queryParameters['type'] ?? 'purchase';
          return PaymentSuccessScreen(reference: reference, type: type);
        },
      ),

      // Payment Error
      GoRoute(
        path: '/payment-error',
        name: 'payment-error',
        builder: (context, state) => const PaymentErrorScreen(),
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});

/// Main shell with bottom navigation
class MainShell extends ConsumerWidget {
  const MainShell({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;

    return Scaffold(
      body: child,
      bottomNavigationBar: isAuthenticated ? const MainBottomNavigation() : null,
    );
  }
}

/// Bottom navigation bar for main app sections
class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location.startsWith('/home')) {
      currentIndex = 0;
    } else if (location.startsWith('/discover')) {
      currentIndex = 1;
    } else if (location.startsWith('/library')) {
      currentIndex = 2;
    } else if (location.startsWith('/profile')) {
      currentIndex = 3;
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/discover');
            break;
          case 2:
            context.go('/library');
            break;
          case 3:
            context.go('/profile');
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Discover',
        ),
        NavigationDestination(
          icon: Icon(Icons.library_books_outlined),
          selectedIcon: Icon(Icons.library_books),
          label: 'Library',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

/// Error screen for navigation errors
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({
    this.error,
    super.key,
  });

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              error?.toString() ?? 'Page not found',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/discover'),
              icon: const Icon(Icons.home),
              label: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimal splash shown at `/` while the router resolves the redirect.
/// Displays just the logo on a white background - no text, no flash.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/logo.png',
          width: 80,
          height: 80,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
