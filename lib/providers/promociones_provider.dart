import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/promocion.dart';
import '../services/promocion_service.dart';
import 'auth_provider.dart';

final promocionServiceProvider = Provider<PromocionService>((ref) {
  return PromocionService(ref.watch(apiClientProvider));
});

class PromocionesNotifier extends AsyncNotifier<List<Promocion>> {
  @override
  Future<List<Promocion>> build() => _load();

  Future<List<Promocion>> _load() =>
      ref.read(promocionServiceProvider).listar();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> crear({
    required String productoId,
    required int cantidadRequerida,
    required double precioPromocion,
  }) async {
    final nueva = await ref.read(promocionServiceProvider).crear(
          productoId: productoId,
          cantidadRequerida: cantidadRequerida,
          precioPromocion: precioPromocion,
        );
    state = AsyncValue.data([...state.valueOrNull ?? [], nueva]);
  }

  Future<void> eliminar(int id) async {
    await ref.read(promocionServiceProvider).eliminar(id);
    state = AsyncValue.data(
      state.valueOrNull?.where((p) => p.id != id).toList() ?? [],
    );
  }
}

final promocionesProvider =
    AsyncNotifierProvider<PromocionesNotifier, List<Promocion>>(
        PromocionesNotifier.new);
