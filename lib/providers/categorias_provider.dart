import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/categoria.dart';
import '../services/categoria_service.dart';
import 'auth_provider.dart';

final categoriaServiceProvider = Provider<CategoriaService>((ref) {
  return CategoriaService(ref.watch(apiClientProvider));
});

class CategoriasNotifier extends AsyncNotifier<List<Categoria>> {
  @override
  Future<List<Categoria>> build() => _load();

  Future<List<Categoria>> _load() =>
      ref.read(categoriaServiceProvider).listar();

  Future<void> crear(String nombre) async {
    final nueva = await ref.read(categoriaServiceProvider).crear(nombre);
    state = AsyncValue.data([...state.valueOrNull ?? [], nueva]);
  }

  Future<void> eliminar(String id) async {
    await ref.read(categoriaServiceProvider).eliminar(id);
    state = AsyncValue.data(
      state.valueOrNull?.where((c) => c.id != id).toList() ?? [],
    );
  }
}

final categoriasProvider =
    AsyncNotifierProvider<CategoriasNotifier, List<Categoria>>(
        CategoriasNotifier.new);
