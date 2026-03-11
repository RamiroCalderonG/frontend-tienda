import '../models/reporte.dart';
import 'api_client.dart';

class ReporteService {
  final ApiClient _api;
  ReporteService(this._api);

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<ResumenPeriodo> getResumen(DateTime inicio, DateTime fin) async {
    final data = await _api.get(
      '/reportes/resumen?fecha_inicio=${_fmt(inicio)}&fecha_fin=${_fmt(fin)}',
    );
    return ResumenPeriodo.fromJson(data);
  }

  Future<List<VentaDia>> getVentasPorDia(DateTime inicio, DateTime fin) async {
    final data = await _api.get(
      '/reportes/ventas-por-dia?fecha_inicio=${_fmt(inicio)}&fecha_fin=${_fmt(fin)}',
    ) as List;
    return data.map((e) => VentaDia.fromJson(e)).toList();
  }

  Future<List<ProductoTop>> getProductosTop(DateTime inicio, DateTime fin, {int limit = 10}) async {
    final data = await _api.get(
      '/reportes/productos-top?fecha_inicio=${_fmt(inicio)}&fecha_fin=${_fmt(fin)}&limit=$limit',
    ) as List;
    return data.map((e) => ProductoTop.fromJson(e)).toList();
  }

  Future<List<ProductoStockBajo>> getStockBajo() async {
    final data = await _api.get('/reportes/stock-bajo') as List;
    return data.map((e) => ProductoStockBajo.fromJson(e)).toList();
  }

  Future<MapaVentas> getMapaVentas(DateTime inicio, DateTime fin) async {
    final data = await _api.get(
      '/reportes/mapa-ventas?fecha_inicio=${_fmt(inicio)}&fecha_fin=${_fmt(fin)}',
    );
    return MapaVentas.fromJson(data);
  }
}
