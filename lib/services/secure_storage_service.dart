import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/case_info.dart';

const String _tokenKey = 'case_token';
const String _caseIdKey = 'case_id';
const String _joinCodeKey = 'join_code';
const String _cursorKey = 'server_cursor';
const String _pinHashKey = 'pin_hash';
const String _sessionValidUntilKey = 'session_valid_until';
const String _casesKey = 'linked_cases';
const String _activeCaseIdKey = 'active_case_id';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Legacy single-case methods (kept for backwards compatibility)
  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveCaseId(String caseId) => _storage.write(key: _caseIdKey, value: caseId);
  Future<String?> getCaseId() => _storage.read(key: _caseIdKey);

  Future<void> saveJoinCode(String joinCode) => _storage.write(key: _joinCodeKey, value: joinCode);
  Future<String?> getJoinCode() => _storage.read(key: _joinCodeKey);

  // Multi-case support
  Future<void> saveCases(List<CaseInfo> cases) async {
    await _storage.write(key: _casesKey, value: CaseInfo.encodeList(cases));
  }

  Future<List<CaseInfo>> getCases() async {
    final json = await _storage.read(key: _casesKey);
    if (json == null || json.isEmpty) return [];
    try {
      return CaseInfo.decodeList(json);
    } catch (e) {
      return [];
    }
  }

  Future<void> saveActiveCaseId(String caseId) =>
      _storage.write(key: _activeCaseIdKey, value: caseId);

  Future<String?> getActiveCaseId() => _storage.read(key: _activeCaseIdKey);

  Future<void> addCase(CaseInfo caseInfo) async {
    final cases = await getCases();
    // Remove existing case with same ID if any
    cases.removeWhere((c) => c.caseId == caseInfo.caseId);
    cases.add(caseInfo);
    await saveCases(cases);
    await saveActiveCaseId(caseInfo.caseId);
    // Also update legacy storage for backwards compatibility
    await saveToken(caseInfo.token);
    await saveCaseId(caseInfo.caseId);
    if (caseInfo.joinCode != null) {
      await saveJoinCode(caseInfo.joinCode!);
    }
  }

  Future<void> updateCase(CaseInfo caseInfo) async {
    final cases = await getCases();
    final index = cases.indexWhere((c) => c.caseId == caseInfo.caseId);
    if (index >= 0) {
      cases[index] = caseInfo;
      await saveCases(cases);
    }
  }

  Future<void> removeCase(String caseId) async {
    final cases = await getCases();
    cases.removeWhere((c) => c.caseId == caseId);
    await saveCases(cases);
    
    // If removed active case, switch to another
    final activeCaseId = await getActiveCaseId();
    if (activeCaseId == caseId && cases.isNotEmpty) {
      await saveActiveCaseId(cases.first.caseId);
      await saveToken(cases.first.token);
      await saveCaseId(cases.first.caseId);
    }
  }

  Future<CaseInfo?> getActiveCase() async {
    final activeCaseId = await getActiveCaseId();
    if (activeCaseId == null) return null;
    final cases = await getCases();
    try {
      return cases.firstWhere((c) => c.caseId == activeCaseId);
    } catch (e) {
      return cases.isNotEmpty ? cases.first : null;
    }
  }

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
