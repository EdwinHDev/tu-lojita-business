import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

abstract class LocalAuthDataSource {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<void> saveRefreshToken(String token);
  Future<String?> getRefreshToken();
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  Future<void> clearAll();
  Future<void> savePendingRegistration({
    required String registrationToken,
    required String email,
    DateTime? expiresAt,
  });
  Future<Map<String, dynamic>?> getPendingRegistration();
  Future<void> clearPendingRegistration();
  Future<void> ensureCleanInstall();
}

class LocalAuthDataSourceImpl implements LocalAuthDataSource {
  final FlutterSecureStorage _storage;

  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  UserModel? _cachedUser;

  LocalAuthDataSourceImpl(this._storage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';
  static const _firstRunKey = 'business_app_has_run_before';

  @override
  Future<void> ensureCleanInstall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRunBefore = prefs.getBool(_firstRunKey) ?? false;
      if (!hasRunBefore) {
        await _storage.deleteAll();
        await prefs.remove(_accessTokenKey);
        await prefs.remove(_refreshTokenKey);
        await prefs.remove(_userKey);
        await prefs.setBool(_firstRunKey, true);
        _cachedAccessToken = null;
        _cachedRefreshToken = null;
        _cachedUser = null;
      }
    } catch (_) {}
  }

  @override
  Future<void> saveAccessToken(String token) async {
    _cachedAccessToken = token;
    try {
      await _storage.write(key: _accessTokenKey, value: token);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, token);
    } catch (_) {}
  }

  @override
  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null && _cachedAccessToken!.isNotEmpty) {
      return _cachedAccessToken;
    }
    try {
      final token = await _storage.read(key: _accessTokenKey);
      if (token != null && token.isNotEmpty) {
        _cachedAccessToken = token;
        return token;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);
      if (token != null && token.isNotEmpty) {
        _cachedAccessToken = token;
        return token;
      }
    } catch (_) {}

    return _cachedAccessToken;
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    _cachedRefreshToken = token;
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshTokenKey, token);
    } catch (_) {}
  }

  @override
  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null && _cachedRefreshToken!.isNotEmpty) {
      return _cachedRefreshToken;
    }
    try {
      final token = await _storage.read(key: _refreshTokenKey);
      if (token != null && token.isNotEmpty) {
        _cachedRefreshToken = token;
        return token;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_refreshTokenKey);
      if (token != null && token.isNotEmpty) {
        _cachedRefreshToken = token;
        return token;
      }
    } catch (_) {}

    return _cachedRefreshToken;
  }

  @override
  Future<void> saveUser(UserModel user) async {
    _cachedUser = user;
    final userJson = jsonEncode(user.toJson());
    try {
      await _storage.write(key: _userKey, value: userJson);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, userJson);
    } catch (_) {}
  }

  @override
  Future<UserModel?> getUser() async {
    if (_cachedUser != null) return _cachedUser;
    try {
      final data = await _storage.read(key: _userKey);
      if (data != null && data.isNotEmpty) {
        _cachedUser = UserModel.fromJson(jsonDecode(data));
        return _cachedUser;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_userKey);
      if (data != null && data.isNotEmpty) {
        _cachedUser = UserModel.fromJson(jsonDecode(data));
        return _cachedUser;
      }
    } catch (_) {}

    return _cachedUser;
  }

  @override
  Future<void> clearAll() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedUser = null;
    try {
      await _storage.deleteAll();
    } catch (_) {}
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userKey);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userKey);
    } catch (_) {}
  }
  static const _pendingRegTokenKey = 'pending_reg_token';
  static const _pendingRegEmailKey = 'pending_reg_email';
  static const _pendingRegExpiresAtKey = 'pending_reg_expires_at';

  @override
  Future<void> savePendingRegistration({
    required String registrationToken,
    required String email,
    DateTime? expiresAt,
  }) async {
    final exp = expiresAt ?? DateTime.now().add(const Duration(minutes: 10));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingRegTokenKey, registrationToken);
      await prefs.setString(_pendingRegEmailKey, email);
      await prefs.setString(_pendingRegExpiresAtKey, exp.toIso8601String());
    } catch (_) {}
  }

  @override
  Future<Map<String, dynamic>?> getPendingRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_pendingRegTokenKey);
      final email = prefs.getString(_pendingRegEmailKey);
      final expiresAtStr = prefs.getString(_pendingRegExpiresAtKey);

      if (token == null || token.isEmpty || email == null || expiresAtStr == null) {
        return null;
      }

      final expiresAt = DateTime.tryParse(expiresAtStr);
      if (expiresAt == null || expiresAt.isBefore(DateTime.now())) {
        await clearPendingRegistration();
        return null;
      }

      return {
        'registrationToken': token,
        'email': email,
        'expiresAt': expiresAt,
      };
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearPendingRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingRegTokenKey);
      await prefs.remove(_pendingRegEmailKey);
      await prefs.remove(_pendingRegExpiresAtKey);
    } catch (_) {}
  }
}
