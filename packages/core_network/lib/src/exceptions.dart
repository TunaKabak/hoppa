class AppException implements Exception {
  final int statusCode;
  final String message;

  AppException(this.statusCode, this.message);

  @override
  String toString() => "AppException(statusCode: $statusCode, message: $message)";
}

class BadRequestException extends AppException {
  BadRequestException(String message) : super(400, message);
}

class UnauthorizedException extends AppException {
  UnauthorizedException(String message) : super(401, message);
}

class ServerException extends AppException {
  ServerException(String message) : super(500, message);
}

class NetworkException extends AppException {
  NetworkException(String message) : super(0, message);
}
