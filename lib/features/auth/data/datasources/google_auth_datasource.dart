import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user_entity.dart';

abstract class GoogleAuthDataSource {
  Future<UserEntity?> signInWithGoogle();
  Future<void> signOut();
}

class GoogleAuthDataSourceImpl implements GoogleAuthDataSource {
  final GoogleSignIn _googleSignIn;

  GoogleAuthDataSourceImpl({required GoogleSignIn googleSignIn})
      : _googleSignIn = googleSignIn;

  @override
  Future<UserEntity?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication auth = account.authentication;

      return UserEntity(
        id: account.id,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        idToken: auth.idToken,
      );
    } catch (e) {
      throw Exception('Error signing in with Google: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }
}
