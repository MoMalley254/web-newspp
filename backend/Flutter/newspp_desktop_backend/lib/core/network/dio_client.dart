import 'package:dio/dio.dart';

class DioClient {
  static const String baseUrl = 'http://localhost:3000/admin';
  static const String authUrl = '$baseUrl/auth';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) {
        return status != null && status < 600; // Accept all statuses < 600
      },
    ),
  );

  static Dio get instance => _dio;

  static void init() {
    // Add logging interceptor
    // _dio.interceptors.add(
    //   LogInterceptor(requestBody: true, responseBody: true),
    // );

    // Add custom request/response/error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('➡️ Request: ${options.method} ${options.uri}');
          // You can add dynamic auth token here if needed
          options.headers['Authorization'] = 'Bearer your_token_here';
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ Response: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('❌ Error: ${e.message}');
          if (e.response?.statusCode == 401) {
            // TODO: Handle unauthorized access
          }
          return handler.next(e);
        },
      ),
    );
  }
}
