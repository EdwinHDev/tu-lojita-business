import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:tu_lojita_business/features/auth/presentation/screens/login_screen.dart';
import 'package:tu_lojita_business/features/auth/presentation/screens/register_screen.dart';
import 'package:tu_lojita_business/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/screens/company_onboarding_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/company_settings_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/notifications_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/settings_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/profile_settings_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/store_creation_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/store_details_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/store_setup_wizard_screen.dart';
import 'package:tu_lojita_business/features/collaborators/presentation/screens/team_management_screen.dart';
import 'package:tu_lojita_business/features/collaborators/presentation/screens/collaborator_profile_screen.dart';
import 'package:tu_lojita_business/features/activity_log/presentation/screens/activity_log_screen.dart';

import 'package:tu_lojita_business/features/dashboard/presentation/screens/category_list_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/create_category_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/item_list_screen.dart';
import 'package:tu_lojita_business/features/items/presentation/screens/item_form_screen.dart';
import 'package:tu_lojita_business/features/items/presentation/screens/item_detail_screen.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/store_settings_screen.dart';
import 'package:tu_lojita_business/features/orders/presentation/screens/order_list_screen.dart';
import 'package:tu_lojita_business/features/orders/presentation/screens/order_details_screen.dart';
import 'package:tu_lojita_business/features/chat/presentation/screens/order_chat_screen.dart';
import 'package:tu_lojita_business/features/chat/presentation/screens/order_support_chat_screen.dart';
import 'package:tu_lojita_business/features/orders/presentation/screens/store_installments_screen.dart';
import 'package:tu_lojita_business/features/subscription/domain/entities/company_subscription.dart';
import 'package:tu_lojita_business/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:tu_lojita_business/features/subscription/presentation/screens/subscription_paywall_screen.dart';
import 'package:tu_lojita_business/features/subscription/presentation/screens/subscription_pending_screen.dart';
import 'package:tu_lojita_business/features/subscription/presentation/screens/subscription_rejected_screen.dart';
import 'package:tu_lojita_business/features/subscription/presentation/screens/store_debts_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/settings/mediation_requests_screen.dart';
import 'package:tu_lojita_business/features/ranking/presentation/screens/my_ranking_screen.dart';
import 'package:tu_lojita_business/features/ranking/presentation/screens/rank_celebration_screen.dart';
import 'package:tu_lojita_business/features/ranking/presentation/screens/division_down_screen.dart';
import 'package:tu_lojita_business/features/ranking/presentation/screens/achievement_unlocked_screen.dart';
import 'package:tu_lojita_business/features/ranking/presentation/screens/flagged_notice_screen.dart';
import 'package:tu_lojita_business/features/auth/presentation/screens/splash_screen.dart';
import 'package:tu_lojita_business/features/auth/presentation/screens/account_suspended_screen.dart';
import 'package:tu_lojita_business/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:tu_lojita_business/features/auth/presentation/screens/reset_password_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthListenable(ref),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialEmail = extra?['prefilledEmail'] as String?;
          return LoginScreen(initialEmail: initialEmail);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialEmail = extra?['initialEmail'] as String?;
          return ForgotPasswordScreen(initialEmail: initialEmail);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final resetSessionToken = extra['resetSessionToken'] as String? ?? '';
          final email = extra['email'] as String?;
          return ResetPasswordScreen(
            resetSessionToken: resetSessionToken,
            email: email,
          );
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/account-suspended',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final queryParams = state.uri.queryParameters;
          final suspendedUntil =
              (extra['suspendedUntil'] ?? queryParams['suspendedUntil']) as String?;
          final reason =
              (extra['reason'] ?? queryParams['reason']) as String?;
          return AccountSuspendedScreen(
            suspendedUntil: suspendedUntil,
            reason: reason,
          );
        },
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final registrationToken = extra['registrationToken'] as String? ?? '';
          final email = extra['email'] as String? ?? '';
          return VerifyOtpScreen(
            registrationToken: registrationToken,
            email: email,
          );
        },
      ),
      GoRoute(
        path: '/onboarding/company',
        builder: (context, state) => const CompanyOnboardingScreen(),
      ),
      GoRoute(
        path: '/subscription/paywall',
        builder: (context, state) => const SubscriptionPaywallScreen(),
      ),
      GoRoute(
        path: '/subscription/pending',
        builder: (context, state) => const SubscriptionPendingScreen(),
      ),
      GoRoute(
        path: '/subscription/rejected',
        builder: (context, state) => const SubscriptionRejectedScreen(),
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
              final autoOpenDispute =
                  state.uri.queryParameters['openDispute'] == 'true';
              return OrderDetailsScreen(
                orderId: orderId,
                storeId: null,
                autoOpenDispute: autoOpenDispute,
              );
            },
          ),
          GoRoute(
            path: 'orders/:orderId/chat',
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              final userName = state.uri.queryParameters['userName'] ?? 'Cliente';
              return OrderChatScreen(orderId: orderId, userName: userName);
            },
          ),
          GoRoute(
            path: 'orders/:orderId/support-chat',
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              return OrderSupportChatScreen(orderId: orderId);
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
              GoRoute(
                path: 'profile',
                builder: (context, state) => const ProfileSettingsScreen(),
              ),
              GoRoute(
                path: 'team',
                builder: (context, state) => const TeamManagementScreen(),
              ),
              GoRoute(
                path: 'collaborator-profile',
                builder: (context, state) => const CollaboratorProfileScreen(),
              ),
              GoRoute(
                path: 'activity-log',
                builder: (context, state) => const ActivityLogScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'stores/create',
            builder: (context, state) => const StoreCreationScreen(),
          ),
          GoRoute(
            path: 'store-setup-wizard',
            builder: (context, state) => const StoreSetupWizardScreen(),
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
                routes: [
                  GoRoute(
                    path: ':orderId/chat',
                    builder: (context, state) {
                      final orderId = state.pathParameters['orderId']!;
                      final userName = state.uri.queryParameters['userName'] ?? 'Cliente';
                      return OrderChatScreen(orderId: orderId, userName: userName);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'installments',
                builder: (context, state) {
                  final storeId = state.pathParameters['storeId']!;
                  return StoreInstallmentsScreen(storeId: storeId);
                },
              ),
              GoRoute(
                path: 'debts',
                builder: (context, state) {
                  final storeId = state.pathParameters['storeId']!;
                  return StoreDebtsScreen(storeId: storeId);
                },
              ),
              GoRoute(
                path: 'mediation-requests',
                builder: (context, state) {
                  final storeId = state.pathParameters['storeId']!;
                  return MediationRequestsScreen(storeId: storeId);
                },
              ),
              GoRoute(
                path: 'ranking',
                builder: (context, state) {
                  final storeId = state.pathParameters['storeId']!;
                  return MyRankingScreen(storeId: storeId);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'ranking/celebration',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return RankCelebrationScreen(
                division: extra['division']?.toString() ?? 'BRONCE',
                currentLp: int.tryParse(extra['currentLp']?.toString() ?? '0') ?? 0,
                storeId: extra['storeId']?.toString() ?? '',
              );
            },
          ),
          GoRoute(
            path: 'ranking/division-down',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return DivisionDownScreen(
                division: extra['division']?.toString() ?? 'HIERRO',
                currentLp: int.tryParse(extra['currentLp']?.toString() ?? '0') ?? 0,
                storeId: extra['storeId']?.toString() ?? '',
              );
            },
          ),
          GoRoute(
            path: 'ranking/achievement-unlocked',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return AchievementUnlockedScreen(
                title: extra['achievementTitle']?.toString() ?? extra['title']?.toString() ?? '¡Nuevo Logro!',
                description: extra['description']?.toString() ?? 'Has completado un hito en tu negocio.',
                lpBonus: int.tryParse(extra['lpBonus']?.toString() ?? '0') ?? 0,
                badgeUrl: extra['badgeUrl']?.toString(),
                storeId: extra['storeId']?.toString() ?? '',
              );
            },
          ),
          GoRoute(
            path: 'ranking/flagged',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return FlaggedNoticeScreen(
                reason: extra['reason']?.toString(),
                storeId: extra['storeId']?.toString() ?? '',
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/orders/:orderId/support-chat',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderSupportChatScreen(orderId: orderId);
        },
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isSplash = state.matchedLocation == '/splash';
      final isAccountSuspendedRoute = state.matchedLocation == '/account-suspended';
      final isAuthRoute = state.matchedLocation == '/onboarding' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/verify-otp' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/reset-password';
      final isOnboardingCompany = state.matchedLocation == '/onboarding/company';
      final isPaywall = state.matchedLocation == '/subscription/paywall';
      final isPending = state.matchedLocation == '/subscription/pending';
      final isRejected = state.matchedLocation == '/subscription/rejected';

      // 1. Si no está autenticado
      if (authState is! Authenticated) {
        if (isSplash || isAuthRoute || isAccountSuspendedRoute) return null;
        return '/onboarding';
      }

      // 2. Si está en el Splash Screen, dejamos que el SplashScreen orqueste
      if (isSplash) {
        return null;
      }

      final user = authState.user;

      // 3. Si la cuenta comercial está suspendida, bloquear cualquier ruta privada
      if (user.isAccountSuspended) {
        return isAccountSuspendedRoute ? null : '/account-suspended';
      }

      if (isAccountSuspendedRoute) {
        return '/splash';
      }

      // 4. Si ya está autenticado e intenta ir a pantallas de login/onboarding
      if (isAuthRoute) {
        return '/splash';
      }

      // 5. Si no tiene empresa registrada y no es ADMIN ni Colaborador
      if (!user.hasCompany && user.role != 'ADMIN' && !user.isCollaborator) {
        return isOnboardingCompany ? null : '/onboarding/company';
      }

      // Si ya tiene empresa y está intentando volver a onboarding de empresa
      if (user.hasCompany && isOnboardingCompany) {
        if (user.isCollaborator) return '/dashboard';
        final subState = ref.read(subscriptionProvider);
        final sub = subState.subscription;
        if (subState.isReportingPayment || sub?.status == SubscriptionStatus.pendingVerification) {
          return '/subscription/pending';
        }
        if (subState.isPaymentRejected) {
          return '/subscription/rejected';
        }
        if (sub?.status == SubscriptionStatus.paymentRequired ||
            sub?.status == SubscriptionStatus.suspended) {
          return '/subscription/paywall';
        }
        return '/subscription/pending';
      }

      // 5. Para comercios (no ADMIN ni Colaboradores): validar estado de suscripción
      if (user.role != 'ADMIN' && !user.isCollaborator) {
        final subState = ref.read(subscriptionProvider);
        final sub = subState.subscription;

        // Mientras los datos de suscripción se cargan de la API, no asumir ciegamente paywall
        if (sub == null) {
          if (isPending || isRejected || isOnboardingCompany) {
            return null;
          }
          if (isPaywall && subState.isLoading) {
            return null;
          }
          return '/splash';
        }

        // Si el pago fue rechazado por el administrador
        if (subState.isPaymentRejected) {
          return (isRejected || isPaywall) ? null : '/subscription/rejected';
        }

        // Si requiere pago o está suspendida
        if (sub.status == SubscriptionStatus.paymentRequired ||
            sub.status == SubscriptionStatus.suspended) {
          return isPaywall ? null : '/subscription/paywall';
        }

        // Si el pago está en verificación
        if (sub.status == SubscriptionStatus.pendingVerification) {
          return isPending ? null : '/subscription/pending';
        }

        // Si la suscripción está ACTIVE o GRACE_PERIOD y el usuario está en pantallas previas de suscripción
        if (sub.status == SubscriptionStatus.active ||
            sub.status == SubscriptionStatus.gracePeriod) {
          if (isPaywall || isPending || isRejected) {
            return '/splash';
          }
        }
      }

      return null;
    },
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authProvider, (_, next) => notifyListeners());
    ref.listen(subscriptionProvider, (_, next) => notifyListeners());
  }
}
