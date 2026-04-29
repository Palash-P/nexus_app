class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException({required this.message, this.statusCode});
}

class NetworkException implements Exception {
  const NetworkException();
}

class CacheException implements Exception {
  final String message;
  const CacheException({required this.message});
}

class UnauthorizedException implements Exception {
  const UnauthorizedException();
}