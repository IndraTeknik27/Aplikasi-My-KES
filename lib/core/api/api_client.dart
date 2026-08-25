import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_storage.dart';

/// Lightweight wrapper around the Laravel envelope shape.
/// `{"success": bool, "message": String, "data": <T>}`.
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;
  final Map<String, dynamic>? meta;
  final int statusCode;

  const ApiResponse({
    required this.success,
    required this.message,
    required this.statusCode,
    this.data,
    this.errors,
    this.meta,
  });

  bool get isSuccess => success;

  R when<R>({
    required R Function(T? data) success,
    required R Function(String message, Map<String, dynamic>? errors) failure,
  }) {
    if (isSuccess) {
      return success(data);
    }
    return failure(message, errors);
  }
}

/// Application-level exception used by [ApiClient].
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? errors;
  final dynamic raw;

  const ApiException({
    required this.message,
    required this.statusCode,
    this.errors,
    this.raw,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidation => statusCode == 422;
  bool get isServer => statusCode >= 500;
  bool get isNetwork => statusCode == 0;

  String? fieldError(String field) {
    if (errors == null) return null;
    final v = errors![field];
    if (v is List && v.isNotEmpty) return v.first?.toString();
    if (v is String) return v;
    return null;
  }

  Map<String, String?> fieldErrors() {
    final map = <String, String?>{};
    if (errors == null) return map;
    errors!.forEach((k, v) {
      if (v is List && v.isNotEmpty) {
        map[k] = v.first?.toString();
      } else if (v is String) {
        map[k] = v;
      }
    });
    return map;
  }

  @override
  String toString() =>
      'ApiException($statusCode): $message${errors == null ? '' : ' | $errors'}';
}

/// Single, central HTTP client.
///
/// Responsibilities:
///   * Attach `Authorization: Bearer <token>` if available.
///   * Attach `X-Session-Id` for guest cart continuity.
///   * Attach `Accept: application/json` and `Content-Type` as JSON.
///   * Normalize Laravel envelope into [ApiResponse] or throw [ApiException].
///   * Log requests in debug mode.
class ApiClient {
  ApiClient._();

  static const String baseUrl = 'http://karteks-energy-solution.test/api/v1';

  static final ApiClient instance = ApiClient._();

  late final Dio _dio = _buildDio();

  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Client': 'my-kes-flutter',
        },
        validateStatus: (_) => true,
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(_AuthInterceptor());
    if (kDebugMode) {
      dio.interceptors.add(_LogInterceptor());
    }
    return dio;
  }

  Dio get dio => _dio;

  // -------- HTTP verbs returning parsed ApiResponse<T> --------

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) => _request<T>('GET', path, query: query, headers: headers);

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) => _request<T>('POST', path, body: body, query: query, headers: headers);

  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) => _request<T>('PUT', path, body: body, query: query, headers: headers);

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) => _request<T>('PATCH', path, body: body, query: query, headers: headers);

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) => _request<T>('DELETE', path, body: body, query: query, headers: headers);

  /// Multipart upload (avatar image, contact form attachment).
  Future<ApiResponse<T>> upload<T>(
    String path, {
    required Map<String, dynamic> formData, // pass FormData.fromMap or fields
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    ProgressCallback? onSendProgress,
  }) {
    final options = Options(
      method: 'POST',
      headers: {'Content-Type': 'multipart/form-data', ...?headers},
    );

    return _request<T>(
      'POST',
      path,
      body: formData,
      query: query,
      headers: headers,
      options: options,
      onSendProgress: onSendProgress,
    );
  }

  /// Download raw bytes (e.g. invoice PDF). Returns `null` on failure.
  Future<List<int>?> download(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get<List<int>>(
        path,
        queryParameters: query,
        options: Options(responseType: ResponseType.bytes),
      );
      if (res.statusCode == 200 && res.data != null) {
        return res.data;
      }
    } catch (_) {}
    return null;
  }

  // ---------------- internals ----------------

  Future<ApiResponse<T>> _request<T>(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: (options ?? Options(method: method)).copyWith(
          headers: {...?options?.headers, ...?headers},
        ),
        onSendProgress: onSendProgress,
      );

      return _parse<T>(response);
    } on DioException catch (e) {
      return _parseDioException<T>(e);
    }
  }

  ApiResponse<T> _parse<T>(Response<dynamic> response) {
    final raw = response.data;
    final status = response.statusCode ?? 0;

    if (raw is Map<String, dynamic>) {
      // Standard envelope
      if (raw.containsKey('success')) {
        final ok = raw['success'] == true;
        final msg = (raw['message'] as String?) ?? '';
        final data = raw['data'];
        final errors = raw['errors'] is Map
            ? Map<String, dynamic>.from(raw['errors'] as Map)
            : null;
        final meta = raw['meta'] is Map
            ? Map<String, dynamic>.from(raw['meta'] as Map)
            : null;

        if (ok) {
          return ApiResponse<T>(
            success: true,
            message: msg,
            statusCode: status,
            data: data as T?,
            meta: meta,
          );
        } else {
          throw ApiException(
            message: msg.isEmpty ? 'Request failed' : msg,
            statusCode: status,
            errors: errors,
            raw: raw,
          );
        }
      }

      // Validation 422 Laravel shape: { message, errors: {...} }
      if (status == 422 && raw['errors'] is Map) {
        throw ApiException(
          message: (raw['message'] as String?) ?? 'Validation failed',
          statusCode: status,
          errors: Map<String, dynamic>.from(raw['errors'] as Map),
          raw: raw,
        );
      }

      // Some endpoints return raw object as body (rare)
      return ApiResponse<T>(
        success: status >= 200 && status < 300,
        message: '',
        statusCode: status,
        data: raw as T?,
      );
    }

    if (raw is List) {
      return ApiResponse<T>(
        success: status >= 200 && status < 300,
        message: '',
        statusCode: status,
        data: raw as T?,
      );
    }

    // Empty body
    return ApiResponse<T>(
      success: status >= 200 && status < 300,
      message: '',
      statusCode: status,
      data: null,
    );
  }

  ApiResponse<T> _parseDioException<T>(DioException e) {
    final res = e.response;
    if (res != null) {
      try {
        return _parse<T>(res);
      } catch (err) {
        if (err is ApiException) rethrow;
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw ApiException(
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        statusCode: 0,
      );
    }
    throw ApiException(
      message: e.message ?? 'Terjadi kesalahan jaringan.',
      statusCode: 0,
    );
  }
}

