import 'package:flutter/foundation.dart';

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

  AuthProvider({required this.apiClient, required this.storageService});

  String? get token => _token;
  String? get caseId => _caseId;
  String? get joinCode => _joinCode;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _caseId != null;
  bool get claimed => _claimed;

  Future<void> initialize() async {
    _token = await storageService.getToken();
    _caseId = await storageService.getCaseId();
    _joinCode = await storageService.getJoinCode();
    if (_token != null) {
      apiClient.setToken(_token!);
      // Check if claimed
      if (_caseId != null) {
        await _checkStatus();
      }
    }
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
      notifyListeners();
    } catch (e) {
      // Ignore errors when checking status
    }
  }

  Future<bool> joinCase(String joinCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiClient.joinCase(joinCode);
      _token = response.token;
      _caseId = response.caseId;
      _claimed = true;
      apiClient.setToken(_token!);
      await storageService.saveToken(_token!);
      await storageService.saveCaseId(_caseId!);
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

  Future<void> logout() async {
    _token = null;
    _caseId = null;
    _joinCode = null;
    _claimed = false;
    apiClient.clearToken();
    await storageService.clearAll();
    notifyListeners();
  }
}
