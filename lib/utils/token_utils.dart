import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';

final _storage = const FlutterSecureStorage();
const String apiBase = String.fromEnvironment('API_BASE', defaultValue: baseUrl);

const _expiryBuffer = Duration(seconds: 30);
Future<String?>? _refreshFuture; // 동시성 락

Future<String?> getValidAccessToken() async {
  final accessToken = await _storage.read(key: 'access_token');
  final expStr = await _storage.read(key: 'access_token_exp');

  // accessToken이 있고 아직 유효하면 바로 반환
  if (accessToken != null) {
    final valid = !_isTokenExpired(accessToken, expStr);
    if (valid) return accessToken;
  }

  // 리프레시 시작 (동시성 방지)
  if (_refreshFuture != null) return await _refreshFuture;
  _refreshFuture = _doRefresh();
  try {
    return await _refreshFuture;
  } finally {
    _refreshFuture = null;
  }
}

bool _isTokenExpired(String? accessToken, String? expStr) {
  final now = DateTime.now();
  // 1) 저장된 expiry가 있으면 사용 (버퍼 적용)
  if (expStr != null) {
    final parsed = DateTime.tryParse(expStr);
    if (parsed != null) {
      return !parsed.isAfter(now.add(_expiryBuffer)); // true = 만료
    }
  }

  // 2) 저장된 expiry가 없으면 JWT의 exp 파싱 시도
  if (accessToken != null) {
    final jwtExp = _getJwtExpiry(accessToken);
    if (jwtExp != null) {
      return !jwtExp.isAfter(now.add(_expiryBuffer));
    }
  }

  // 3) 파싱 실패하면 만료로 처리
  return true;
}

DateTime? _getJwtExpiry(String jwt) {
  try {
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    final payload = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    final Map<String, dynamic> map = jsonDecode(decoded);
    final exp = map['exp'];
    if (exp == null) return null;
    // exp는 보통 unix seconds
    final int seconds = (exp is int) ? exp : int.tryParse(exp.toString()) ?? 0;
    if (seconds <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  } catch (_) {
    return null;
  }
}

Future<String?> _doRefresh() async {
  try {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) return null;

    final resp = await http.post(
      Uri.parse('$apiBase/api/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (resp.statusCode != 200) {
      // 필요 시 토큰 삭제(로그아웃 처리) 또는 별도 처리
      // await _clearAllTokens();
      return null;
    }

    final Map<String, dynamic> body = jsonDecode(resp.body);
    final newAccess = body['token'] ?? body['access_token'];
    final newRefresh = body['refresh_token'] ?? body['refreshToken'];
    final expiresInRaw = body['expires_in'] ?? body['expiresIn'] ?? body['expires_at'];

    if (newAccess != null) {
      await _storage.write(key: 'access_token', value: newAccess);
    }
    if (newRefresh != null) {
      await _storage.write(key: 'refresh_token', value: newRefresh);
    }

    // expiresIn 처리: seconds 형태면 int로, expires_at이면 ISO 또는 timestamp 처리
    DateTime? newExpiry;
    if (expiresInRaw != null) {
      // 숫자(seconds)
      final secs = int.tryParse(expiresInRaw.toString());
      if (secs != null) {
        newExpiry = DateTime.now().add(Duration(seconds: secs));
      } else {
        // 혹시 ISO 문자열로 내려오는 경우
        final maybeIso = DateTime.tryParse(expiresInRaw.toString());
        if (maybeIso != null) newExpiry = maybeIso;
      }
    } else {
      // 서버가 expires 정보를 안줄 경우, JWT에서 파싱 시도
      newExpiry = _getJwtExpiry(newAccess ?? '');
    }

    if (newExpiry != null) {
      // ISO 저장
      await _storage.write(key: 'access_token_exp', value: newExpiry.toIso8601String());
    }

    return newAccess;
  } catch (e) {
    // 네트워크/파싱 예외 발생 시 null 반환
    return null;
  }
}

Future<void> _clearAllTokens() async {
  await _storage.delete(key: 'access_token');
  await _storage.delete(key: 'refresh_token');
  await _storage.delete(key: 'access_token_exp');
}
