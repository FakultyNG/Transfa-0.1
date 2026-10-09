import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'session_store.dart';

class ApiClient {
  ApiClient({required String baseUrl, required SessionStore sessionStore})
    : _sessionStore = sessionStore,
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.data is FormData) {
            options.contentType = Headers.multipartFormDataContentType;
          }
          final token = await _sessionStore.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  static const apiPrefix = '/api/v1';

  final Dio _dio;
  final SessionStore _sessionStore;
  Future<bool>? _refreshFuture;

  Future<Object?> get(
    String path, {
    Map<String, Object?>? queryParameters,
    bool allowRefresh = true,
  }) => _request(
    () => _dio.get<Object?>(path, queryParameters: queryParameters),
    allowRefresh: allowRefresh,
  );

  Future<Object?> post(
    String path, {
    Object? data,
    Map<String, Object?>? headers,
    bool allowRefresh = true,
  }) => _request(
    () => _dio.post<Object?>(
      path,
      data: data,
      options: headers == null ? null : Options(headers: headers),
    ),
    allowRefresh: allowRefresh,
  );

  Future<Object?> patch(
    String path, {
    Object? data,
    bool allowRefresh = true,
  }) => _request(
    () => _dio.patch<Object?>(path, data: data),
    allowRefresh: allowRefresh,
  );

  Future<Object?> delete(
    String path, {
    Object? data,
    bool allowRefresh = true,
  }) => _request(
    () => _dio.delete<Object?>(path, data: data),
    allowRefresh: allowRefresh,
  );

  Future<Object?> _request(
    Future<Response<Object?>> Function() request, {
    required bool allowRefresh,
    bool isRetry = false,
  }) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (error) {
      if (allowRefresh && !isRetry && error.response?.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return _request(request, allowRefresh: false, isRetry: true);
        }
      }
      throw ApiException.fromDioException(error);
    }
  }

  Future<bool> _refreshAccessToken() {
    final pending = _refreshFuture;
    if (pending != null) return pending;

    final refresh = _performRefresh();
    _refreshFuture = refresh;
    return refresh.whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _sessionStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _dio.post<Object?>(
        '$apiPrefix/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );
      final root = _map(response.data);
      final data = _map(root['data']);
      final accessToken = data['accessToken']?.toString();
      if (accessToken == null || accessToken.isEmpty) return false;
      await _sessionStore.write(
        AuthSession(accessToken: accessToken, refreshToken: refreshToken),
      );
      return true;
    } on DioException {
      await _sessionStore.clear();
      return false;
    } on FormatException {
      await _sessionStore.clear();
      return false;
    }
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Expected a JSON object.');
}
