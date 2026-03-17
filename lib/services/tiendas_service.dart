import '../models/tienda.dart';
import 'api_client.dart';

class TiendasService {
  final ApiClient _api;
  TiendasService(this._api);

  Future<List<Tienda>> listar() async {
    final data = await _api.get('/stores');
    return (data as List).map((j) => Tienda.fromJson(j)).toList();
  }

  Future<Tienda> crear({
    required String storeName,
    String? storeAddress,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
  }) async {
    final data = await _api.post('/stores', {
      'store_name': storeName,
      if (storeAddress != null && storeAddress.isNotEmpty)
        'store_address': storeAddress,
      'admin_name': adminName,
      'admin_email': adminEmail,
      'admin_password': adminPassword,
    });
    return Tienda.fromJson(data);
  }

  Future<void> eliminar(String storeId) async {
    await _api.delete('/stores/$storeId');
  }
}
