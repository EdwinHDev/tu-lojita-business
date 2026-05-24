import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/domain/repositories/auth_repository.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Synchronous initialization or trigger async one
    Future.microtask(() => checkStatus());
    return const AuthInitial();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> checkStatus() async {
    state = const AuthLoading();
    try {
      // Intentamos sincronizar con el backend directamente
      final user = await _repository.checkAuthStatus();
      if (user != null) {
        state = Authenticated(user);
        ref.read(socketServiceProvider).init();
      } else {
        // Si falla el backend (ej: offline), intentamos con la sesión local
        final localUser = await _repository.getSession();
        if (localUser != null) {
          state = Authenticated(localUser);
          ref.read(socketServiceProvider).init();
        } else {
          state = const Unauthenticated();
        }
      }
    } catch (e) {
      state = const Unauthenticated();
    }
  }

  Future<void> refreshUserStatus() async {
    // Reutilizamos checkStatus para refrescar todo el perfil
    await checkStatus();
  }

  Future<void> silentRefresh() async {
    // Actualiza el usuario sin emitir AuthLoading para evitar redirecciones del router
    try {
      final user = await _repository.checkAuthStatus();
      if (user != null) {
        state = Authenticated(user);
      }
    } catch (_) {
      // Si falla, no cambiamos el estado para no cerrar la sesión accidentalmente
    }
  }

  Future<void> login() async {
    state = const AuthLoading();
    try {
      await _repository.loginWithGoogle();
      // Sincronizamos inmediatamente para obtener el estado real de la empresa/tienda
      await checkStatus();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const Unauthenticated();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
