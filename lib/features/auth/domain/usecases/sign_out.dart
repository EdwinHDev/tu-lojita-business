import '../repositories/auth_repository.dart';

class SignOut {
  final AuthRepository repository;

  SignOut({required this.repository});

  Future<void> call() async {
    return await repository.signOut();
  }
}
