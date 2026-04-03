import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/domain/usecases/check_auth_status.dart';
import '../../features/company/presentation/pages/create_company_page.dart';
import '../../features/company/data/services/company_service.dart';
import '../navigation/main_navigation.dart';
import '../di/injection_container.dart';
import '../services/token_storage_service.dart';

class AppRouter {
  static GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) async {
      final checkAuthStatus = sl<CheckAuthStatus>();
      final user = await checkAuthStatus();
      
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isCreateCompany = state.matchedLocation == '/create-company';
      final isHome = state.matchedLocation == '/home';
      
      // Si el usuario no está autenticado
      if (user == null) {
        // Redirigir a onboarding si no está ya ahí
        if (!isOnboarding) {
          return '/onboarding';
        }
        return null;
      }
      
      // Si el usuario está autenticado
      // Verificar si tiene empresa
      final tokenStorage = sl<TokenStorageService>();
      final token = await tokenStorage.getAccessToken();
      
      if (token == null) {
        // Sin token, redirigir a onboarding
        return '/onboarding';
      }
      
      final companyService = CompanyService();
      try {
        final companyCheck = await companyService.checkHasCompany(token);
        
        print('🔍 Company check: hasCompany=${companyCheck.hasCompany}, isHome=$isHome, isCreateCompany=$isCreateCompany');
        
        // Si tiene empresa
        if (companyCheck.hasCompany) {
          // Si no está en home, redirigir a home
          if (!isHome) {
            print('✅ User has company, redirecting to /home');
            return '/home';
          }
          // Ya está en home, no redirigir
          return null;
        }
        
        // Si NO tiene empresa
        if (!companyCheck.hasCompany) {
          // Si no está en create-company, redirigir a create-company
          if (!isCreateCompany) {
            print('❌ User has NO company, redirecting to /create-company');
            // Verificar si tiene tienda para autocompletar RIF
            try {
              final storeCheck = await companyService.checkHasStore(token);
              if (storeCheck.hasStore && storeCheck.storeId != null) {
                final storeDetails = await companyService.getStoreDetails(storeCheck.storeId!, token);
                print('🏪 User has store, auto-filling RIF: ${storeDetails.rif}');
                return '/create-company?rif=${storeDetails.rif}';
              }
            } catch (e) {
              print('⚠️ Error checking store: $e');
            }
            return '/create-company';
          }
          // Ya está en create-company, no redirigir
          return null;
        }
      } catch (e) {
        print('❌ Error checking company status: $e');
        // Si hay error verificando, redirigir a create-company por seguridad
        if (!isCreateCompany) {
          return '/create-company';
        }
      }
      
      // No redirigir
      return null;
    },
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
        path: '/create-company',
        builder: (context, state) {
          final initialRif = state.uri.queryParameters['rif'];
          return CreateCompanyPage(initialRif: initialRif);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigation(),
      ),
    ],
  );
}
