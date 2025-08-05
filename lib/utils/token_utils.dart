import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../pages/config.dart';

final _storage = FlutterSecureStorage();
const String apiBase = String.fromEnvironment('API_BASE', defaultValue: baseUrl);

Future<String?> getValidAccessToken() async {
  final accessToken = await _storage.read(key: 'access_token');
  final expStr = await _storage.read(key: 'access_token_exp');

  if (accessToken == null || expStr == null) return null;

  final expiry = DateTime.tryParse(expStr);
  final now = DateTime.now();

  // 아직 유효하면 그대로 반환
  if (expiry != null && expiry.isAfter(now)) return accessToken;

  // 만료된 경우 refresh 시도
  final refreshToken = await _storage.read(key: 'refresh_token');
  if (refreshToken == null) return null;

  final response = await http.post(
    Uri.parse('$apiBase/api/auth/refresh'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'refresh_token': refreshToken}),
  );

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    final newAccess = json['token'];
    final newRefresh = json['refresh_token'];
    final expiresIn = json['expires_in'];

    if (newAccess != null) await _storage.write(key: 'access_token', value: newAccess);
    if (newRefresh != null) await _storage.write(key: 'refresh_token', value: newRefresh);
    if (expiresIn != null) {
      final newExpiry = DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String();
      await _storage.write(key: 'access_token_exp', value: newExpiry);
    }

    return newAccess;
  }

  return null;
}
