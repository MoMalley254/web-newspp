import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  // Use a 32-character secret key for AES-256
  static final _key = Key.fromUtf8('12345678901234567890123456789012');
  static final _iv = IV.fromLength(
    16,
  ); // Initialization Vector (can be randomized)

  static final _encrypter = Encrypter(AES(_key));

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();

    // final encryptedAccessToken = _encrypter.encrypt(accessToken, iv: _iv);

    // final encryptedRefreshToken = _encrypter.encrypt(refreshToken, iv: _iv);

    // await prefs.setString('access_token', encryptedAccessToken.base64);
    // await prefs.setString('refresh_token', encryptedRefreshToken.base64);
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<Map<String, String?>> getTokens() async {
    // await clearTokens();
    final prefs = await SharedPreferences.getInstance();

    final encryptedAccessToken = prefs.getString('access_token');
    final encryptedRefreshToken = prefs.getString('refresh_token');

    if (encryptedAccessToken == null || encryptedRefreshToken == null) {
      return {'access_token': null, 'refresh_token': null};
    }

    // final decryptedAccessToken = _encrypter.decrypt64(
    //   encryptedAccessToken,
    //   iv: _iv,
    // );
    // final decryptedRefreshToken = _encrypter.decrypt64(
    //   encryptedRefreshToken,
    //   iv: _iv,
    // );

    // return {
    //   'access_token': decryptedAccessToken,
    //   'refresh_token': decryptedRefreshToken,
    // };
    return {
      'access_token': encryptedAccessToken,
      'refresh_token': encryptedRefreshToken,
    };
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
