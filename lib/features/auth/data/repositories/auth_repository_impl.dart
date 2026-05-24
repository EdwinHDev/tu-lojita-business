import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local_auth_data_source.dart';
import '../datasources/remote_auth_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final RemoteAuthDataSource _remoteDataSource;
  final LocalAuthDataSource _localDataSource;

  AuthRepositoryImpl({
    required RemoteAuthDataSource remoteDataSource,
    required LocalAuthDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<User> loginWithGoogle() async {
    final idToken = await _remoteDataSource.getGoogleIdToken();
    final data = await _remoteDataSource.loginWithBackend(idToken);

    final user = UserModel.fromJson(data['user']);
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;

    await _localDataSource.saveUser(user);
    await _localDataSource.saveAccessToken(accessToken);
    await _localDataSource.saveRefreshToken(refreshToken);

    return user;
  }

  @override
  Future<void> logout() async {
    await _localDataSource.clearAll();
  }

  @override
  Future<User?> getSession() async {
    return await _localDataSource.getUser();
  }

  @override
  Future<Map<String, dynamic>> checkCompanyStatus() async {
    return await _remoteDataSource.checkHasCompany();
  }

  @override
  Future<Map<String, dynamic>> checkStoreStatus() async {
    return await _remoteDataSource.checkHasStore();
  }

  @override
  Future<void> saveUser(User user) async {
    if (user is UserModel) {
      await _localDataSource.saveUser(user);
    } else {
      final model = UserModel(
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role,
        hasCompany: user.hasCompany,
        avatarUrl: user.avatarUrl,
      );
      await _localDataSource.saveUser(model);
    }
  }

  @override
  Future<User?> checkAuthStatus() async {
    try {
      final data = await _remoteDataSource.checkAuthStatus();
      final user = UserModel.fromJson(data['user']);
      await _localDataSource.saveUser(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User> updateProfile(String? identification, String? phone) async {
    final data = await _remoteDataSource.updateProfile(identification, phone);
    final user = UserModel.fromJson(data);
    await _localDataSource.saveUser(user);
    return user;
  }
}
