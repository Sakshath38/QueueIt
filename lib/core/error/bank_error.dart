sealed class BankError {
  final String message;
  final String? traceId;
  const BankError(this.message, {this.traceId});
}

class NetworkError extends BankError {
  const NetworkError([super.message = 'Network connection failed. Please check your signal.']);
}

class ConflictError extends BankError {
  const ConflictError([super.message = 'This slot was just taken by another customer. Please choose another.']);
}

class ServerError extends BankError {
  final int statusCode;
  const ServerError(super.message, {required this.statusCode, super.traceId});
}