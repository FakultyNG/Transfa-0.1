import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  factory ApiException.fromDioException(DioException error) {
    final response = error.response;
    final data = response?.data;
    String? message;
    String? code;
    Object? details;

    if (data is Map) {
      final nestedError = data['error'];
      if (nestedError is Map) {
        message =
            nestedError['message']?.toString() ?? data['message']?.toString();
        code = nestedError['code']?.toString();
        details = nestedError['details'] ?? nestedError['errors'];
      } else {
        message = data['message']?.toString() ?? nestedError?.toString();
        code = data['code']?.toString();
        details = data['details'] ?? data['errors'];
      }
    }

    return ApiException(
      message: message ?? _fallbackMessage(error.type, response?.statusCode),
      statusCode: response?.statusCode,
      code: code,
      details: details,
    );
  }

  final String message;
  final int? statusCode;
  final String? code;
  final Object? details;

  static String _fallbackMessage(DioExceptionType type, int? statusCode) {
    if (statusCode == 429) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return 'The service is temporarily unavailable. Please try again.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'The server could not complete the request. Please try again.';
    }

    return switch (type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'The request timed out. Please try again.',
      DioExceptionType.connectionError =>
        'Unable to reach Transfa. Check your connection and try again.',
      DioExceptionType.cancel => 'The request was cancelled.',
      _ => 'Something went wrong. Please try again.',
    };
  }

  @override
  String toString() => message;
}
