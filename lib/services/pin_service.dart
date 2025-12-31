import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Simple PIN hashing utility
class PinService {
  /// Hash a 4-digit PIN using SHA-256
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify a PIN against a stored hash
  static bool verifyPin(String pin, String storedHash) {
    return hashPin(pin) == storedHash;
  }

  /// Validate that a PIN is exactly 4 digits
  static bool isValidPin(String pin) {
    return pin.length == 4 && RegExp(r'^\d{4}$').hasMatch(pin);
  }
}
