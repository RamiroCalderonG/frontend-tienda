import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider<UserService>(
  (ref) => UserService(ref.read(apiClientProvider)),
);

class UsersNotifier extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() => ref.read(userServiceProvider).listar();

  Future<void> crear({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final nuevo = await ref.read(userServiceProvider).crear(
          name: name,
          email: email,
          password: password,
          role: role,
        );
    state = AsyncData([...state.valueOrNull ?? [], nuevo]);
  }

  Future<void> actualizar(String id, Map<String, dynamic> campos) async {
    final actualizado = await ref.read(userServiceProvider).actualizar(id, campos);
    state = AsyncData(
      (state.valueOrNull ?? []).map((u) => u.id == id ? actualizado : u).toList(),
    );
  }

  Future<void> eliminar(String id) async {
    await ref.read(userServiceProvider).eliminar(id);
    state = AsyncData(
      (state.valueOrNull ?? []).where((u) => u.id != id).toList(),
    );
  }
}

final usersProvider = AsyncNotifierProvider<UsersNotifier, List<User>>(
  UsersNotifier.new,
);
