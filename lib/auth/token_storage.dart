import 'package:hive_flutter/hive_flutter.dart';

class TokenStorage {
  static final TokenStorage instance = TokenStorage._();
  TokenStorage._();

  Box get _box => Hive.box('chat_app');

  Future<void> saveTokens(
      {required String accessToken, required String refreshToken}) async {
    await _box.put('token', accessToken);
    await _box.put('refreshToken', refreshToken);
  }

  String? get accessToken => _box.get('token');
  String? get refreshToken => _box.get('refreshToken');

  Future<void> setAccessToken(String token) async => _box.put('token', token);

  Future<void> clear() async => _box.clear();
}
