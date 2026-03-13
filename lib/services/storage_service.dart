import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'storage_impl_web.dart' if (dart.library.io) 'storage_impl_stub.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  // En web usamos localStorage directo (sin plugins) porque flutter_secure_storage
  // requiere HTTPS (Web Crypto API) y no funciona por HTTP en IPs locales.

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb) {
      webStorageSet(_keyAccessToken, accessToken);
      webStorageSet(_keyRefreshToken, refreshToken);
    } else {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) return webStorageGet(_keyAccessToken);
    return _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) return webStorageGet(_keyRefreshToken);
    return _storage.read(key: _keyRefreshToken);
  }

  Future<void> clearTokens() async {
    if (kIsWeb) {
      webStorageRemove(_keyAccessToken);
      webStorageRemove(_keyRefreshToken);
    } else {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
    }
  }
}
