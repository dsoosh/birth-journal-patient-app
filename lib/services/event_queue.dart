import 'package:hive_flutter/hive_flutter.dart';
import '../models/event.dart';

const String _queueBox = 'pending_events';

class EventQueue {
  Box<Map>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(_queueBox);
  }

  Future<void> add(EventEnvelope event) async {
    await _ensureBox();
    await _box!.put(event.eventId, event.toJson());
  }

  Future<List<EventEnvelope>> pending() async {
    await _ensureBox();
    return _box!.values
        .map((map) => EventEnvelope.fromJson(Map<String, dynamic>.from(map)))
        .toList();
  }

  Future<void> removeByIds(Iterable<String> ids) async {
    await _ensureBox();
    await _box!.deleteAll(ids);
  }

  Future<void> clear() async {
    await _ensureBox();
    await _box!.clear();
  }

  Future<void> _ensureBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<Map>(_queueBox);
    }
  }
}
