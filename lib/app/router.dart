import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/state/auth_providers.dart';
import '../features/branch/presentation/branch_finder_screen.dart';
import '../features/branch/presentation/branch_detail_screen.dart';
import '../features/branch/presentation/slot_booking_screen.dart';
import '../features/branch/presentation/live_token_screen.dart';

// We wrap GoRouter in a Riverpod provider so it can react to auth state changes
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    // The Redirect Guard: runs every time the route changes or authState updates
    redirect: (context, state) {
      final isLoggedIn = authState != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login'; // Force login
      if (isLoggedIn && isLoggingIn) return '/';        // Already logged in
      return null;                                      // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const BranchFinderScreen(),
        routes: [
          GoRoute(
            path: 'branch/:id',
            builder: (context, state) {
              final branchId = state.pathParameters['id'] ?? '';
              return BranchDetailScreen(branchId: branchId);
            },
            routes: [
              GoRoute(
                path: 'book',
                builder: (context, state) {
                  final branchId = state.pathParameters['id'] ?? '';
                  final serviceId = state.uri.queryParameters['serviceId'] ?? '';
                  final serviceName = state.uri.queryParameters['serviceName'] ?? 'General Service';
                  return SlotBookingScreen(
                    branchId: branchId,
                    serviceId: serviceId,
                    serviceName: serviceName,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'token/:id',
            builder: (context, state) {
              final tokenId = state.pathParameters['id'] ?? '';
              return LiveTokenScreen(tokenId: tokenId);
            },
          ),
        ],
      ),
    ],
  );
});