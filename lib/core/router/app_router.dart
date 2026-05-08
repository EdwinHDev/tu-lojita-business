import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/screens/company_onboarding_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/company_settings_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/notifications_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/settings_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/store_creation_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/store_details_screen.dart';

import 'package:tu_lojita_business/features/dashboard/presentation/screens/category_list_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/create_category_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/item_list_screen.dart';
import 'package:tu_lojita_business/features/items/presentation/screens/item_form_screen.dart';
import 'package:tu_lojita_business/features/items/presentation/screens/item_detail_screen.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/store_settings_screen.dart';
import 'package:tu_lojita_business/features/orders/presentation/screens/order_list_screen.dart';
import 'package:tu_lojita_business/features/orders/presentation/screens/order_details_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: _AuthListenable(ref),
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/company',
        builder: (context, state) => const CompanyOnboardingScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: 'orders/:orderId',
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              return OrderDetailsScreen(orderId: orderId, storeId: null);
            },
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'company',
                builder: (context, state) => const CompanySettingsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'stores/create',
            builder: (context, state) => const StoreCreationScreen(),
          ),
          GoRoute(
            path: 'stores/:storeId',
            builder: (context, state) {
              final storeId = state.pathParameters['storeId']!;
              return StoreDetailsScreen(storeId: storeId);
            },
            routes: [
              GoRoute(
                path: 'settings',
                builder: (context, state) {
                  final storeId = state.pathParameters['storeId']!;
                  return StoreSettingsScreen(storeId: storeId);
                },
              ),
              GoRoute(
                path: 'categories',
                builder: (context, state) {
                  final storeId = state.pathParameters['storeId']!;
                  return CategoryListScreen(storeId: storeId);
                },
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) {
                      final storeId = state.pathParameters['storeId']!;
                      return CreateCategoryScreen(storeId: storeId);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'items',
                builder: (context, state) {
                  final storeId = state.pathParameters['storeId']!;
                  return ItemListScreen(storeId: storeId);
                },
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) {
                      final storeId = state.pathParameters['storeId']!;
                      final item = state.extra is Item ? state.extra as Item : null;
                      return ItemFormScreen(storeId: storeId, item: item);
                    },
                  ),
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final storeId = state.pathParameters['storeId']!;
                      final item = state.extra as Item;
                      return ItemDetailScreen(storeId: storeId, item: item);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'orders',
                builder: (context, state) {
                  final storeId = state.pathParameters['storeId']!;
                  return OrderListScreen(storeId: storeId);
                },
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggingIn = state.matchedLocation == '/onboarding';
      final isOnboardingCompany = state.matchedLocation == '/onboarding/company';

      if (authState is! Authenticated) {
        return (isLoggingIn || isOnboardingCompany) ? null : '/onboarding';
      }

      // If authenticated, check if has company
      final user = authState.user;
      
      if (!user.hasCompany && user.role != 'ADMIN') {
        return isOnboardingCompany ? null : '/onboarding/company';
      }

      if (isLoggingIn || isOnboardingCompany) {
        return '/dashboard';
      }

      return null;
    },
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authProvider, (_, next) => notifyListeners());
  }
}
