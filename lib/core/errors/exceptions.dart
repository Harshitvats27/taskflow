class NotFoundException implements Exception {
  final String message;
  NotFoundException([this.message = 'Resource not found']);

  @override
  String toString() => 'NotFoundException: $message';
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException([this.message = 'Connection timed out']);

  @override
  String toString() => 'TimeoutException: $message';
}

class ValidationException implements Exception {
  final String message;
  ValidationException([this.message = 'Validation failed']);

  @override
  String toString() => 'ValidationException: $message';
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized access']);

  @override
  String toString() => 'UnauthorizedException: $message';
}

class OfflineException implements Exception {
  final String message;
  OfflineException([this.message = 'You are offline. Network required for this action.']);

  @override
  String toString() => 'OfflineException: $message';
}
