class AppException implements Exception {
  final int statusCode;
  final String message;

  AppException(this.statusCode, this.message);

  @override
  String toString() => "AppException(statusCode: $statusCode, message: $message)";
}

class BadRequestException extends AppException {
  BadRequestException([String message = "Geçersiz istek. Lütfen bilgilerinizi kontrol ediniz."]) : super(400, message);
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String message = "Yetkisiz erişim. Lütfen tekrar giriş yapınız."]) : super(401, message);
}

class ServerException extends AppException {
  ServerException([String message = "Sunucuda bir hata oluştu. Lütfen daha sonra tekrar deneyiniz."]) : super(500, message);
}

class NetworkException extends AppException {
  NetworkException([String message = "İnternet bağlantınızı kontrol ederek lütfen tekrar deneyiniz."]) : super(0, message);
}
