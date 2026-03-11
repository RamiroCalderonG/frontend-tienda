import '../models/auth_tokens.dart';
import '../models/user.dart';
import '../models/store.dart';
import 'api_client.dart';
import 'storage_service.dart';

class AuthService {
  final ApiClient _api;
  final StorageService _storage;

  AuthService(this._api, this._storage);

  Future<void> login(String email, String password) async {
    final data = await _api.post(
      '/auth/login',
      {'email': email, 'password': password},
      auth: false,
    );
    final tokens = AuthTokens.fromJson(data);
    await _storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  Future<Map<String, dynamic>> getMe() async {
    final data = await _api.get('/auth/me');
    return {
      'user': User.fromJson(data['user']),
      'store': Store.fromJson(data['store']),
    };
  }

  Future<void> logout() async {
    await _storage.clearTokens();
  }
}
