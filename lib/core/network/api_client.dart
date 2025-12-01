import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({
    required http.Client httpClient,
    required this.baseUrl,
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    this.timeout = const Duration(seconds: 20),
  }) : _httpClient = httpClient;

  final http.Client _httpClient;
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;

  Uri _resolve(String path, [Map<String, dynamic>? queryParameters]) {
    final base = Uri.parse(baseUrl);
    final resolved = base.resolve(path);
    if (queryParameters == null || queryParameters.isEmpty) {
      return resolved;
    }
    return resolved.replace(
      queryParameters: {
        ...resolved.queryParameters,
        ...queryParameters.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        ),
      },
    );
  }

  Map<String, String> _mergeHeaders(Map<String, String>? headers) {
    return {...defaultHeaders, if (headers != null) ...headers};
  }

  Object? _encodeBody(Object? body) {
    if (body == null) {
      return null;
    }
    if (body is String || body is List<int>) {
      return body;
    }
    return jsonEncode(body);
  }

  Object? _encodeFormBody(Object? body) {
    if (body == null) return null;

    if (body is Map) {
      // Le client http accepte Map<String, String> pour encoder en x-www-form-urlencoded.
      return body.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      );
    }

    if (body is String || body is List<int>) {
      return body;
    }

    return body.toString();
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _resolve(path, queryParameters);
    final response = await _httpClient
        .get(uri, headers: _mergeHeaders(headers))
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        method: 'GET',
        uri: uri,
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? body,
    Map<String, String>? headers,
    bool formEncoded = false,
  }) async {
    final uri = _resolve(path, queryParameters);
    final mergedHeaders = _mergeHeaders(headers);
    if (formEncoded) {
      mergedHeaders['Content-Type'] = 'application/x-www-form-urlencoded';
    }

    final encodedBody = formEncoded ? _encodeFormBody(body) : _encodeBody(body);

    final response = await _httpClient
        .post(uri, headers: mergedHeaders, body: encodedBody)
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        method: 'POST',
        uri: uri,
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}

class ApiException implements Exception {
  ApiException({
    required this.method,
    required this.uri,
    required this.statusCode,
    this.body,
  });

  final String method;
  final Uri uri;
  final int statusCode;
  final String? body;

  @override
  String toString() {
    return 'ApiException(method: $method, uri: $uri, statusCode: $statusCode, body: $body)';
  }
}
