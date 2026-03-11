import '../models/venta.dart';
import 'api_client.dart';

class VentaService {
  final ApiClient _api;
  VentaService(this._api);

  Future<Venta> crear({
    required String metodoPago,
    required List<TicketItem> items,
  }) async {
    final data = await _api.post('/ventas', {
      'metodo_pago': metodoPago,
      'items': items
          .map((i) => {'producto_id': i.productoId, 'cantidad': i.cantidad})
          .toList(),
    });
    return Venta.fromJson(data);
  }

  Future<List<Venta>> listar() async {
    final data = await _api.get('/ventas') as List;
    return data.map((e) => Venta.fromJson(e)).toList();
  }
}
