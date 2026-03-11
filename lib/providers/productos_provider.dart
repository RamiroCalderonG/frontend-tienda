import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/producto.dart';
import '../services/producto_service.dart';
import 'auth_provider.dart';

final productoServiceProvider = Provider<ProductoService>((ref) {
  return ProductoService(ref.watch(apiClientProvider));
});

class ProductosNotifier extends AsyncNotifier<List<Producto>> {
  @override
  Future<List<Producto>> build() => _load();

  Future<List<Producto>> _load() =>
      ref.read(productoServiceProvider).listar(soloActivos: false);

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> crear(Map<String, dynamic> body) async {
    final nuevo = await ref.read(productoServiceProvider).crear(body);
    state = AsyncValue.data([...state.valueOrNull ?? [], nuevo]);
  }

  Future<void> actualizar(String id, Map<String, dynamic> body) async {
    final actualizado =
        await ref.read(productoServiceProvider).actualizar(id, body);
    state = AsyncValue.data(
      state.valueOrNull
              ?.map((p) => p.id == id ? actualizado : p)
              .toList() ??
          [],
    );
  }

  Future<void> eliminar(String id) async {
    await ref.read(productoServiceProvider).eliminar(id);
    state = AsyncValue.data(
      state.valueOrNull?.where((p) => p.id != id).toList() ?? [],
    );
  }
}

final productosProvider =
    AsyncNotifierProvider<ProductosNotifier, List<Producto>>(
        ProductosNotifier.new);
