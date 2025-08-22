import 'package:dio/dio.dart';
import 'package:newspp_desktop_backend/services/toast_service.dart';
import 'package:newspp_desktop_backend/services/tokens_service.dart';

class DioClient {
  final tokenService = TokenStorage();
  final toastService = ToastService();

  static const String baseUrl = 'http://localhost:3000';
  static const String refreshUrl = '$baseUrl/admin/refresh';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 600,
    ),
  );

  static void init() {
  DioClient(); // This will trigger the factory constructor
}


  static Dio get instance => _dio;

  static final DioClient _singleton = DioClient._internal();

  factory DioClient() {
    return _singleton;
  }

  DioClient._internal() {
    _dio.interceptors.clear(); // In case it's reinitialized
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await _singleton.getAToken();
          if (accessToken.isNotEmpty) {
            options.headers['authorization'] = 'Bearer $accessToken';
          }
          print('➡️ Request: ${options.method} ${options.uri}');
          print('Sending token: Bearer $accessToken');
          return handler.next(options);
        },

        onResponse: (response, handler) {
          print('✅ Response: ${response.statusCode}');
          return handler.next(response);
        },

        onError: (DioException error, handler) async {
          print('❌ Error: ${error.response?.statusCode} ${error.message}');

          if (error.response?.statusCode == 401) {
            // Attempt to refresh token
            final refreshed = await _singleton._refreshToken();

            if (refreshed) {
              // Retry the original request with new token
              final newAccessToken = await _singleton.getAToken();

              final requestOptions = error.requestOptions;
              requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

              try {
                final clonedResponse = await _dio.fetch(requestOptions);
                return handler.resolve(clonedResponse);
              } catch (retryError) {
                print('Retry failed: $retryError');
                return handler.reject(DioException(
                  requestOptions: requestOptions,
                  error: retryError,
                  type: DioExceptionType.badResponse,
                ));
              }
            } else {
              _singleton.toastService.showErrortoast('Session expired. Please log in again.');
              // You can add redirect to login here if needed
              return handler.reject(error);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Get access token from secure storage
  Future<String> getAToken() async {
    try {
      Map<String, dynamic> tokens = await tokenService.getTokens();
      return tokens['access_token'] ?? '';
    } catch (e) {
      print('A token error: $e');
      toastService.showErrortoast(e.toString());
      return '';
    }
  }

  /// Get refresh token from secure storage
  Future<String> getRToken() async {
    try {
      Map<String, dynamic> tokens = await tokenService.getTokens();
      return tokens['refresh_token'] ?? '';
    } catch (e) {
      print('R token error: $e');
      toastService.showErrortoast(e.toString());
      return '';
    }
  }

  /// Try to refresh the access token
  Future<bool> _refreshToken() async {
    try {
      final rToken = await getRToken();
      if (rToken.isEmpty) return false;

      final response = await _dio.post(
        refreshUrl,
        data: {'refreshToken': rToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newAccessToken = data['accessToken'];
        final newRefreshToken = data['refreshToken'];

        await tokenService.saveTokens(newAccessToken, newRefreshToken);
        print('🔄 Token refreshed');
        return true;
      } else {
        print('Failed to refresh token: ${response.data}');
        return false;
      }
    } catch (e) {
      print('Exception during token refresh: $e');
      return false;
    }
  }
}