class _AuthInterceptor extends Interceptor {
  bool _refreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    final sessionId = await SecureStorage.readCartSessionId();
    if (sessionId != null && sessionId.isNotEmpty) {
      options.headers['X-Session-Id'] = sessionId;
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // Capture guest session id if backend returns one in response headers.
    final sessionHeader = response.headers.value('X-Session-Id');
    if (sessionHeader != null && sessionHeader.isNotEmpty) {
      await SecureStorage.saveCartSessionId(sessionHeader);
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode ?? 0;

    if (status == 401 && !_refreshing) {
      // Token expired/invalid. Attempt a single refresh.
      _refreshing = true;
      try {
        final refreshToken = await SecureStorage.readToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final dio = ApiClient.instance.dio;
          final retry = await dio.post(
            '/auth/refresh',
            options: Options(
              headers: {'Authorization': 'Bearer $refreshToken'},
            ),
          );
          if (retry.statusCode == 200 && retry.data is Map) {
            final newToken = (retry.data as Map)['data']?['access_token'];
            if (newToken is String && newToken.isNotEmpty) {
              await SecureStorage.saveToken(newToken);
              // Retry original request once
              final req = err.requestOptions;
              req.headers['Authorization'] = 'Bearer $newToken';
              final resp = await dio.fetch(req);
              return handler.resolve(resp);
            }
          }
        }
      } catch (_) {
        // fall through
      } finally {
        _refreshing = false;
      }

      // Refresh failed — wipe token to force re-login.
      await SecureStorage.clearAuth();
    }

    handler.next(err);
  }
}

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('→ ${options.method} ${options.uri}');
    if (options.data != null) {
      debugPrint('  body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('✗ ${err.requestOptions.uri}: ${err.message}');
    handler.next(err);
  }
}
