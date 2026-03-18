import '../models/movimiento.dart';
import 'api_client.dart';

class InventarioService {
  final ApiClient _api;
  InventarioService(this._api);

  Future<Movimiento> restock({
    required String productoId,
    required int cantidad,
    double? costoUnitario,
    bool actualizarCosto = false,
    String? fechaCaducidad,
    String? notas,
  }) async {
    final data = await _api.post('/inventario/restock', {
      'producto_id': productoId,
      'cantidad': cantidad,
      if (costoUnitario != null) 'costo_unitario': costoUnitario,
      'actualizar_costo': actualizarCosto,
      if (fechaCaducidad != null) 'fecha_caducidad': fechaCaducidad,
      if (notas != null && notas.isNotEmpty) 'notas': notas,
    });
    return Movimiento.fromJson(data);
  }

  Future<Movimiento> ajuste({
    required String productoId,
    required int cantidad,
    required String tipo,
    String? notas,
  }) async {
    final data = await _api.post('/inventario/ajuste', {
      'producto_id': productoId,
      'cantidad': cantidad,
      'tipo': tipo,
      if (notas != null && notas.isNotEmpty) 'notas': notas,
    });
    return Movimiento.fromJson(data);
  }

  Future<List<Movimiento>> listarMovimientos({String? productoId, int limit = 50}) async {
    final params = '?limit=$limit${productoId != null ? '&producto_id=$productoId' : ''}';
    final data = await _api.get('/inventario/movimientos$params') as List;
    return data.map((e) => Movimiento.fromJson(e)).toList();
  }

  Future<List<LoteVencimiento>> listarVencimientos({int dias = 3}) async {
    final data = await _api.get('/inventario/vencimientos?dias=$dias') as List;
    return data.map((e) => LoteVencimiento.fromJson(e)).toList();
  }
}
