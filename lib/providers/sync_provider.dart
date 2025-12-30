import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/event.dart';
import '../models/sync.dart';
import '../services/api_client.dart';
import '../services/event_queue.dart';
import '../services/secure_storage_service.dart';

class SyncProvider extends ChangeNotifier {
  final ApiClient apiClient;
  final EventQueue queue;
  final SecureStorageService storage;

  bool _isSyncing = false;
  String? _error;
  List<EventEnvelope> _pending = [];

  SyncProvider({
    required this.apiClient,
    required this.queue,
    required this.storage,
  });

  bool get isSyncing => _isSyncing;
  String? get error => _error;
  List<EventEnvelope> get pending => _pending;

  Future<void> initialize() async {
    await queue.init();
    _pending = await queue.pending();
    notifyListeners();
  }

  Future<void> enqueueEvent({
    required String caseId,
    required String type,
    required Map<String, dynamic> payload,
    String? source,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final event = EventEnvelope(
      eventId: const Uuid().v4(),
      caseId: caseId,
      type: type,
      ts: now,
      payloadVersion: 1,
      payload: payload,
      track: null, // server derives track
      source: source,
    );
    await queue.add(event);
    _pending = await queue.pending();
    notifyListeners();
  }

  Future<void> sync({required String caseId}) async {
    _isSyncing = true;
    _error = null;
    notifyListeners();

    try {
      final cursor = await storage.getCursor();
      _pending = await queue.pending();
      final request = SyncRequest(
        clientTime: DateTime.now().toUtc().toIso8601String(),
        cursor: cursor,
        events: _pending,
      );

      final response = await apiClient.syncEvents(request);
      if (response.acceptedEventIds.isNotEmpty) {
        await queue.removeByIds(response.acceptedEventIds);
      }
      await storage.saveCursor(response.serverCursor);
      _pending = await queue.pending();
      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isSyncing = false;
      notifyListeners();
    }
  }
}
