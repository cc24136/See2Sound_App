class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.cause});

  final int? statusCode;
  final String message;
  final Object? cause;

  bool get isConnectionError => statusCode == null;

  @override
  String toString() => message;
}
