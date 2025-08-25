import 'package:dio/dio.dart';
import 'package:newspp_desktop_backend/services/toast_service.dart';
import 'package:newspp_desktop_backend/services/tokens_service.dart';

class DioClient {
  final tokenService = TokenStorage();
  final toastService = ToastService();

  static const String baseUrl = 'http://localhost:3000';
  static const String refreshUrl = '$baseUrl/admin/refresh';

  int retryCount = 0;

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
      // Only treat 400 as errors, let 500 pass without throwing an error
      validateStatus: (status) {
        // Treat 400-499 as errors, but allow 500-599 for now
        if (status != null) {
          return (status >= 200 && status < 300) ||
              (status >= 500 && status < 600);
        }
        return false; // All other status codes are considered invalid
      },
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
          return handler.next(options);
        },

        onResponse: (response, handler) {
          print('✅ Response: ${response.statusCode}');
          return handler.next(response);
        },

        onError: (DioException error, handler) async {
          print('❌ Error: ${error.response?.statusCode} ${error.message}');

          // Check if we are getting a 403 error and retry count is less than 3
          if (error.response?.statusCode == 403 && retryCount < 3) {
            _singleton.toastService.showProcessingtoast(
              'Authenticating please wait, attempt ${retryCount + 1}',
              2,
            );
            print(
              'Attempt ${retryCount + 1}: Trying to refresh the access token...',
            );

            // Increment retry count
            retryCount++;

            try {
              // Attempt to refresh the token
              final refreshed = await _singleton._refreshToken();

              if (refreshed) {
                _singleton.toastService.showSuccesstoast('Authenticated');
                // Retry the original request with the new access token
                final newAccessToken = await _singleton.getAToken();

                final requestOptions = error.requestOptions;
                requestOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';

                // Retry the request
                final clonedResponse = await _dio.fetch(requestOptions);
                return handler.resolve(clonedResponse);
              } else {
                // Token refresh failed, reject with error
                _singleton.toastService.showErrortoast(
                  'Re-authentication failed. Please log in again.',
                );
                return handler.reject(error); // Reject original error
              }
            } catch (retryError) {
              print('Retry failed: $retryError');
              //Clear saved tokens
              await _singleton.tokenService.clearTokens();
              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  error: retryError,
                  type: DioExceptionType.badResponse,
                ),
              );
            }
          } else {
            // Reject if it's not a 403 or retry attempts exceed 3
            return handler.reject(error);
          }
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

      if (response.statusCode == 201) {
        final data = response.data;
        final newAccessToken = data['newAToken'];
        final refreshToken = data['rToken'];

        await tokenService.saveTokens(newAccessToken, refreshToken);
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
