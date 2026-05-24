import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/domain/repositories/auth_repository.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';

class ProfileSettingsState {
  final bool isLoading;
  final String? error;
  final bool success;

  const ProfileSettingsState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  ProfileSettingsState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return ProfileSettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
    );
  }
}

class ProfileSettingsNotifier extends Notifier<ProfileSettingsState> {
  @override
  ProfileSettingsState build() {
    return const ProfileSettingsState();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<bool> updateProfile({
    required String identification,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      await _repository.updateProfile(identification, phone);
      if (!ref.mounted) return true;
      state = state.copyWith(isLoading: false, success: true);
      // Silently refresh the local session and global state to update widgets reactively
      await ref.read(authProvider.notifier).silentRefresh();
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final profileSettingsProvider = NotifierProvider<ProfileSettingsNotifier, ProfileSettingsState>(() {
  return ProfileSettingsNotifier();
});
