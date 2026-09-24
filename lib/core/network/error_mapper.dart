import 'package:dio/dio.dart';
import '../error/bank_error.dart';

class ErrorMapper {
  static BankError map(dynamic error) {
    if (error is DioException) {
      final response = error.response;
      final traceId = response?.data is Map ? response?.data['traceId'] as String? : null;

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return const NetworkError('Network connection unstable. Please try again.');

        case DioExceptionType.badResponse:
          final statusCode = response?.statusCode ?? 500;
          final serverMsg = (response?.data is Map && response?.data['message'] != null)
              ? response?.data['message'] as String
              : null;

          if (statusCode == 409) {
            return ConflictError(
              serverMsg ?? 'This slot or token was just claimed by another user.',
            );
          } else if (statusCode == 401) {
            return ServerError(
              serverMsg ?? 'Session expired. Please sign in.',
              statusCode: 401,
              traceId: traceId,
            );
          }

          return ServerError(
            serverMsg ?? 'Server request failed.',
            statusCode: statusCode,
            traceId: traceId,
          );

        default:
          return const NetworkError('Unable to connect to the banking gateway.');
      }
    }

    if (error is BankError) return error;
    return ServerError(error.toString(), statusCode: 500);
  }
}