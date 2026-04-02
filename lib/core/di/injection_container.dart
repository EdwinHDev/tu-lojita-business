import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/onboarding/data/datasources/onboarding_local_datasource.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/domain/usecases/get_onboarding_items.dart';
import '../../features/auth/data/datasources/google_auth_datasource.dart';
import '../../features/auth/data/datasources/backend_auth_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/repositories/backend_auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/backend_auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/authenticate_with_backend.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../config/env_config.dart';
import '../services/token_storage_service.dart';

final Map<Type, dynamic> _services = {};

T sl<T>() {
  final service = _services[T];
  if (service == null) {
    throw Exception('Service of type $T is not registered');
  }
  return service as T;
}

Future<void> initializeDependencies() async {
  _services[OnboardingLocalDataSource] = OnboardingLocalDataSourceImpl();

  _services[OnboardingRepository] = OnboardingRepositoryImpl(
    localDataSource: sl<OnboardingLocalDataSource>(),
  );

  _services[GetOnboardingItems] = GetOnboardingItems(
    repository: sl<OnboardingRepository>(),
  );

  final googleSignIn = GoogleSignIn.instance;
  await googleSignIn.initialize(
    serverClientId: EnvConfig.googleServerClientId,
  );
  _services[GoogleSignIn] = googleSignIn;

  _services[GoogleAuthDataSource] = GoogleAuthDataSourceImpl(
    googleSignIn: sl<GoogleSignIn>(),
  );

  _services[AuthRepository] = AuthRepositoryImpl(
    dataSource: sl<GoogleAuthDataSource>(),
  );

  _services[SignInWithGoogle] = SignInWithGoogle(
    repository: sl<AuthRepository>(),
  );

  _services[SignOut] = SignOut(
    repository: sl<AuthRepository>(),
  );

  _services[http.Client] = http.Client();

  _services[FlutterSecureStorage] = const FlutterSecureStorage();

  _services[TokenStorageService] = TokenStorageService(
    secureStorage: sl<FlutterSecureStorage>(),
  );

  _services[BackendAuthDataSource] = BackendAuthDataSourceImpl(
    httpClient: sl<http.Client>(),
  );

  _services[BackendAuthRepository] = BackendAuthRepositoryImpl(
    dataSource: sl<BackendAuthDataSource>(),
    tokenStorage: sl<TokenStorageService>(),
  );

  _services[AuthenticateWithBackend] = AuthenticateWithBackend(
    repository: sl<BackendAuthRepository>(),
  );
}
