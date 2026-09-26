import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/domain/repositories/auth_repository.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/features/auth/domain/exceptions/auth_exceptions.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Synchronous initialization or trigger async one
    Future.microtask(() => checkStatus());
    return const AuthInitial();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> checkStatus() async {
    final localUser = await _repository.getSession();
    if (localUser != null) {
      state = Authenticated(localUser);
      ref.read(socketServiceProvider).init();
      ref.read(firebaseMessagingServiceProvider).registerDeviceToken();
    } else {
      state = const AuthLoading();
    }

    try {
      final user = await _repository.checkAuthStatus();
      if (user != null) {
        state = Authenticated(user);
        ref.read(socketServiceProvider).init();
        ref.read(firebaseMessagingServiceProvider).registerDeviceToken();
      } else if (state is! Authenticated) {
        final fallbackUser = await _repository.getSession();
        if (fallbackUser != null) {
          state = Authenticated(fallbackUser);
          ref.read(socketServiceProvider).init();
          ref.read(firebaseMessagingServiceProvider).registerDeviceToken();
        } else {
          state = const Unauthenticated();
        }
      }
    } catch (e) {
      if (state is! Authenticated) {
        final fallbackUser = await _repository.getSession();
        if (fallbackUser != null) {
          state = Authenticated(fallbackUser);
          ref.read(socketServiceProvider).init();
          ref.read(firebaseMessagingServiceProvider).registerDeviceToken();
        } else {
          state = const Unauthenticated();
        }
      }
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
      if (e is GoogleSignInCancelledException) {
        state = const Unauthenticated();
        return;
      }
      if (e is AuthException) {
        state = AuthError(e.message);
        return;
      }
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const Unauthenticated();
  }

  Future<bool> loginWithCredentials(String email, String password) async {
    state = const AuthLoading();
    try {
      await _repository.loginWithEmailPassword(email, password);
      await checkStatus();
      return true;
    } catch (e) {
      if (e is AuthException) {
        state = AuthError(e.message);
      } else {
        state = AuthError(e.toString());
      }
      return false;
    }
  }

  Future<bool> registerWithCredentials({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = const AuthLoading();
    try {
      await _repository.registerWithEmailPassword(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      await checkStatus();
      return true;
    } catch (e) {
      if (e is AuthException) {
        state = AuthError(e.message);
      } else {
        state = AuthError(e.toString());
      }
      return false;
    }
  }

  Future<String?> requestRegistrationOtp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
    String? phone,
    String? identification,
  }) async {
    try {
      final token = await _repository.requestRegistrationOtp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        identification: identification,
      );
      return token;
    } catch (e) {
      if (e is AuthException) {
        state = AuthError(e.message);
      } else {
        state = AuthError(e.toString());
      }
      return null;
    }
  }

  Future<bool> verifyRegistrationOtp({
    required String registrationToken,
    required String otp,
  }) async {
    state = const AuthLoading();
    try {
      await _repository.verifyRegistrationOtp(
        registrationToken: registrationToken,
        otp: otp,
      );
      await checkStatus();
      return true;
    } catch (e) {
      if (e is AuthException) {
        state = AuthError(e.message);
      } else {
        state = AuthError(e.toString());
      }
      return false;
    }
  }

  Future<String?> resendRegistrationOtp({
    required String registrationToken,
  }) async {
    try {
      final newToken = await _repository.resendRegistrationOtp(
        registrationToken: registrationToken,
      );
      return newToken;
    } catch (e) {
      if (e is AuthException) {
        state = AuthError(e.message);
      } else {
        state = AuthError(e.toString());
      }
      return null;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
