import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/domain/repositories/auth_repository.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:tu_lojita_business/features/auth/data/models/user_model.dart';
import 'package:tu_lojita_business/core/services/session_purge_service.dart';

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
    if (!ref.mounted) return;
    if (localUser != null) {
      state = Authenticated(localUser);
      if (!localUser.isAccountSuspended) {
        ref.read(socketServiceProvider).init();
        ref.read(firebaseMessagingServiceProvider).registerDeviceToken();
      }
    } else {
      state = const AuthLoading();
    }

    try {
      final user = await _repository.checkAuthStatus();
      if (!ref.mounted) return;
      if (user != null) {
        state = Authenticated(user);
        if (!user.isAccountSuspended) {
          ref.read(socketServiceProvider).init();
          ref.read(firebaseMessagingServiceProvider).registerDeviceToken();
        }
      } else {
        final currentSession = await _repository.getSession();
        if (!ref.mounted) return;
        final localDataSource = ref.read(localAuthDataSourceProvider);
        final currentToken = await localDataSource.getAccessToken();
        if (!ref.mounted) return;
        if (currentSession == null || currentToken == null || currentToken.isEmpty) {
          await ref.read(sessionPurgeServiceProvider).purge();
          if (!ref.mounted) return;
          state = const Unauthenticated();
        } else if (state is! Authenticated) {
          state = Authenticated(currentSession);
          if (!currentSession.isAccountSuspended) {
            ref.read(socketServiceProvider).init();
            ref.read(firebaseMessagingServiceProvider).registerDeviceToken();
          }
        }
      }
    } catch (e) {
      if (!ref.mounted) return;
      final errStr = e.toString().toLowerCase();
      final isAuthError = errStr.contains('401') ||
          errStr.contains('unauthorized') ||
          (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403));

      if (isAuthError) {
        await ref.read(sessionPurgeServiceProvider).purge();
        if (!ref.mounted) return;
        state = const Unauthenticated();
        return;
      }

      final currentSession = await _repository.getSession();
      if (!ref.mounted) return;
      final currentToken = await ref.read(localAuthDataSourceProvider).getAccessToken();
      if (!ref.mounted) return;
      if (currentSession == null || currentToken == null || currentToken.isEmpty) {
        await ref.read(sessionPurgeServiceProvider).purge();
        if (!ref.mounted) return;
        state = const Unauthenticated();
      } else if (state is! Authenticated) {
        state = Authenticated(currentSession);
        if (!currentSession.isAccountSuspended) {
          ref.read(socketServiceProvider).init();
          ref.read(firebaseMessagingServiceProvider).registerDeviceToken();
        }
      }
    }
  }

  Future<void> logoutLocal() async {
    await ref.read(sessionPurgeServiceProvider).purge();
    state = const Unauthenticated();
  }

  Future<void> handleAccountSuspended({
    String? reason,
    String? suspendedUntil,
    bool isPermanent = false,
  }) async {
    final current = await _repository.getSession();
    final until = suspendedUntil != null ? DateTime.tryParse(suspendedUntil) : null;
    final effectiveIsPermanent = isPermanent || until == null;
    final fallbackReason = reason ??
        (effectiveIsPermanent
            ? 'Tu cuenta comercial ha sido suspendida permanentemente.'
            : 'Tu cuenta comercial está suspendida temporalmente.');
    final UserModel suspendedUser;
    if (current != null) {
      suspendedUser = UserModel(
        id: current.id,
        email: current.email,
        firstName: current.firstName,
        lastName: current.lastName,
        role: current.role,
        hasCompany: current.hasCompany,
        avatarUrl: current.avatarUrl,
        company: current.company,
        identification: current.identification,
        phone: current.phone,
        isActive: !effectiveIsPermanent,
        accountSuspendedUntil: effectiveIsPermanent ? null : until,
        accountSuspensionReason: fallbackReason,
      );
    } else {
      suspendedUser = UserModel(
        id: 'suspended',
        email: 'user',
        firstName: 'Comercio',
        lastName: '',
        role: 'USER',
        hasCompany: false,
        isActive: !effectiveIsPermanent,
        accountSuspendedUntil: effectiveIsPermanent ? null : until,
        accountSuspensionReason: fallbackReason,
      );
    }
    await _repository.saveUser(suspendedUser);
    state = Authenticated(suspendedUser);
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
      if (e is AccountSuspendedException) {
        final isPermanent = e.isPermanent || e.suspendedUntil == null;
        final suspendedUser = UserModel(
          id: 'suspended',
          email: 'google_user',
          firstName: 'Comercio',
          lastName: '',
          role: 'USER',
          accountSuspendedUntil: isPermanent ? null : DateTime.tryParse(e.suspendedUntil ?? ''),
          accountSuspensionReason: e.reason ??
              (isPermanent
                  ? 'Tu cuenta comercial ha sido suspendida permanentemente.'
                  : 'Tu cuenta comercial está suspendida temporalmente.'),
          isActive: !isPermanent,
        );
        await _repository.saveUser(suspendedUser);
        state = Authenticated(suspendedUser);
        return;
      }
      if (e is AuthException) {
        state = AuthError(e.message, code: e.code);
        return;
      }
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {}
    await ref.read(sessionPurgeServiceProvider).purge();
    state = const Unauthenticated();
  }

  Future<bool> loginWithCredentials(String email, String password) async {
    state = const AuthLoading();
    try {
      await _repository.loginWithEmailPassword(email, password);
      await checkStatus();
      return true;
    } catch (e) {
      if (e is AccountSuspendedException) {
        final isPermanent = e.isPermanent || e.suspendedUntil == null;
        final suspendedUser = UserModel(
          id: 'suspended',
          email: email,
          firstName: 'Comercio',
          lastName: '',
          role: 'USER',
          accountSuspendedUntil: isPermanent ? null : DateTime.tryParse(e.suspendedUntil ?? ''),
          accountSuspensionReason: e.reason ??
              (isPermanent
                  ? 'Tu cuenta comercial ha sido suspendida permanentemente.'
                  : 'Tu cuenta comercial está suspendida temporalmente.'),
          isActive: !isPermanent,
        );
        await _repository.saveUser(suspendedUser);
        state = Authenticated(suspendedUser);
        return true;
      }
      if (e is AuthException) {
        state = AuthError(e.message, code: e.code);
      } else {
        state = AuthError(e.toString());
      }
      return false;
    }
  }

  Future<bool> loginWithCollaborator(String accessId, String password) async {
    state = const AuthLoading();
    try {
      final user = await _repository.loginWithCollaboratorCredentials(accessId, password);
      state = Authenticated(user);
      ref.read(socketServiceProvider).init();
      ref.read(firebaseMessagingServiceProvider).registerDeviceToken();
      return true;
    } catch (e) {
      if (e is AuthException) {
        state = AuthError(e.message, code: e.code);
      } else {
        state = AuthError(e.toString());
      }
      return false;
    }
  }

  Future<void> changeCollaboratorPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _repository.changeCollaboratorPassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      if (e is AuthException) {
        state = AuthError(e.message);
      } else {
        state = AuthError(e.toString());
      }
      rethrow;
    }
  }

  Future<String?> requestForgotPasswordOtp(String email) async {
    try {
      final token = await _repository.requestForgotPasswordOtp(email);
      return token;
    } catch (e) {
      if (e is AuthException) {
        state = AuthError(e.message);
      } else {
        state = AuthError(e.toString());
      }
      rethrow;
    }
  }

  Future<String?> verifyForgotPasswordOtp({
    required String recoveryToken,
    required String otp,
  }) async {
    try {
      final resetSessionToken = await _repository.verifyForgotPasswordOtp(
        recoveryToken: recoveryToken,
        otp: otp,
      );
      return resetSessionToken;
    } catch (e) {
      if (e is AuthException) {
        state = AuthError(e.message);
      } else {
        state = AuthError(e.toString());
      }
      rethrow;
    }
  }

  Future<String?> resendForgotPasswordOtp(String recoveryToken) async {
    try {
      final newToken = await _repository.resendForgotPasswordOtp(recoveryToken);
      return newToken;
    } catch (e) {
      if (e is AuthException) {
        state = AuthError(e.message);
      } else {
        state = AuthError(e.toString());
      }
      rethrow;
    }
  }

  Future<void> resetPasswordWithToken({
    required String resetSessionToken,
    required String newPassword,
  }) async {
    try {
      await _repository.resetPasswordWithToken(
        resetSessionToken: resetSessionToken,
        newPassword: newPassword,
      );
    } catch (e) {
      if (e is AuthException) {
        state = AuthError(e.message);
      } else {
        state = AuthError(e.toString());
      }
      rethrow;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
