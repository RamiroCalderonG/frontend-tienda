import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  static String get baseUrl {
    // Permite sobreescribir con --dart-define=API_URL=...
    const apiUrl = String.fromEnvironment('API_URL');
    if (apiUrl.isNotEmpty) return apiUrl;

    if (kIsWeb) {
      final port = Uri.base.port;
      // En producción (puerto 80/443) usa Nginx /api
      if (port == 80 || port == 443 || port == 0) {
        return '${Uri.base.scheme}://${Uri.base.host}/api';
      }
      // En desarrollo local apunta directo al backend
      return 'http://${Uri.base.host}:8000';
    }
    // Mobile producción
    return 'http://192.168.10.41/api';
  }

  final StorageService _storage;

  ApiClient(this._storage);

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _storage.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path) async {
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _handleResponse(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _handleResponse(res);
  }

  dynamic _handleResponse(http.Response res) {
    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body.isEmpty) return null;
      return jsonDecode(body);
    }
    String message = 'Error ${res.statusCode}';
    try {
      final json = jsonDecode(body);
      message = json['detail'] ?? message;
    } catch (_) {}
    throw ApiException(res.statusCode, message);
  }
}
