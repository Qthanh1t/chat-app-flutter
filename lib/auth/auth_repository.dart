import 'package:dio/dio.dart';
import '../service/api_client.dart';
import 'token_storage.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<void> login(
      {required String username, required String password}) async {
    final res = await _dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });

    final access = res.data['accessToken'] as String;
    final refresh = res.data['refreshToken'] as String;
    await TokenStorage.instance
        .saveTokens(accessToken: access, refreshToken: refresh);
  }

  Future<void> logout() async {
    final rt = TokenStorage.instance.refreshToken;
    if (rt != null) {
      try {
        await _dio.post('/auth/logout', data: {'refreshToken': rt});
      } catch (_) {}
    }
    await TokenStorage.instance.clear();
  }

  Future<String?> refreshAccessToken() async {
    final rt = TokenStorage.instance.refreshToken;
    if (rt == null) return null;

    final res =
        await _dio.post('/auth/refreshtoken', data: {'refreshToken': rt});
    final newAccess = res.data['accessToken'] as String;
    await TokenStorage.instance.setAccessToken(newAccess);
    return newAccess;
  }
}
