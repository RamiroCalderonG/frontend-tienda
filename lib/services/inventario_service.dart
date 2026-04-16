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

  Future<ValorStock> fetchValorStock() async {
    final data = await _api.get('/inventario/valor-stock') as Map<String, dynamic>;
    return ValorStock.fromJson(data);
  }
}

class ValorStock {
  final double totalInvertido;
  final double totalValorVenta;

  const ValorStock({required this.totalInvertido, required this.totalValorVenta});

  factory ValorStock.fromJson(Map<String, dynamic> j) => ValorStock(
        totalInvertido: (j['total_invertido'] as num).toDouble(),
        totalValorVenta: (j['total_valor_venta'] as num).toDouble(),
      );
}
