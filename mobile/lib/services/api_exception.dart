/// Thrown by service methods when the backend returns a non-2xx response.
/// Mirrors the backend's `ErrorResponse` JSON shape
/// (see caffora-backend/.../exception/GlobalExceptionHandler.java).
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final List<String>? fieldErrors;

  ApiException({required this.statusCode, required this.message, this.fieldErrors});

  @override
  String toString() => message;
}

/// Thrown when a request can't reach the backend at all (no connectivity,
/// DNS failure, timeout). Callers use this to decide whether to fall back
/// to cached/offline data.
class NetworkUnavailableException implements Exception {
  final String message;
  NetworkUnavailableException([this.message = 'No connection to the Caffora server.']);

  @override
  String toString() => message;
}
