import '../models/categoria.dart';
import 'api_client.dart';

class CategoriaService {
  final ApiClient _api;
  CategoriaService(this._api);

  Future<List<Categoria>> listar() async {
    final data = await _api.get('/categorias') as List;
    return data.map((e) => Categoria.fromJson(e)).toList();
  }

  Future<Categoria> crear(String nombre) async {
    final data = await _api.post('/categorias', {'nombre': nombre});
    return Categoria.fromJson(data);
  }

  Future<void> eliminar(String id) async {
    await _api.delete('/categorias/$id');
  }
}
