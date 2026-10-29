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

class AccountSuspendedException extends AuthException {
  final String? suspendedUntil;
  final String? reason;
  final bool isPermanent;

  AccountSuspendedException({
    String message = 'Tu cuenta está suspendida.',
    this.suspendedUntil,
    this.reason,
    this.isPermanent = false,
  }) : super(message, code: isPermanent ? 'ACCOUNT_BANNED' : 'ACCOUNT_SUSPENDED');
}
