import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _tokenKey = 'case_token';
const String _caseIdKey = 'case_id';
const String _joinCodeKey = 'join_code';
const String _cursorKey = 'server_cursor';
const String _pinHashKey = 'pin_hash';
const String _sessionValidUntilKey = 'session_valid_until';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveCaseId(String caseId) => _storage.write(key: _caseIdKey, value: caseId);
  Future<String?> getCaseId() => _storage.read(key: _caseIdKey);

  Future<void> saveJoinCode(String joinCode) => _storage.write(key: _joinCodeKey, value: joinCode);
  Future<String?> getJoinCode() => _storage.read(key: _joinCodeKey);

  Future<void> saveCursor(String? cursor) async {
    if (cursor == null) {
      await _storage.delete(key: _cursorKey);
    } else {
      await _storage.write(key: _cursorKey, value: cursor);
    }
  }

  Future<String?> getCursor() => _storage.read(key: _cursorKey);

  // PIN management
  Future<void> savePinHash(String pinHash) => _storage.write(key: _pinHashKey, value: pinHash);
  Future<String?> getPinHash() => _storage.read(key: _pinHashKey);
  Future<bool> hasPin() async => await _storage.read(key: _pinHashKey) != null;

  // Session management (for keeping user logged in when minimizing app)
  Future<void> saveSessionValidUntil(DateTime until) =>
      _storage.write(key: _sessionValidUntilKey, value: until.toIso8601String());
  
  Future<DateTime?> getSessionValidUntil() async {
    final value = await _storage.read(key: _sessionValidUntilKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> clearSession() => _storage.delete(key: _sessionValidUntilKey);

  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _caseIdKey);
    await _storage.delete(key: _joinCodeKey);
    await _storage.delete(key: _cursorKey);
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _sessionValidUntilKey);
  }
}
