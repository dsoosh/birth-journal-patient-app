import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/websocket_service.dart';

class WebSocketProvider extends ChangeNotifier {
  final ApiClient apiClient;
  
  WebSocketService? _ws;
  List<Map<String, dynamic>> _recentMessages = [];
  bool _isConnected = false;

  WebSocketProvider({required this.apiClient});

  bool get isConnected => _isConnected;
  List<Map<String, dynamic>> get recentMessages => _recentMessages;

  Future<void> connect(String caseId, String token) async {
    if (_isConnected) return;

    try {
      _ws = WebSocketService(
        baseUrl: apiClient.baseUrl,
        token: token,
        caseId: caseId,
      );
      
      await _ws!.connect();
      _isConnected = true;
      notifyListeners();
      
      // Listen for messages
      _ws!.messages.listen((message) {
        _recentMessages.add(message);
        // Keep only last 100 messages
        if (_recentMessages.length > 100) {
          _recentMessages.removeAt(0);
        }
        notifyListeners();
      });
    } catch (e) {
      print('Error connecting WebSocket: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  void disconnect() {
    _ws?.disconnect();
    _ws = null;
    _isConnected = false;
    notifyListeners();
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected) {
      _ws?.send(message);
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
