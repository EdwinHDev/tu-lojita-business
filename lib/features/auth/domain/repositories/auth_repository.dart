import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> loginWithGoogle();
  Future<void> logout();
  Future<User?> getSession();
  Future<Map<String, dynamic>> checkCompanyStatus();
  Future<Map<String, dynamic>> checkStoreStatus();
  Future<void> saveUser(User user);
  Future<User?> checkAuthStatus();
  Future<User> updateProfile(String? identification, String? phone);
  Future<User> loginWithEmailPassword(String email, String password);
  Future<User> registerWithEmailPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });
  Future<String> requestRegistrationOtp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
    String? phone,
    String? identification,
  });
  Future<User> verifyRegistrationOtp({
    required String registrationToken,
    required String otp,
  });
  Future<String> resendRegistrationOtp({
    required String registrationToken,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<String?> requestForgotPasswordOtp(String email);
  Future<String> verifyForgotPasswordOtp({
    required String recoveryToken,
    required String otp,
  });
  Future<String> resendForgotPasswordOtp(String recoveryToken);
  Future<void> resetPasswordWithToken({
    required String resetSessionToken,
    required String newPassword,
  });
  Future<User> loginWithCollaboratorCredentials(String accessId, String password);
  Future<void> changeCollaboratorPassword({
    required String currentPassword,
    required String newPassword,
  });
}
