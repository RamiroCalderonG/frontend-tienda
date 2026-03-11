import '../models/producto.dart';
import 'api_client.dart';

class ProductoService {
  final ApiClient _api;
  ProductoService(this._api);

  Future<List<Producto>> listar({String? categoriaId, bool soloActivos = true}) async {
    String path = '/productos?solo_activos=$soloActivos';
    if (categoriaId != null) path += '&categoria_id=$categoriaId';
    final data = await _api.get(path) as List;
    return data.map((e) => Producto.fromJson(e)).toList();
  }

  Future<Producto> crear(Map<String, dynamic> body) async {
    final data = await _api.post('/productos', body);
    return Producto.fromJson(data);
  }

  Future<Producto> actualizar(String id, Map<String, dynamic> body) async {
    final data = await _api.put('/productos/$id', body);
    return Producto.fromJson(data);
  }

  Future<void> eliminar(String id) async {
    await _api.delete('/productos/$id');
  }
}
