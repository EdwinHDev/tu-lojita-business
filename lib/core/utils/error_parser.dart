import 'package:dio/dio.dart';

class ErrorParser {
  static String parse(dynamic error) {
    if (error is DioException) {
      if (error.response != null && error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map && data.containsKey('message')) {
          final message = data['message'];
          if (message is List) {
            return message.join(', ');
          }
          return message.toString();
        }
      }
      return error.message ?? 'Unknown connection error';
    }
    return error.toString();
  }
}
