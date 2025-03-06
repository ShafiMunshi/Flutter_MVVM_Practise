abstract class AppException implements Exception {
  final String message;
  AppException(this.message);
}

class NetworkException extends AppException {
  NetworkException() : super("No Internet connection. ");
}

class ServerException extends AppException {
  ServerException(String details) : super("Server Error: $details");
}

class LocalDatabaseException extends AppException {
  LocalDatabaseException(String details) : super("Database error: $details");
}

class UnauthorizedException extends AppException {
  UnauthorizedException() : super("User is Unauthorized");
}

class ValidationException extends AppException {
  ValidationException(String details) : super("Validation Error: $details");
}



class UnknownException extends AppException {
  UnknownException(String details) : super("Unknown Error: $details");
}
