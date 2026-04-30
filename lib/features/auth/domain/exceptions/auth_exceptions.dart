class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message ${code != null ? '($code)' : ''}';
}

class TokenExpiredException extends AuthException {
  TokenExpiredException([super.message = 'Session has expired']);
}

class GoogleSignInCancelledException extends AuthException {
  GoogleSignInCancelledException([super.message = 'Google sign in was cancelled']);
}

class BackendAuthenticationException extends AuthException {
  BackendAuthenticationException(super.message);
}
