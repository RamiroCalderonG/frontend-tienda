import '../models/user.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _api;
  UserService(this._api);

  Future<List<User>> listar() async {
    final data = await _api.get('/users') as List;
    return data.map((e) => User.fromJson(e)).toList();
  }

  Future<User> crear({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final data = await _api.post('/users', {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
    return User.fromJson(data);
  }

  Future<User> actualizar(String id, Map<String, dynamic> campos) async {
    final data = await _api.put('/users/$id', campos);
    return User.fromJson(data);
  }

  Future<void> eliminar(String id) async {
    await _api.delete('/users/$id');
  }
}
