import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenStore {
  static const String _tokenKey = 'logisync.access_token';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> save(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> read() async {
    final secureValue = await _secureStorage.read(key: _tokenKey);
    if (secureValue != null && secureValue.trim().isNotEmpty) {
      return secureValue;
    }

    // One-time migration path for older app versions that stored token
    // in shared preferences.
    final preferences = await SharedPreferences.getInstance();
    final legacyValue = preferences.getString(_tokenKey);
    if (legacyValue != null && legacyValue.trim().isNotEmpty) {
      await _secureStorage.write(key: _tokenKey, value: legacyValue);
      await preferences.remove(_tokenKey);
      return legacyValue;
    }

    return null;
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: _tokenKey);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
  }
}
