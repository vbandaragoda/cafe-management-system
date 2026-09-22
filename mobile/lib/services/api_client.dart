import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import 'api_exception.dart';
import 'session_service.dart';

/// Thin wrapper around [http] that talks to the Caffora Spring Boot
/// backend: builds the base URL, attaches the `Authorization: Bearer`
/// header when a session token exists, decodes JSON, and translates
/// non-2xx responses into [ApiException] / [NetworkUnavailableException]
/// using the backend's ErrorResponse shape.
class ApiClient {
  final SessionService _session;
  final http.Client _http;

  ApiClient({SessionService? session, http.Client? httpClient})
      : _session = session ?? SessionService(),
        _http = httpClient ?? http.Client();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    final full = '${base.path}$path';
    return base.replace(
      path: full,
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (auth) {
      final token = await _session.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) async {
    return _send(auth, (headers) => _http.get(_uri(path, query), headers: headers).timeout(AppConfig.requestTimeout));
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) async {
    return _send(
      auth,
      (headers) => _http
          .post(_uri(path), headers: headers, body: body == null ? null : jsonEncode(body))
          .timeout(AppConfig.requestTimeout),
    );
  }

  Future<dynamic> put(String path, {Object? body, bool auth = true}) async {
    return _send(
      auth,
      (headers) => _http
          .put(_uri(path), headers: headers, body: body == null ? null : jsonEncode(body))
          .timeout(AppConfig.requestTimeout),
    );
  }

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) async {
    return _send(
      auth,
      (headers) => _http
          .patch(_uri(path), headers: headers, body: body == null ? null : jsonEncode(body))
          .timeout(AppConfig.requestTimeout),
    );
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    return _send(auth, (headers) => _http.delete(_uri(path), headers: headers).timeout(AppConfig.requestTimeout));
  }

  Future<dynamic> _send(
    bool auth,
    Future<http.Response> Function(Map<String, String> headers) doRequest,
  ) async {
    final headers = await _headers(auth: auth);
    http.Response response;
    try {
      response = await doRequest(headers);
    } on TimeoutException {
      throw NetworkUnavailableException('The Caffora server took too long to respond.');
    } on SocketException {
      throw NetworkUnavailableException();
    } on http.ClientException {
      throw NetworkUnavailableException();
    }

    final status = response.statusCode;
    final rawBody = response.body.isEmpty ? null : response.body;
    dynamic decoded;
    if (rawBody != null) {
      try {
        decoded = jsonDecode(rawBody);
      } catch (_) {
        decoded = null;
      }
    }

    if (status >= 200 && status < 300) {
      return decoded;
    }

    String message = 'Something went wrong (HTTP $status).';
    List<String>? fieldErrors;
    if (decoded is Map<String, dynamic>) {
      message = decoded['message'] as String? ?? message;
      final fe = decoded['fieldErrors'];
      if (fe is List) {
        fieldErrors = fe.map((e) => e.toString()).toList();
      }
    }
    throw ApiException(statusCode: status, message: message, fieldErrors: fieldErrors);
  }
}
