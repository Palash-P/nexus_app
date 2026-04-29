import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../storage/secure_storage.dart';
import '../errors/exceptions.dart';

class ApiClient {
  late final Dio _dio;
  final SecureStorage secureStorage;

  ApiClient({required this.secureStorage}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://nexus-production-6a7c.up.railway.app',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(secureStorage),
      _ErrorInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    return await _dio.get(path, queryParameters: queryParams);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> postFormData(String path, {required FormData formData}) async {
    return await _dio.post(
      path,
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        sendTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),
      ),
    );
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}

class _AuthInterceptor extends Interceptor {
  final SecureStorage secureStorage;

  _AuthInterceptor(this.secureStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await secureStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Token $token';
    }
    handler.next(options);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // debugPrint('ERROR INTERCEPTOR — status: ${err.response?.statusCode}');
    // debugPrint('ERROR INTERCEPTOR — raw data: ${err.response?.data}');

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        throw const NetworkException();
      default:
        final statusCode = err.response?.statusCode;
        if (statusCode == 401) throw const UnauthorizedException();

        String message = 'Something went wrong';
        final data = err.response?.data;
        if (data is Map) {
          message = data['detail']?.toString() ??
              data['error']?.toString() ??
              data['message']?.toString() ??
              'Something went wrong';
        } else if (data is String && data.isNotEmpty) {
          message = data;
        }

        throw ServerException(message: message, statusCode: statusCode);
    }
  }
}