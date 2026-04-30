import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> loginWithGoogle();
  Future<void> logout();
  Future<User?> getSession();
  Future<Map<String, dynamic>> checkCompanyStatus();
  Future<Map<String, dynamic>> checkStoreStatus();
  Future<void> saveUser(User user);
  Future<User?> checkAuthStatus();
}
