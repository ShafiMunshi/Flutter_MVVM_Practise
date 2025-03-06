import 'package:mvvvm_practise/core/exceptions.dart';

class ErrorMapper {
  static String toUserMessage(AppException error) {
    return switch (error) {
      NetworkException() => "No internet Connection",
      ServerException() => "Server is unavailable, try again later.",
     
      UnauthorizedException() => "User is not authorized",
      _ => "Something went wrong."
    };
  }
}
