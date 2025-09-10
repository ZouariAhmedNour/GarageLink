// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../global.dart';

class ApiClient {
  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Récupérer le token JWT stocké (après login)
  Future<String?> getToken() async => await _storage.read(key: 'jwt_token');

  Future<http.Response> post(String path, {Map<String, dynamic>? body, Map<String,String>? headers}) async {
    final uri = Uri.parse('$UrlApi$path');
    final token = await getToken();
    final allHeaders = <String,String>{ 'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token',};
    if (headers != null) allHeaders.addAll(headers);
    return _client.post(uri, headers: allHeaders, body: body != null ? json.encode(body) : null);
  }

  Future<http.Response> put(String path, {Map<String, dynamic>? body, Map<String,String>? headers}) async {
    final uri = Uri.parse('$UrlApi$path');
    final token = await getToken();
    final allHeaders = <String,String>{ 'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token',};
    if (headers != null) allHeaders.addAll(headers);
    return _client.put(uri, headers: allHeaders, body: body != null ? json.encode(body) : null);
  }

  Future<http.Response> get(String path, {Map<String,String>? headers}) async {
    final uri = Uri.parse('$UrlApi$path');
    final token = await getToken();
    final allHeaders = <String,String>{ if (token != null) 'Authorization': 'Bearer $token',};
    if (headers != null) allHeaders.addAll(headers);
    return _client.get(uri, headers: allHeaders);
  }

  Future<void> saveToken(String token) => _storage.write(key: 'jwt_token', value: token);
  Future<void> deleteToken() => _storage.delete(key: 'jwt_token');
}
