import '../models/promocion.dart';
import 'api_client.dart';

class PromocionService {
  final ApiClient _api;
  PromocionService(this._api);

  Future<List<Promocion>> listar() async {
    final data = await _api.get('/promociones') as List;
    return data.map((e) => Promocion.fromJson(e)).toList();
  }

  Future<Promocion> crear({
    required String productoId,
    required int cantidadRequerida,
    required double precioPromocion,
  }) async {
    final data = await _api.post('/promociones', {
      'producto_id': productoId,
      'cantidad_requerida': cantidadRequerida,
      'precio_promocion': precioPromocion,
    });
    return Promocion.fromJson(data);
  }

  Future<void> eliminar(int id) async {
    await _api.delete('/promociones/$id');
  }
}
