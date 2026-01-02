import 'package:flutter/foundation.dart';

import '../models/case_info.dart';
import '../services/api_client.dart';
import '../services/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;
  final SecureStorageService storageService;

  String? _token;
  String? _caseId;
  String? _joinCode;
  bool _isLoading = false;
  String? _error;
  bool _claimed = false;
  bool _laborActive = false;
  bool _postpartumActive = false;
  bool _isClosed = false;

  // Multi-case support
  List<CaseInfo> _cases = [];
  CaseInfo? _activeCase;

  AuthProvider({required this.apiClient, required this.storageService});

  String? get token => _token;
  String? get caseId => _caseId;
  String? get joinCode => _joinCode;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _caseId != null;
  bool get claimed => _claimed;
  bool get laborActive => _laborActive;
  bool get postpartumActive => _postpartumActive;
  bool get isClosed => _isClosed;

  // Multi-case getters
  List<CaseInfo> get cases => _cases;
  CaseInfo? get activeCase => _activeCase;
  bool get hasMultipleCases => _cases.length > 1;

  /// Returns the current mode: 'labor', 'postpartum', or 'none'
  String get currentMode {
    if (_postpartumActive) return 'postpartum';
    if (_laborActive) return 'labor';
    return 'none';
  }

  Future<void> initialize() async {
    // Load all cases
    _cases = await storageService.getCases();
    _activeCase = await storageService.getActiveCase();

    // For backwards compatibility, also try legacy storage
    if (_cases.isEmpty) {
      _token = await storageService.getToken();
      _caseId = await storageService.getCaseId();
      _joinCode = await storageService.getJoinCode();
      
      // Migrate to multi-case storage
      if (_token != null && _caseId != null) {
        final caseInfo = CaseInfo(
          caseId: _caseId!,
          token: _token!,
          joinCode: _joinCode,
          linkedAt: DateTime.now(),
        );
        await storageService.addCase(caseInfo);
        _cases = [caseInfo];
        _activeCase = caseInfo;
      }
    } else if (_activeCase != null) {
      _token = _activeCase!.token;
      _caseId = _activeCase!.caseId;
      _joinCode = _activeCase!.joinCode;
      _isClosed = _activeCase!.isClosed;
    }

    if (_token != null) {
      apiClient.setToken(_token!);
      if (_caseId != null) {
        await _checkStatus();
      }
    }
    notifyListeners();
  }

  /// Switch to a different case
  Future<void> switchToCase(String caseId) async {
    final caseInfo = _cases.firstWhere(
      (c) => c.caseId == caseId,
      orElse: () => throw Exception('Case not found'),
    );

    await storageService.saveActiveCaseId(caseId);
    await storageService.saveToken(caseInfo.token);
    await storageService.saveCaseId(caseInfo.caseId);

    _activeCase = caseInfo;
    _token = caseInfo.token;
    _caseId = caseInfo.caseId;
    _joinCode = caseInfo.joinCode;
    _isClosed = caseInfo.isClosed;

    apiClient.setToken(_token!);
    await _checkStatus();
    notifyListeners();
  }

  Future<bool> initiateCase() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiClient.initiateCase();
      _token = response.token;
      _caseId = response.caseId;
      _joinCode = response.joinCode;
      _claimed = false;
      apiClient.setToken(_token!);
      await storageService.saveToken(_token!);
      await storageService.saveCaseId(_caseId!);
      await storageService.saveJoinCode(_joinCode!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> checkClaimed() async {
    if (_caseId == null) return;
    await _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final status = await apiClient.getCaseStatus(_caseId!);
      _claimed = status.claimed;
      _laborActive = status.laborActive;
      _postpartumActive = status.postpartumActive;
      
      // Check if case is closed
      final wasClosed = _isClosed;
      _isClosed = status.closedAt != null;
      
      // Update case info if closed status changed
      if (_isClosed != wasClosed && _activeCase != null) {
        final updatedCase = _activeCase!.copyWith(isClosed: _isClosed);
        await storageService.updateCase(updatedCase);
        _activeCase = updatedCase;
        
        // Update in cases list
        final index = _cases.indexWhere((c) => c.caseId == _caseId);
        if (index >= 0) {
          _cases[index] = updatedCase;
        }
      }
      
      notifyListeners();
    } catch (e) {
      // Ignore errors when checking status
    }
  }

  /// Refresh the case mode from server
  Future<void> refreshMode() async {
    if (_caseId == null) return;
    await _checkStatus();
  }

  Future<bool> joinCase(String joinCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiClient.joinCase(joinCode);
      
      // Create case info and store it
      final caseInfo = CaseInfo(
        caseId: response.caseId,
        token: response.token,
        joinCode: joinCode,
        linkedAt: DateTime.now(),
      );
      
      await storageService.addCase(caseInfo);
      
      _token = response.token;
      _caseId = response.caseId;
      _claimed = true;
      _isClosed = false;
      _activeCase = caseInfo;
      _cases = await storageService.getCases();
      
      apiClient.setToken(_token!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove a case (does not delete data, just unlinks)
  Future<void> removeCase(String caseId) async {
    await storageService.removeCase(caseId);
    _cases = await storageService.getCases();
    
    // If we removed the active case, switch to another or clear auth
    if (_caseId == caseId) {
      if (_cases.isNotEmpty) {
        await switchToCase(_cases.first.caseId);
      } else {
        _token = null;
        _caseId = null;
        _joinCode = null;
        _claimed = false;
        _activeCase = null;
        apiClient.clearToken();
      }
    }
    notifyListeners();
  }
}
