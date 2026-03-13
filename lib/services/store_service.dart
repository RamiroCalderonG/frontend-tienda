import '../models/store.dart';
import '../models/store_config.dart';
import 'api_client.dart';

class StoreService {
  final ApiClient _api;
  StoreService(this._api);

  Future<Store> updateConfig(StoreConfig config) async {
    final data = await _api.put('/stores/config', config.toMap());
    return Store.fromJson(data);
  }
}
