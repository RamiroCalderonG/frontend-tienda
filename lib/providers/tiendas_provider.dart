import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tienda.dart';
import '../services/tiendas_service.dart';
import 'auth_provider.dart';

final tiendasServiceProvider = Provider<TiendasService>((ref) {
  return TiendasService(ref.watch(apiClientProvider));
});

class TiendasNotifier extends AsyncNotifier<List<Tienda>> {
  @override
  Future<List<Tienda>> build() => _load();

  Future<List<Tienda>> _load() {
    return ref.read(tiendasServiceProvider).listar();
  }

  Future<void> crear({
    required String storeName,
    String? storeAddress,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
  }) async {
    final tienda = await ref.read(tiendasServiceProvider).crear(
          storeName: storeName,
          storeAddress: storeAddress,
          adminName: adminName,
          adminEmail: adminEmail,
          adminPassword: adminPassword,
        );
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([tienda, ...current]);
  }

  Future<void> eliminar(String storeId) async {
    await ref.read(tiendasServiceProvider).eliminar(storeId);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((t) => t.id != storeId).toList());
  }
}

final tiendasProvider =
    AsyncNotifierProvider<TiendasNotifier, List<Tienda>>(TiendasNotifier.new);
