import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> canUseBiometric() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Położne',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<void> savePIN(String pin) async {
    await _secureStorage.write(key: 'patient_pin', value: pin);
  }

  Future<String?> getPIN() async {
    return await _secureStorage.read(key: 'patient_pin');
  }

  Future<bool> verifyPIN(String pin) async {
    final savedPin = await getPIN();
    return savedPin == pin;
  }

  Future<void> clearPIN() async {
    await _secureStorage.delete(key: 'patient_pin');
  }

  Future<void> enableBiometric() async {
    await _secureStorage.write(key: 'biometric_enabled', value: 'true');
  }

  Future<void> disableBiometric() async {
    await _secureStorage.write(key: 'biometric_enabled', value: 'false');
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: 'biometric_enabled');
    return value == 'true';
  }

  Future<void> enablePIN() async {
    await _secureStorage.write(key: 'pin_enabled', value: 'true');
  }

  Future<void> disablePIN() async {
    await _secureStorage.write(key: 'pin_enabled', value: 'false');
  }

  Future<bool> isPINEnabled() async {
    final value = await _secureStorage.read(key: 'pin_enabled');
    return value == 'true';
  }
}
