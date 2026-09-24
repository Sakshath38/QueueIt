import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/bank_error.dart';

// Holds the current user session token. Null means logged out.
final authStateProvider = StateProvider<String?>((ref) => null);

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class AuthRepository {
  Future<String> login(String customerId, String pin) async {
    // Simulate network latency
    await Future.delayed(const Duration(seconds: 1));
    
    if (customerId.isEmpty || pin.isEmpty) {
      throw const ServerError('Customer ID and PIN are required.', statusCode: 400);
    }
    
    // For this prototype, any ID works, but PIN must be 1234
    if (pin != '1234') {
      throw const ServerError('Invalid PIN. Please try again.', statusCode: 401);
    }
    
    return 'secure_token_$customerId';
  }
}