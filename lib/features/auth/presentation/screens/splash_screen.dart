import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';
import 'package:tu_lojita_business/features/subscription/domain/entities/company_subscription.dart';
import 'package:tu_lojita_business/features/subscription/presentation/providers/subscription_provider.dart';

/// Pantalla de bienvenida y orquestador central de arranque para Tu Lojita Business.
///
/// Ejecuta de forma secuencial y en segundo plano todas las comprobaciones necesarias:
/// 1. Estado de autenticación / Sesión activa.
/// 2. Registro de empresa matriz (`hasCompany`).
/// 3. Estado real de la suscripción (Activa, En Verificación, Requerida, Rechazada).
/// 4. Existencia de al menos una sucursal / tienda creada.
///
/// Evita cualquier parpadeo de pantallas intermedias (como la pantalla de pago en verificación)
/// para los usuarios que ya completaron su proceso.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  String? _errorMessage;
  String _statusText = 'Iniciando Tu Lojita...';

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final curved = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(curved);

    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runStartupChecks();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _runStartupChecks() async {
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
      _statusText = 'Verificando sesión...';
    });

    try {
      // 1. Comprobar sesión de usuario
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.checkStatus();
      if (!mounted) return;

      final authState = ref.read(authProvider);
      if (authState is! Authenticated) {
        final localAuth = ref.read(localAuthDataSourceProvider);
        final pendingReg = await localAuth.getPendingRegistration();
        if (!mounted) return;
        if (pendingReg != null) {
          context.go('/verify-otp', extra: {
            'registrationToken': pendingReg['registrationToken'],
            'email': pendingReg['email'],
          });
          return;
        }

        context.go('/onboarding');
        return;
      }

      final user = authState.user;

      // 2. Comprobar si la cuenta comercial está suspendida (cero parpadeo al dashboard/paywall)
      if (user.isAccountSuspended) {
        context.go(
          '/account-suspended',
          extra: {
            'suspendedUntil': user.accountSuspendedUntil?.toIso8601String(),
            'reason': user.accountSuspensionReason,
          },
        );
        return;
      }

      // 3. Si el rol es ADMIN, entra directo al dashboard
      if (user.role == 'ADMIN') {
        context.go('/dashboard');
        return;
      }

      // 3.1. Si el usuario es COLABORADOR: bypass de suscripción y setup wizard
      if (user.isCollaborator) {
        setState(() {
          _statusText = 'Cargando sucursales asignadas...';
        });

        await ref.read(storesProvider.notifier).loadData();
        if (!mounted) return;

        final storesState = ref.read(storesProvider);
        if (storesState.errorMessage != null && storesState.stores.isEmpty) {
          final auth = ref.read(authProvider);
          if (auth is! Authenticated) {
            context.go('/onboarding');
            return;
          }
          final errStr = storesState.errorMessage!.toLowerCase();
          if (errStr.contains('401') || errStr.contains('unauthorized')) {
            await ref.read(authProvider.notifier).logout();
            if (!mounted) return;
            context.go('/onboarding');
            return;
          }
          setState(() {
            _errorMessage =
                'No pudimos cargar tus sucursales. Revisa tu conexión a internet.';
          });
          return;
        }

        final accessibleStores = user.hasFullBranchAccess
            ? storesState.stores
            : storesState.stores
                .where((s) => user.canAccessBranch(s.id))
                .toList();

        if (accessibleStores.isEmpty) {
          setState(() {
            _errorMessage =
                'No tienes sucursales asignadas actualmente. Por favor contacta al administrador de tu empresa.';
          });
          return;
        }

        // Colaborador verificado con sucursales activas -> directo al dashboard
        context.go('/dashboard');
        return;
      }

      // 4. Comprobar si el usuario completó el onboarding de empresa (Solo Propietarios)
      if (!user.hasCompany) {
        context.go('/onboarding/company');
        return;
      }

      // 4. Consultar y verificar el estado real de la suscripción
      setState(() {
        _statusText = 'Comprobando suscripción...';
      });

      await ref.read(subscriptionProvider.notifier).loadSubscriptionAndMethods();
      if (!mounted) return;

      final subState = ref.read(subscriptionProvider);

      // Si falló la red al consultar la suscripción, mostrar opción de reintento
      if (subState.errorMessage != null && subState.subscription == null) {
        final auth = ref.read(authProvider);
        if (auth is! Authenticated) {
          context.go('/onboarding');
          return;
        }
        final errStr = subState.errorMessage!.toLowerCase();
        if (errStr.contains('401') || errStr.contains('unauthorized')) {
          await ref.read(authProvider.notifier).logout();
          if (!mounted) return;
          context.go('/onboarding');
          return;
        }
        setState(() {
          _errorMessage =
              'No pudimos verificar tu suscripción. Revisa tu conexión a internet.';
        });
        return;
      }

      // 4.1. Si el comprobante fue rechazado
      if (subState.isPaymentRejected) {
        context.go('/subscription/rejected');
        return;
      }

      final sub = subState.subscription;

      // 4.2. Si requiere pago o está suspendida
      if (sub == null ||
          sub.status == SubscriptionStatus.paymentRequired ||
          sub.status == SubscriptionStatus.suspended) {
        context.go('/subscription/paywall');
        return;
      }

      // 4.3. Si el pago está en verificación
      if (sub.status == SubscriptionStatus.pendingVerification) {
        context.go('/subscription/pending');
        return;
      }

      // 5. Suscripción activa o en gracia: verificar existencia de tiendas
      setState(() {
        _statusText = 'Cargando sucursales...';
      });

      await ref.read(storesProvider.notifier).loadData();
      if (!mounted) return;

      final storesState = ref.read(storesProvider);

      // Si ocurrió un error de red al cargar las tiendas, mostrar reintento
      if (storesState.errorMessage != null && storesState.stores.isEmpty) {
        final auth = ref.read(authProvider);
        if (auth is! Authenticated) {
          context.go('/onboarding');
          return;
        }
        final errStr = storesState.errorMessage!.toLowerCase();
        if (errStr.contains('401') || errStr.contains('unauthorized')) {
          await ref.read(authProvider.notifier).logout();
          if (!mounted) return;
          context.go('/onboarding');
          return;
        }
        setState(() {
          _errorMessage =
              'No pudimos cargar tus sucursales. Revisa tu conexión a internet.';
        });
        return;
      }

      // 5.1. Si no tiene tiendas o su única tienda no tiene configurada la sucursal,
      // guiar al Post-Activation Store Setup Wizard
      final stores = storesState.stores;
      final needsSetupWizard = stores.isEmpty ||
          (stores.length == 1 &&
              (stores.first.branchName == null ||
                  stores.first.branchName!.trim().isEmpty));

      if (needsSetupWizard) {
        context.go('/dashboard/store-setup-wizard');
        return;
      }

      // 6. ¡Todas las condiciones cumplidas! Entrar al Dashboard
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (auth is! Authenticated) {
        context.go('/onboarding');
        return;
      }
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('401') || errStr.contains('unauthorized')) {
        await ref.read(authProvider.notifier).logout();
        if (!mounted) return;
        context.go('/onboarding');
        return;
      }
      setState(() {
        _errorMessage =
            'Ocurrió un problema de conexión. Por favor reintenta.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final primaryColor = const Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Logo exactamente centrado en la pantalla
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => HugeIcon(
                        icon: HugeIcons.strokeRoundedStore01,
                        color: primaryColor,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Sección dinámica de verificación anclada al fondo
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32.0, 0, 32.0, 36.0),
                child: _errorMessage != null
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedWifiDisconnected01,
                              color: Colors.redAccent,
                              size: 32,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    await ref.read(authProvider.notifier).logout();
                                    if (context.mounted) {
                                      context.go('/onboarding');
                                    }
                                  },
                                  icon: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedLogout01,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Cerrar sesión',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _runStartupChecks,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(0, 40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: const Text(
                                    'Reintentar',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.6,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _statusText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
