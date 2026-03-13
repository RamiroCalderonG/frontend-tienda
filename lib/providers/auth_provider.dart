import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/store.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

// Providers de servicios
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(storage);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final api = ref.watch(apiClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthService(api, storage);
});

// Estado de autenticación
class AuthState {
  final User? user;
  final Store? store;
  final bool loading;
  final String? error;

  const AuthState({
    this.user,
    this.store,
    this.loading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    Store? store,
    bool? loading,
    String? error,
  }) =>
      AuthState(
        user: user ?? this.user,
        store: store ?? this.store,
        loading: loading ?? this.loading,
        error: error ?? this.error,
      );
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Intenta restaurar sesión al iniciar
    return await _tryRestoreSession();
  }

  Future<AuthState> _tryRestoreSession() async {
    final storage = ref.read(storageServiceProvider);
    final token = await storage.getAccessToken();
    if (token == null) return const AuthState();

    try {
      final authService = ref.read(authServiceProvider);
      final me = await authService.getMe();
      return AuthState(user: me['user'], store: me['store']);
    } catch (_) {
      await storage.clearTokens();
      return const AuthState();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.login(email, password);
      final me = await authService.getMe();
      return AuthState(user: me['user'], store: me['store']);
    });
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = const AsyncValue.data(AuthState());
  }

  void updateStore(Store store) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(store: store));
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
