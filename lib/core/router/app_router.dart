import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/auth/domain/entities/backend_user_entity.dart';
import '../di/injection_container.dart';

class AppRouter {
  static GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingPage(
          getOnboardingItems: sl(),
          signInWithGoogle: sl(),
          authenticateWithBackend: sl(),
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          final user = state.extra as BackendUserEntity?;
          return HomePage(user: user);
        },
      ),
    ],
  );
}
