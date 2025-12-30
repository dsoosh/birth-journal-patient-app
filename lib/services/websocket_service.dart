import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final String baseUrl;
  final String token;
  final String caseId;
  
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _messageStreamController = StreamController<Map<String, dynamic>>.broadcast();
  
  bool get isConnected => _channel != null;
  Stream<Map<String, dynamic>> get messages => _messageStreamController.stream;

  WebSocketService({
    required this.baseUrl,
    required this.token,
    required this.caseId,
  });

  Future<void> connect() async {
    if (isConnected) return;

    try {
      // Build WebSocket URL
      String wsUrl = baseUrl;
      
      // Remove /api/v1 from base URL
      if (wsUrl.endsWith('/api/v1')) {
        wsUrl = wsUrl.substring(0, wsUrl.length - 7);
      } else if (wsUrl.endsWith('/api')) {
        wsUrl = wsUrl.substring(0, wsUrl.length - 4);
      }
      
      // Convert http(s) to ws(s)
      wsUrl = wsUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
      
      final url = Uri.parse('$wsUrl/api/v1/ws/cases/$caseId?token=$token');
      print('WebSocket connecting to: $url');
      
      _channel = WebSocketChannel.connect(url);
      
      // Listen for messages
      _subscription = _channel!.stream.listen(
        (message) {
          try {
            print('WebSocket received: $message');
            final data = jsonDecode(message) as Map<String, dynamic>;
            _messageStreamController.add(data);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          disconnect();
        },
        onDone: () {
          print('WebSocket closed');
          disconnect();
        },
      );
      print('WebSocket connected successfully');
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      rethrow;
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void send(Map<String, dynamic> message) {
    if (!isConnected) {
      throw Exception('WebSocket not connected');
    }
    _channel!.sink.add(jsonEncode(message));
  }

  void dispose() {
    disconnect();
    _messageStreamController.close();
  }
}
