import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/google_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final GoogleAuthDataSource dataSource;

  AuthRepositoryImpl({required this.dataSource});

  @override
  Future<UserEntity?> signInWithGoogle() async {
    return await dataSource.signInWithGoogle();
  }

  @override
  Future<void> signOut() async {
    return await dataSource.signOut();
  }
}
